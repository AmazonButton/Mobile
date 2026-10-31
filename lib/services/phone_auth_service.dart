import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý xác thực số điện thoại qua Firebase Phone Auth
class PhoneAuthService {
  static final PhoneAuthService _instance = PhoneAuthService._internal();
  factory PhoneAuthService() => _instance;
  PhoneAuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Chuẩn hoá số điện thoại Việt Nam sang định dạng E.164 (+84...)
  static String normalizePhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (clean.startsWith('+84')) {
      return clean;
    }
    if (clean.startsWith('84')) {
      return '+$clean';
    }
    if (clean.startsWith('0')) {
      return '+84${clean.substring(1)}';
    }
    if (clean.length == 9) {
      return '+84$clean';
    }
    return clean;
  }

  /// Gửi mã xác nhận OTP qua SMS tới số điện thoại
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerify,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? resendToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final formattedPhone = normalizePhone(phone);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: timeout,
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint(
            '[PhoneAuthService] Tự động xác thực thành công (Android auto-retrieval)',
          );
          if (onAutoVerify != null) {
            onAutoVerify(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
            '[PhoneAuthService] verificationFailed: ${e.code} - ${e.message}',
          );
          final message = describeError(e);
          onError(message);
        },
        codeSent: (String verificationId, int? token) {
          onCodeSent(verificationId, token);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (onCodeAutoRetrievalTimeout != null) {
            onCodeAutoRetrievalTimeout(verificationId);
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      onError(describeError(e));
    } catch (e) {
      debugPrint('[PhoneAuthService] Lỗi khi gọi verifyPhoneNumber: $e');
      onError('Không thể kết nối dịch vụ xác thực SMS. Vui lòng thử lại sau.');
    }
  }

  /// Xác thực mã OTP và lấy Firebase ID Token (JWT) để gửi lên Backend
  Future<String> verifyOtpAndGetToken({
    required String verificationId,
    required String smsCode,
  }) async {
    return verifyCredentialAndGetToken(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      ),
    );
  }

  /// Dùng chung cho nhập mã thủ công và Android tự xác thực.
  Future<String> verifyCredentialAndGetToken(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Không tìm thấy tài khoản người dùng Firebase');
      }

      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Không lấy được mã định danh Firebase ID Token');
      }

      return idToken;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[PhoneAuthService] Lỗi xác thực OTP: ${e.code} - ${e.message}',
      );
      throw Exception(describeError(e));
    } catch (e) {
      debugPrint('[PhoneAuthService] Lỗi không xác định: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Chuyển đổi mã lỗi Firebase sang tiếng Việt thân thiện
  static String describeError(FirebaseAuthException e) {
    // Android may wrap this configuration error in the generic "unknown" code.
    if (e.code == 'billing-not-enabled' ||
        (e.message ?? '').toUpperCase().contains('BILLING_NOT_ENABLED')) {
      return 'Dịch vụ SMS chưa được bật thanh toán trên Firebase. '
          'Quản trị viên cần liên kết Cloud Billing để gửi OTP thật. '
          'Nếu đang kiểm thử, hãy dùng số và mã thử nghiệm đã cấu hình.';
    }
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Số điện thoại không đúng định dạng hợp lệ.';
      case 'invalid-verification-code':
        return 'Mã xác nhận OTP không chính xác. Vui lòng thử lại.';
      case 'session-expired':
        return 'Mã xác nhận OTP đã hết hạn. Vui lòng bấm gửi lại mã mới.';
      case 'too-many-requests':
        return 'Bạn đã yêu cầu gửi mã quá nhiều lần. Vui lòng thử lại sau vài phút.';
      case 'quota-exceeded':
        return 'Hạn ngạch gửi SMS hôm nay đã vượt giới hạn. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại đường truyền internet.';
      case 'user-disabled':
        return 'Số điện thoại hoặc tài khoản này đã bị tạm khoá.';
      case 'operation-not-allowed':
        return 'Tính năng xác thực bằng số điện thoại chưa được bật trên Firebase Console.';
      default:
        return e.message ?? 'Đã có lỗi xảy ra trong quá trình xác thực OTP.';
    }
  }
}
