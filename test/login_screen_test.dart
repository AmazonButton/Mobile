import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/screens/dashboard_screen.dart';
import 'package:smart_order_button/screens/login_screen.dart';
import 'package:smart_order_button/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen Secure Flow & Error Bypass Elimination (Story 1.4)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiClient().clearTokens();
    });

    testWidgets('Remains on LoginScreen and shows error SnackBar on 401 ApiException', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find Email and Password TextFields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'user@example.com');
      await tester.enterText(textFields.at(1), 'WrongPassword123!');
      await tester.pumpAndSettle();

      // Tap submit button
      final submitButton = find.text('Đăng nhập');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);

      await tester.pumpAndSettle();

      // Verify SnackBar with error message is shown
      expect(find.text('Tài khoản hoặc mật khẩu không chính xác'), findsOneWidget);

      // Verify user STAYS on LoginScreen and does NOT bypass to DashboardScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    testWidgets('Remains on LoginScreen and shows error SnackBar on network failure', (WidgetTester tester) async {
      final client = ApiClient();
      client.testClient = MockClient((request) async {
        throw SocketException('Connection refused');
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'user@example.com');
      await tester.enterText(textFields.at(1), 'AnyPassword123!');
      await tester.pumpAndSettle();

      final submitButton = find.text('Đăng nhập');
      await tester.tap(submitButton);

      await tester.pumpAndSettle();

      // Verify user stays on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);

      // Verify network error message is displayed in SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Social login buttons show development notice and do not bypass to Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Tap Google button
      final googleButton = find.text('Google');
      expect(googleButton, findsOneWidget);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(find.text('Đăng nhập bằng Google đang được phát triển'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    testWidgets('Navigates to DashboardScreen on valid login credentials', (WidgetTester tester) async {
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

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'user@example.com');
      await tester.enterText(textFields.at(1), 'CorrectPass123!');
      await tester.pumpAndSettle();

      final submitButton = find.text('Đăng nhập');
      await tester.tap(submitButton);

      await tester.pumpAndSettle();

      // Verify tokens saved
      expect(client.isAuthenticated, isTrue);
      expect(client.accessToken, 'mock_jwt_token_valid');

      // Verify navigated to DashboardScreen
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}
