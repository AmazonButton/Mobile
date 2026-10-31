import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/screens/dashboard_screen.dart';
import 'package:smart_order_button/screens/login_screen.dart';
import 'package:smart_order_button/screens/welcome_screen.dart';
import 'package:smart_order_button/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Secure Flow & Error Bypass Elimination (Story 1.4)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiClient().clearTokens();
    });

    testWidgets(
      'Remains on LoginScreen and shows error SnackBar on 401 ApiException',
      (WidgetTester tester) async {
        final client = ApiClient();
        client.testClient = MockClient((request) async {
          return Response(
            jsonEncode({
              'statusCode': 401,
              'message': 'Tài khoản hoặc mật khẩu không chính xác',
            }),
            401,
            headers: {'content-type': 'application/json'},
          );
        });

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        await enterCredentials(tester, 'WrongPassword123!');

        // Tap submit button
        final submitButton = find.text('Đăng nhập');
        expect(submitButton, findsOneWidget);
        await tester.tap(submitButton);

        await tester.pumpAndSettle();

        // Verify SnackBar with error message is shown
        expect(
          find.text('Tài khoản hoặc mật khẩu không chính xác'),
          findsOneWidget,
        );

        // Verify user STAYS on LoginScreen and does NOT bypass to DashboardScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(DashboardScreen), findsNothing);
      },
    );

    testWidgets(
      'Remains on LoginScreen and shows error SnackBar on network failure',
      (WidgetTester tester) async {
        final client = ApiClient();
        client.testClient = MockClient((request) async {
          throw SocketException('Connection refused');
        });

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        await enterCredentials(tester, 'AnyPassword123!');

        final submitButton = find.text('Đăng nhập');
        await tester.tap(submitButton);

        await tester.pumpAndSettle();

        // Verify user stays on LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(DashboardScreen), findsNothing);

        // Verify network error message is displayed in SnackBar
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets('Method selection cannot bypass authentication', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      expect(find.text('Đăng nhập bằng email'), findsOneWidget);
      expect(find.text('Đăng nhập bằng số điện thoại / OTP'), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      expect(ApiClient().isAuthenticated, isFalse);
    });

    testWidgets('Navigates to DashboardScreen on valid login credentials', (
      WidgetTester tester,
    ) async {
      final client = ApiClient();
      client.testClient = MockClient((request) async {
        if (request.url.path.contains('/auth/login')) {
          return Response(
            jsonEncode({
              'success': true,
              'data': {
                'token': 'mock_jwt_token_valid',
                'refreshToken': 'mock_refresh_token_valid',
                'user': {
                  'fullName': 'Nguyễn Văn A',
                  'email': 'user@example.com',
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return Response('Not Found', 404);
      });

      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

      await tester.ensureVisible(find.text('Tôi đã có tài khoản rồi'));
      await tester.tap(find.text('Tôi đã có tài khoản rồi'));
      await tester.pumpAndSettle();
      await enterCredentials(tester, 'CorrectPass123!');

      final submitButton = find.text('Đăng nhập');
      await tester.tap(submitButton);

      await tester.pumpAndSettle();

      // Verify tokens saved
      expect(client.isAuthenticated, isTrue);
      expect(client.accessToken, 'mock_jwt_token_valid');

      // Verify navigated to DashboardScreen
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(DashboardScreen))).canPop(),
        isFalse,
      );
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}

Future<void> enterCredentials(WidgetTester tester, String password) async {
  await tester.tap(find.text('Đăng nhập bằng email'));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('loginIdentifier')),
    'user@example.com',
  );
  await tester.pump();
  await tester.tap(find.text('Tiếp tục'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('loginPassword')), password);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Đăng nhập'));
}
