import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/screens/dashboard_screen.dart';
import 'package:smart_order_button/screens/welcome_screen.dart';
import 'package:smart_order_button/screens/splash_screen.dart';
import 'package:smart_order_button/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Session Verification & Auto-Routing (Story 1.3)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiClient().clearTokens();
    });

    testWidgets('Routes to WelcomeScreen when no token is present', (
      WidgetTester tester,
    ) async {
      // Unauthenticated state
      final client = ApiClient();
      await client.clearTokens();

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Verify SplashScreen rendered
      expect(find.byType(SplashScreen), findsOneWidget);

      // Tap skip button ('Bỏ qua →')
      final skipButton = find.text('Bỏ qua →');
      expect(skipButton, findsOneWidget);
      await tester.tap(skipButton);

      // Pump through async verification and transition animation
      await tester.pumpAndSettle();

      // Should be on WelcomeScreen, not DashboardScreen
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
    });

    testWidgets('Routes to DashboardScreen when valid token exists', (
      WidgetTester tester,
    ) async {
      // Authenticated state
      SharedPreferences.setMockInitialValues({
        'auth_access_token': 'valid_authenticated_token',
        'auth_refresh_token': 'valid_refresh_token',
      });
      final client = ApiClient();
      await client.init(force: true);

      expect(client.isAuthenticated, isTrue);

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Verify SplashScreen rendered
      expect(find.byType(SplashScreen), findsOneWidget);

      // Tap skip button ('Bỏ qua →')
      final skipButton = find.text('Bỏ qua →');
      expect(skipButton, findsOneWidget);
      await tester.tap(skipButton);

      // Pump through async verification and transition animation
      await tester.pumpAndSettle();

      // Should be on DashboardScreen, not WelcomeScreen
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });
  });
}
