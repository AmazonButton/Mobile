import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/screens/login_screen.dart';
import 'package:smart_order_button/screens/signup_screen.dart';
import 'package:smart_order_button/screens/signup/widgets/widgets.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/widgets/phone_login_bottom_sheet.dart';

import 'signup_otp_flow_test.dart' show FakePhoneAuth;

const registerLabel = 'Tạo tài khoản mới bằng số điện thoại';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().clearTokens();
  });

  void largeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('new user opens registration directly without signing in', (
    tester,
  ) async {
    largeScreen(tester);
    final requests = <http.Request>[];
    ApiClient().testClient = MockClient((request) async {
      requests.add(request);
      return http.Response('{}', 500);
    });
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.ensureVisible(find.text(registerLabel));
    await tester.tap(find.text(registerLabel));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Bước 1/5'), findsOneWidget);
    expect(find.byType(PhoneLoginBottomSheet), findsNothing);
    expect(requests, isEmpty);
    expect(ApiClient().isAuthenticated, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'phone login offers registration and preserves the entered number',
    (tester) async {
      largeScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      final phoneLogin = find.text('Đăng nhập bằng số điện thoại / OTP');
      await tester.ensureVisible(phoneLogin);
      await tester.tap(phoneLogin);
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(PhoneLoginBottomSheet),
              matching: find.byType(TextField),
            )
            .first,
        '0901234567',
      );
      final register = find.descendant(
        of: find.byType(PhoneLoginBottomSheet),
        matching: find.text(registerLabel),
      );
      await tester.ensureVisible(register);
      await tester.tap(register);
      await tester.pumpAndSettle();
      expect(find.byType(PhoneLoginBottomSheet), findsNothing);
      expect(find.text('Bước 1/5'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
      expect(ApiClient().isAuthenticated, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('unregistered phone error still offers new account creation', (
    tester,
  ) async {
    largeScreen(tester);
    final phone = FakePhoneAuth();
    String? registrationPhone;
    final requestedPaths = <String>[];
    ApiClient().testClient = MockClient((request) async {
      requestedPaths.add(request.url.path);
      if (request.url.path.endsWith('/auth/register-by-phone')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'accessToken': 'new-access',
              'refreshToken': 'new-refresh',
              'user': {'fullName': 'Test User', 'phone': '+84901234567'},
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({
          'message':
              'Tài khoản chưa được đăng ký trong hệ thống, vui lòng đăng ký trước.',
        }),
        401,
        headers: {'content-type': 'application/json'},
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => PhoneLoginBottomSheet(
                  phoneAuthService: phone,
                  onSuccess: () {},
                  onRegister: (value) {
                    registrationPhone = value;
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SignUpScreen(
                          initialStep: 1,
                          initialPhone: value,
                          phoneAuthService: phone,
                        ),
                      ),
                    );
                  },
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '0901234567');
    await tester.pump();
    await tester.tap(find.text('Gửi mã xác nhận OTP'));
    await tester.pump();
    phone.requests.single.codeSent('test-session', 7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tester.widget<Pinput>(find.byType(Pinput)).onCompleted!('123456');
    await tester.pump();
    await tester.pump();
    expect(
      find.text(
        'Tài khoản chưa được đăng ký trong hệ thống, vui lòng đăng ký trước.',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text(registerLabel));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(registerLabel));
    await tester.pumpAndSettle();
    expect(registrationPhone, '0901234567');
    expect(find.byType(PhoneLoginBottomSheet), findsNothing);
    expect(find.text('Bước 1/5'), findsOneWidget);
    expect(ApiClient().isAuthenticated, isFalse);
    tester
        .widget<StepIdentityForm>(find.byType(StepIdentityForm))
        .onContinue('Test User', registrationPhone!);
    await tester.pump();
    phone.requests.last.codeSent('signup-session', 8);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tester.widget<Pinput>(find.byType(Pinput)).onCompleted!('123456');
    await tester.pumpAndSettle();
    expect(requestedPaths.length, 2);
    expect(requestedPaths.first, endsWith('/auth/login-by-phone'));
    expect(requestedPaths.last, endsWith('/auth/register-by-phone'));
    expect(ApiClient().accessToken, 'new-access');
    expect(find.text('Bước 3/5'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'registration sends verified phone token to register API without prior app login',
    (tester) async {
      largeScreen(tester);
      final phone = FakePhoneAuth();
      final requests = <http.Request>[];
      ApiClient().testClient = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'accessToken': 'new-account-access',
              'refreshToken': 'new-account-refresh',
              'user': {'fullName': 'Test User', 'phone': '+84901234567'},
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpScreen(
            initialStep: 1,
            initialPhone: '0901234567',
            phoneAuthService: phone,
          ),
        ),
      );
      expect(ApiClient().isAuthenticated, isFalse);
      tester
          .widget<StepIdentityForm>(find.byType(StepIdentityForm))
          .onContinue('Test User', '0901234567');
      await tester.pump();
      phone.requests.single.codeSent('test-session', 7);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester.widget<Pinput>(find.byType(Pinput)).onCompleted!('123456');
      await tester.pumpAndSettle();
      expect(requests.length, 1);
      expect(requests.single.url.path, endsWith('/auth/register-by-phone'));
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(requests.single.body), {
        'firebaseIdToken': 'verified-id-token',
        'fullName': 'Test User',
      });
      expect(ApiClient().accessToken, 'new-account-access');
      expect(find.text('Bước 3/5'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'phone OTP supports back, resend and successful login on small display',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final phone = FakePhoneAuth();
      var successes = 0;
      ApiClient().testClient = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'data': {
              'accessToken': 'phone-access',
              'refreshToken': 'phone-refresh',
              'user': {'phone': '+84901234567'},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Open'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => PhoneLoginBottomSheet(
                    phoneAuthService: phone,
                    onSuccess: () => successes++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '0901234567');
      await tester.pump();
      await tester.ensureVisible(find.text('Gửi mã xác nhận OTP'));
      await tester.tap(find.text('Gửi mã xác nhận OTP'));
      await tester.pump();
      phone.requests.last.codeSent('first', 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('0901234567'), findsOneWidget);
      await tester.ensureVisible(find.text('Gửi mã xác nhận OTP'));
      await tester.tap(find.text('Gửi mã xác nhận OTP'));
      await tester.pump();
      phone.requests.last.codeSent('second', 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 46));
      await tester.ensureVisible(find.text('Gửi lại mã xác nhận'));
      await tester.tap(find.text('Gửi lại mã xác nhận'));
      await tester.pump();
      expect(phone.requests.last.resendToken, 2);
      phone.requests.last.codeSent('third', 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester.widget<Pinput>(find.byType(Pinput)).onCompleted!('123456');
      await tester.pumpAndSettle();
      expect(successes, 1);
      expect(ApiClient().accessToken, 'phone-access');
      expect(find.byType(PhoneLoginBottomSheet), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
