import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/screens/welcome_screen.dart';
import 'package:smart_order_button/screens/login_screen.dart';
import 'package:smart_order_button/screens/signup_screen.dart';
import 'package:smart_order_button/widgets/auth_guide.dart';
import 'package:smart_order_button/widgets/phone_login_bottom_sheet.dart';

void main() {
  testWidgets('Welcome branches to registration directly and returns once', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.ensureVisible(find.text('Bắt đầu'));
    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Bước 1/5'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);
  });

  testWidgets(
    'Existing account chooses email, preserves identifier and password on back',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
      await tester.ensureVisible(find.text('Tôi đã có tài khoản rồi'));
      await tester.tap(find.text('Tôi đã có tài khoản rồi'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.tap(find.text('Đăng nhập bằng email'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('loginIdentifier')),
        'user@example.com',
      );
      await tester.pump();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('loginPassword')),
        'password123',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('user@example.com'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('loginPassword')))
            .controller!
            .text,
        'password123',
      );
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('loginPassword')))
            .obscureText,
        isFalse,
      );
    },
  );

  testWidgets(
    'Small display, large text and reduced motion keep actions reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.6),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const WelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AuthGuide), findsOneWidget);
      await tester.ensureVisible(find.text('Tôi đã có tài khoản rồi'));
      await tester.tap(find.text('Tôi đã có tài khoản rồi'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Đăng nhập bằng số điện thoại / OTP'),
      );
      await tester.tap(find.text('Đăng nhập bằng số điện thoại / OTP'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(find.byType(PhoneLoginBottomSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
