import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient Token Persistence (Story 1.1)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ApiClient().clearTokens();
    });

    test('Initializes with empty tokens when storage is empty', () async {
      final client = ApiClient();
      await client.init();
      expect(client.accessToken, isNull);
      expect(client.refreshToken, isNull);
      expect(client.isAuthenticated, isFalse);
    });

    test('Loads pre-existing tokens from SharedPreferences on init', () async {
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'test_jwt_access_token_123',
        'auth_refresh_token': 'test_jwt_refresh_token_456',
      });

      final client = ApiClient();
      // Reset internal flag for test
      await client.clearTokens();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_access_token', 'saved_token');
      await prefs.setString('auth_refresh_token', 'saved_refresh');

      await client.ensureAuthenticated();
      expect(client.accessToken, 'saved_token');
      expect(client.refreshToken, 'saved_refresh');
      expect(client.isAuthenticated, isTrue);
    });

    test('Saving tokens persists to SharedPreferences', () async {
      final client = ApiClient();
      await client.setTokens(
        accessToken: 'new_token_789',
        refreshToken: 'new_refresh_999',
      );

      expect(client.accessToken, 'new_token_789');
      expect(client.refreshToken, 'new_refresh_999');
      expect(client.isAuthenticated, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_access_token'), 'new_token_789');
      expect(prefs.getString('auth_refresh_token'), 'new_refresh_999');
    });

    test('Clearing tokens removes them from RAM and SharedPreferences', () async {
      final client = ApiClient();
      await client.setTokens(
        accessToken: 'token_to_remove',
        refreshToken: 'refresh_to_remove',
      );

      await client.clearTokens();

      expect(client.accessToken, isNull);
      expect(client.refreshToken, isNull);
      expect(client.isAuthenticated, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_access_token'), isNull);
      expect(prefs.getString('auth_refresh_token'), isNull);
    });

    test('ensureAuthenticated does not invent dummy credentials when not logged in', () async {
      final client = ApiClient();
      await client.clearTokens();
      await client.ensureAuthenticated();

      expect(client.accessToken, isNull);
      expect(client.isAuthenticated, isFalse);
    });
  });

  group('ApiClient 401 Interceptor & Auto Refresh (Story 1.2)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ApiClient().clearTokens();
    });

    test('Automatically refreshes token and replays request on 401', () async {
      final client = ApiClient();
      await client.setTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'valid_refresh_token',
      );

      int refreshCallCount = 0;
      int protectedCallCount = 0;

      client.testClient = MockClient((request) async {
        if (request.url.path.contains('/auth/refresh')) {
          refreshCallCount++;
          final body = jsonDecode(request.body);
          if (body['refreshToken'] == 'valid_refresh_token') {
            return Response(
              jsonEncode({
                'success': true,
                'data': {
                  'token': 'brand_new_access_token',
                  'refreshToken': 'renewed_refresh_token',
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return Response('Unauthorized', 401);
        }

        if (request.url.path.contains('/devices')) {
          protectedCallCount++;
          // First attempt has expired token -> return 401
          if (request.headers['Authorization'] == 'Bearer expired_access_token') {
            return Response(
              jsonEncode({'statusCode': 401, 'message': 'Token expired'}),
              401,
              headers: {'content-type': 'application/json'},
            );
          }
          // Second attempt with new token -> return 200
          if (request.headers['Authorization'] == 'Bearer brand_new_access_token') {
            return Response(
              jsonEncode({
                'success': true,
                'data': [
                  {'id': 'dev-1', 'name': 'Living Room Button'}
                ]
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
        }

        return Response('Not Found', 404);
      });

      final result = await client.get('/devices');

      expect(refreshCallCount, 1);
      expect(protectedCallCount, 2);
      expect(client.accessToken, 'brand_new_access_token');
      expect(client.refreshToken, 'renewed_refresh_token');
      expect(result['data'], isA<List>());
      expect(result['data'][0]['name'], 'Living Room Button');
    });

    test('Wipes tokens and throws ApiException when refresh token is invalid/revoked', () async {
      final client = ApiClient();
      await client.setTokens(
        accessToken: 'expired_access_token',
        refreshToken: 'invalid_refresh_token',
      );

      client.testClient = MockClient((request) async {
        if (request.url.path.contains('/auth/refresh')) {
          return Response(
            jsonEncode({'statusCode': 401, 'message': 'Refresh token expired'}),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return Response(
          jsonEncode({'statusCode': 401, 'message': 'Token expired'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => client.get('/devices'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      // Verify tokens are cleaned up
      await Future.delayed(const Duration(milliseconds: 50));
      expect(client.accessToken, isNull);
      expect(client.refreshToken, isNull);
    });

    test('Does not attempt 401 interceptor on /auth/ endpoints to prevent loops', () async {
      final client = ApiClient();
      int refreshCallCount = 0;

      client.testClient = MockClient((request) async {
        if (request.url.path.contains('/auth/refresh')) {
          refreshCallCount++;
          return Response('{}', 200);
        }
        return Response(
          jsonEncode({'statusCode': 401, 'message': 'Sai mật khẩu'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(
        () => client.post('/auth/login', body: {'email': 'test@example.com'}),
        throwsA(isA<ApiException>()),
      );

      expect(refreshCallCount, 0);
    });
  });
}
