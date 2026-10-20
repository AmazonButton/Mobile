import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/notifications_api_service.dart';
import 'package:smart_order_button/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationsApiService Tests (Story 5.2)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ApiClient().clearTokens();
    });

    test('registerFcmToken posts device token to Backend successfully', () async {
      final client = ApiClient();
      await client.setTokens(accessToken: 'valid_jwt_token');

      String? capturedPath;
      Map<String, dynamic>? capturedBody;

      client.testClient = MockClient((request) async {
        capturedPath = request.url.path;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return Response(
          jsonEncode({
            'success': true,
            'message': 'FCM token registered successfully',
            'tokenId': '101',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = NotificationsApiService(apiClient: client);
      final result = await api.registerFcmToken('test_fcm_token_xyz', deviceType: 'ANDROID');

      expect(result, isTrue);
      expect(capturedPath, contains('/notifications/fcm-token'));
      expect(capturedBody?['token'], 'test_fcm_token_xyz');
      expect(capturedBody?['deviceType'], 'ANDROID');
    });

    test('registerFcmToken rejects empty or whitespace token', () async {
      final api = NotificationsApiService();
      final result = await api.registerFcmToken('   ');
      expect(result, isFalse);
    });

    test('unregisterFcmToken sends DELETE request with token', () async {
      final client = ApiClient();
      await client.setTokens(accessToken: 'valid_jwt_token');

      String? capturedMethod;
      String? capturedPath;
      Map<String, dynamic>? capturedBody;

      client.testClient = MockClient((request) async {
        capturedMethod = request.method;
        capturedPath = request.url.path;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return Response(
          jsonEncode({
            'success': true,
            'deactivatedCount': 1,
            'message': 'FCM token deactivated successfully',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = NotificationsApiService(apiClient: client);
      final result = await api.unregisterFcmToken('token_to_unregister');

      expect(result, isTrue);
      expect(capturedMethod, 'DELETE');
      expect(capturedPath, contains('/notifications/fcm-token'));
      expect(capturedBody?['token'], 'token_to_unregister');
    });

    test('unregisterFcmToken rejects empty token cleanly', () async {
      final api = NotificationsApiService();
      final result = await api.unregisterFcmToken('');
      expect(result, isFalse);
    });

    test('registerFcmToken handles API error response gracefully', () async {
      final client = ApiClient();
      client.testClient = MockClient((request) async {
        return Response(
          jsonEncode({'statusCode': 500, 'message': 'Internal Server Error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = NotificationsApiService(apiClient: client);
      final result = await api.registerFcmToken('valid_token');
      expect(result, isFalse);
    });
  });

  group('NotificationService Lifecycle & Token Sync (Story 5.2)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ApiClient().clearTokens();
    });

    test('syncTokenWithBackend saves token to SharedPreferences on success', () async {
      final client = ApiClient();
      await client.setTokens(accessToken: 'jwt_logged_in');

      client.testClient = MockClient((request) async {
        return Response(
          jsonEncode({'success': true, 'tokenId': '99'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = NotificationService();
      final success = await service.syncTokenWithBackend(overrideToken: 'mock_device_token_abc');

      expect(success, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cached_fcm_token'), 'mock_device_token_abc');
    });

    test('unregisterTokenOnLogout clears cached token from storage', () async {
      SharedPreferences.setMockInitialValues({
        'cached_fcm_token': 'token_to_purge',
      });

      final client = ApiClient();
      await client.setTokens(accessToken: 'jwt_logged_in');

      client.testClient = MockClient((request) async {
        return Response(
          jsonEncode({'success': true, 'deactivatedCount': 1}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = NotificationService();
      final success = await service.unregisterTokenOnLogout();

      expect(success, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cached_fcm_token'), isNull);
    });
  });
}
