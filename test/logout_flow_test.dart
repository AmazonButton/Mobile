import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/services/user_profile_service.dart';
import 'package:smart_order_button/screens/home_screen.dart';
import 'package:smart_order_button/screens/login_screen.dart';
import 'package:smart_order_button/screens/profile_screen.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/auth_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Logout Flow with Token Revocation (Story 1.5)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiClient().clearTokens();
    });

    test('AuthApiService.logout notifies backend and clears tokens', () async {
      final client = ApiClient();
      await client.setTokens(
        accessToken: 'active_access_token_123',
        refreshToken: 'active_refresh_token_456',
      );

      bool logoutEndpointCalled = false;
      client.testClient = MockClient((request) async {
        if (request.url.path.contains('/auth/logout')) {
          logoutEndpointCalled = true;
          return Response('{}', 200, headers: {'content-type': 'application/json'});
        }
        return Response('Not Found', 404);
      });

      expect(client.isAuthenticated, isTrue);

      await AuthApiService().logout();

      expect(logoutEndpointCalled, isTrue);
      expect(client.isAuthenticated, isFalse);
      expect(client.accessToken, isNull);
      expect(client.refreshToken, isNull);
    });

    test('UserProfileService.reset clears all stored user profile data', () {
      final userService = UserProfileService();
      userService.updateName('Test User');
      userService.updateEmail('test@smartorder.vn');
      userService.updatePhone('0912345678');

      expect(userService.name, 'Test User');
      expect(userService.email, 'test@smartorder.vn');

      userService.reset();

      expect(userService.name, isEmpty);
      expect(userService.email, isEmpty);
      expect(userService.phone, isEmpty);
      expect(userService.address, isEmpty);
      expect(userService.avatarFile, isNull);
    });

    testWidgets('ProfileScreen logout confirms dialog, revokes tokens and navigates to LoginScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final client = ApiClient();
      await client.setTokens(
        accessToken: 'profile_access_token',
        refreshToken: 'profile_refresh_token',
      );
      UserProfileService().updateName('Profile User');

      bool logoutApiCalled = false;
      client.testClient = MockClient((request) async {
        if (request.url.path.contains('/auth/logout')) {
          logoutApiCalled = true;
          return Response('{}', 200, headers: {'content-type': 'application/json'});
        }
        return Response('Not Found', 404);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(showBackButton: false),
        ),
      );

      // Find logout tile and tap it to show confirmation dialog
      final logoutTile = find.text('Đăng xuất');
      expect(logoutTile, findsOneWidget);
      await tester.tap(logoutTile);
      await tester.pumpAndSettle();

      // Dialog is shown with title 'Đăng xuất'
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'), findsOneWidget);

      // Tap confirm 'Đăng xuất' button in the dialog
      final confirmButton = find.widgetWithText(ElevatedButton, 'Đăng xuất');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);

      await tester.pumpAndSettle();

      // Verify tokens cleared
      expect(logoutApiCalled, isTrue);
      expect(client.isAuthenticated, isFalse);
      expect(UserProfileService().name, isEmpty);

      // Verify navigated to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('HomeScreen logout confirms dialog, revokes tokens and navigates to LoginScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final client = ApiClient();
      await client.setTokens(
        accessToken: 'home_access_token',
        refreshToken: 'home_refresh_token',
      );
      UserProfileService().updateName('Home User');

      bool logoutApiCalled = false;
      client.testClient = MockClient((request) async {
        if (request.url.path.contains('/auth/logout')) {
          logoutApiCalled = true;
          return Response('{}', 200, headers: {'content-type': 'application/json'});
        }
        return Response('Not Found', 404);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Tap user avatar initials to open account bottom sheet
      final avatarInitials = find.text(UserProfileService().initials);
      expect(avatarInitials, findsOneWidget);
      await tester.tap(avatarInitials);
      await tester.pumpAndSettle();

      // Account sheet is open, find 'Đăng xuất tài khoản' button
      final logoutButton = find.text('Đăng xuất tài khoản');
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap confirm button in dialog
      final confirmButton = find.widgetWithText(ElevatedButton, 'Đăng xuất');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);

      await tester.pumpAndSettle();

      // Verify tokens cleared and user navigated to LoginScreen
      expect(logoutApiCalled, isTrue);
      expect(client.isAuthenticated, isFalse);
      expect(UserProfileService().name, isEmpty);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
