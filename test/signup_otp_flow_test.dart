import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/screens/signup_screen.dart';
import 'package:smart_order_button/screens/signup/widgets/widgets.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/auth_api_service.dart';
import 'package:smart_order_button/services/phone_auth_service.dart';

class OtpRequest {
  OtpRequest(
    this.phone,
    this.resendToken,
    this.codeSent,
    this.error,
    this.auto,
  );
  final String phone;
  final int? resendToken;
  final void Function(String, int?) codeSent;
  final void Function(String) error;
  final void Function(PhoneAuthCredential)? auto;
}

class FakePhoneAuth implements PhoneAuthService {
  final requests = <OtpRequest>[];
  int manualCalls = 0;
  int automaticCalls = 0;
  Object? verificationError;
  Completer<String>? pendingToken;

  @override
  Future<void> sendOtp({
    required String phone,
    required void Function(String, int?) onCodeSent,
    required void Function(String) onError,
    void Function(PhoneAuthCredential)? onAutoVerify,
    void Function(String)? onCodeAutoRetrievalTimeout,
    int? resendToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    requests.add(
      OtpRequest(phone, resendToken, onCodeSent, onError, onAutoVerify),
    );
  }

  Future<String> _token() async {
    if (verificationError != null) throw verificationError!;
    return pendingToken == null ? 'verified-id-token' : pendingToken!.future;
  }

  @override
  Future<String> verifyOtpAndGetToken({
    required String verificationId,
    required String smsCode,
  }) {
    manualCalls++;
    return _token();
  }

  @override
  Future<String> verifyCredentialAndGetToken(PhoneAuthCredential credential) {
    automaticCalls++;
    return _token();
  }
}

class FakeSignupApi implements AuthApiService {
  int calls = 0;
  String? lastToken;
  Object? error;
  Completer<void>? pending;

  @override
  Future<Map<String, dynamic>> registerByPhone({
    required String firebaseIdToken,
    required String fullName,
    String? email,
  }) async {
    calls++;
    lastToken = firebaseIdToken;
    if (pending != null) await pending!.future;
    if (error != null) throw error!;
    return {
      'success': true,
      'data': {
        'user': {'fullName': fullName, 'phone': '+84901234567'},
      },
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakePhoneAuth phone;
  late FakeSignupApi api;
  late int verified;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    phone = FakePhoneAuth();
    api = FakeSignupApi();
    verified = 0;
  });

  Future<void> showStep(
    WidgetTester tester, {
    Future<void> Function()? resend,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepOtpVerification(
            phone: '0901234567',
            fullName: 'Test User',
            verificationId: 'session-1',
            phoneAuthService: phone,
            authApiService: api,
            onEditPhone: () {},
            onVerified: () => verified++,
            onResend: resend,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    tester.widget<Pinput>(find.byType(Pinput)).onCompleted!('123456');
    await tester.pump();
  }

  Future<void> showSignup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: SignUpScreen(
          initialStep: 1,
          phoneAuthService: phone,
          authApiService: api,
        ),
      ),
    );
    tester
        .widget<StepIdentityForm>(find.byType(StepIdentityForm))
        .onContinue('Test User', '0901234567');
    await tester.pump();
  }

  testWidgets('manual OTP registers once and locks editing while pending', (
    tester,
  ) async {
    api.pending = Completer<void>();
    await showStep(tester);
    await submit(tester);
    await submit(tester);
    expect(api.calls, 1);
    expect(api.lastToken, 'verified-id-token');
    expect(phone.manualCalls, 1);
    expect(
      tester
          .widget<GestureDetector>(
            find
                .ancestor(
                  of: find.text('Sửa số'),
                  matching: find.byType(GestureDetector),
                )
                .first,
          )
          .onTap,
      isNull,
    );
    expect(tester.widget<Pinput>(find.byType(Pinput)).enabled, isFalse);
    api.pending!.complete();
    await tester.pump();
    await submit(tester);
    expect(verified, 1);
    expect(api.calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('wrong OTP does not register and allows another attempt', (
    tester,
  ) async {
    phone.verificationError = Exception('Mã không chính xác');
    await showStep(tester);
    await submit(tester);
    expect(api.calls, 0);
    expect(find.text('Mã không chính xác'), findsOneWidget);
    phone.verificationError = null;
    await submit(tester);
    expect(verified, 1);
    expect(phone.manualCalls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'backend retry reuses Firebase token instead of consuming OTP again',
    (tester) async {
      api.error = ApiException(message: 'Mất kết nối', statusCode: 503);
      await showStep(tester);
      await submit(tester);
      expect(verified, 0);
      expect(find.text('Mất kết nối'), findsOneWidget);
      api.error = null;
      await tester.tap(find.text('Xác nhận'));
      await tester.pump();
      expect(api.calls, 2);
      expect(phone.manualCalls, 1);
      expect(verified, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('resend is single flight and safe after disposal', (
    tester,
  ) async {
    final pending = Completer<void>();
    int resends = 0;
    await showStep(
      tester,
      resend: () {
        resends++;
        return pending.future;
      },
    );
    await tester.pump(const Duration(seconds: 46));
    final resend = tester
        .widget<GestureDetector>(
          find
              .ancestor(
                of: find.text('Gửi lại mã'),
                matching: find.byType(GestureDetector),
              )
              .first,
        )
        .onTap!;
    resend();
    resend();
    await tester.pump();
    expect(resends, 1);
    await submit(tester);
    expect(phone.manualCalls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed resend unlocks retry without claiming a new code was sent',
    (tester) async {
      int calls = 0;
      await showStep(
        tester,
        resend: () async {
          calls++;
          throw Exception('Không gửi được mã');
        },
      );
      await tester.pump(const Duration(seconds: 46));
      await tester.tap(find.text('Gửi lại mã'));
      await tester.pump();
      expect(find.text('Không gửi được mã'), findsOneWidget);
      expect(find.text('Gửi lại mã'), findsOneWidget);
      await tester.tap(find.text('Gửi lại mã'));
      await tester.pump();
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Android instant verification works without codeSent', (
    tester,
  ) async {
    await showSignup(tester);
    phone.requests.single.auto!(
      PhoneAuthProvider.credential(verificationId: 'auto', smsCode: '123456'),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(phone.automaticCalls, 1);
    expect(api.calls, 1);
    await tester.pumpAndSettle();
    expect(find.text('Bước 3/5'), findsOneWidget);
    // A late codeSent callback must not send the registered user back to OTP.
    phone.requests.single.codeSent('late-session', 8);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Bước 3/5'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('callbacks from an edited phone are ignored', (tester) async {
    await showSignup(tester);
    final old = phone.requests.single;
    old.codeSent('old-session', 7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Sửa số'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    old.auto!(
      PhoneAuthProvider.credential(verificationId: 'old', smsCode: '123456'),
    );
    old.codeSent('old-session-again', 7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Bước 1/5'), findsOneWidget);
    expect(api.calls, 0);
    expect(phone.automaticCalls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('resend uses the new verification ID and resend token', (
    tester,
  ) async {
    await showSignup(tester);
    phone.requests.single.codeSent('old-session', 7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 46));
    await tester.tap(find.text('Gửi lại mã'));
    await tester.pump();
    expect(phone.requests.length, 2);
    expect(phone.requests.last.resendToken, 7);
    phone.requests.last.codeSent('new-session', 8);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester
          .widget<StepOtpVerification>(find.byType(StepOtpVerification))
          .verificationId,
      'new-session',
    );
    expect(find.text('Gửi lại mã sau 0:45'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('send timeout unlocks the form and ignores late callbacks', (
    tester,
  ) async {
    await showSignup(tester);
    await tester.pump(const Duration(seconds: 76));
    await tester.pump();
    expect(
      tester.widget<StepIdentityForm>(find.byType(StepIdentityForm)).isLoading,
      isFalse,
    );
    expect(
      find.text('Gửi mã mất quá nhiều thời gian. Vui lòng thử lại.'),
      findsOneWidget,
    );
    phone.requests.single.codeSent('too-late', 7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Bước 1/5'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'manual and automatic verification cannot register concurrently',
    (tester) async {
      api.pending = Completer<void>();
      await showSignup(tester);
      final request = phone.requests.single;
      request.codeSent('session-1', 7);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await submit(tester);
      request.auto!(
        PhoneAuthProvider.credential(verificationId: 'auto', smsCode: '123456'),
      );
      await tester.pump();
      tester.widget<SignupTopStepper>(find.byType(SignupTopStepper)).onBack();
      await tester.pump();
      expect(find.text('Bước 2/5'), findsOneWidget);
      expect(api.calls, 1);
      expect(phone.manualCalls, 1);
      expect(phone.automaticCalls, 0);
      api.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Bước 3/5'), findsOneWidget);
      expect(api.calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('automatic verification during resend resumes after sending', (
    tester,
  ) async {
    await showSignup(tester);
    phone.requests.single.codeSent('session-1', 7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 46));
    await tester.tap(find.text('Gửi lại mã'));
    await tester.pump();
    phone.requests.last.auto!(
      PhoneAuthProvider.credential(verificationId: 'auto', smsCode: '123456'),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Bước 3/5'), findsOneWidget);
    expect(api.calls, 1);
    expect(phone.automaticCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'failed send ignores late success and allows a new phone request',
    (tester) async {
      await showSignup(tester);
      final old = phone.requests.single;
      old.error('Không gửi được SMS');
      await tester.pump();
      expect(find.text('Không gửi được SMS'), findsOneWidget);
      expect(
        tester
            .widget<StepIdentityForm>(find.byType(StepIdentityForm))
            .isLoading,
        isFalse,
      );
      old.codeSent('late', 7);
      await tester.pump();
      expect(find.text('Bước 1/5'), findsOneWidget);
      tester
          .widget<StepIdentityForm>(find.byType(StepIdentityForm))
          .onContinue('Test User', '0912345678');
      await tester.pump();
      expect(phone.requests.last.phone, '0912345678');
      expect(phone.requests.last.resendToken, isNull);
      phone.requests.last.codeSent('new-phone-session', 8);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<StepOtpVerification>(find.byType(StepOtpVerification))
            .phone,
        '0912345678',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'pending Android credential is used if manual verification fails',
    (tester) async {
      final manualToken = Completer<String>();
      phone.pendingToken = manualToken;
      await showSignup(tester);
      final request = phone.requests.single;
      request.codeSent('session-1', 7);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await submit(tester);
      request.auto!(
        PhoneAuthProvider.credential(verificationId: 'auto', smsCode: '123456'),
      );
      await tester.pump();
      phone.pendingToken = null;
      manualToken.completeError(Exception('Mã nhập sai'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(phone.manualCalls, 1);
      expect(phone.automaticCalls, 1);
      expect(api.calls, 1);
      expect(find.text('Bước 3/5'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('failed automatic credential is not retried in a loop', (
    tester,
  ) async {
    phone.verificationError = Exception('Phiên xác thực hết hạn');
    await showSignup(tester);
    phone.requests.single.auto!(
      PhoneAuthProvider.credential(verificationId: 'auto', smsCode: '123456'),
    );
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(phone.automaticCalls, 1);
    expect(api.calls, 0);
    expect(find.text('Phiên xác thực hết hạn'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
