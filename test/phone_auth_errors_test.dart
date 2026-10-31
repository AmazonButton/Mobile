import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/services/phone_auth_service.dart';

void main() {
  test(
    'Android wrapped billing error explains why real SMS cannot be sent',
    () {
      final message = PhoneAuthService.describeError(
        FirebaseAuthException(
          code: 'unknown',
          message: 'An internal error has occurred. [ BILLING_NOT_ENABLED ]',
        ),
      );
      expect(message, contains('Cloud Billing'));
      expect(message, contains('mã thử nghiệm'));
    },
  );

  test('explicit billing error is recognized without a native message', () {
    expect(
      PhoneAuthService.describeError(
        FirebaseAuthException(code: 'billing-not-enabled'),
      ),
      contains('Cloud Billing'),
    );
  });

  test('invalid code still asks the user to retry the OTP', () {
    expect(
      PhoneAuthService.describeError(
        FirebaseAuthException(code: 'invalid-verification-code'),
      ),
      contains('OTP không chính xác'),
    );
  });
}
