import 'auth_guide.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import '../services/services.dart';
import '../utils/utils.dart';

/// Bottom Sheet đăng nhập nhanh bằng số điện thoại qua Firebase SMS OTP
class PhoneLoginBottomSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final ValueChanged<String>? onRegister;
  final PhoneAuthService? phoneAuthService;

  const PhoneLoginBottomSheet({
    super.key,
    required this.onSuccess,
    this.onRegister,
    this.phoneAuthService,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onSuccess,
    ValueChanged<String>? onRegister,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          PhoneLoginBottomSheet(onSuccess: onSuccess, onRegister: onRegister),
    );
  }

  @override
  State<PhoneLoginBottomSheet> createState() => _PhoneLoginBottomSheetState();
}

class _PhoneLoginBottomSheetState extends State<PhoneLoginBottomSheet> {
  int _currentPhase = 1; // 1: Nhập SĐT, 2: Nhập OTP

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();

  String _verificationId = '';
  int? _resendToken;

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _errorMessage;

  int _otpCountdown = 45;
  Timer? _countdownTimer;

  static const Color primaryBlue = Color(0xFF1D5B9F);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color textDark = Color(0xFF102A43);
  static const Color textMuted = Color(0xFF627D98);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
    _otpController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _otpCountdown = 45);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_otpCountdown > 0) {
        setState(() => _otpCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  bool get _isPhoneValid {
    final phone = _phoneController.text.trim();
    return PhoneValidator.isValid(phone);
  }

  Future<void> _handleSendOtp() async {
    if (!_isPhoneValid || _isSendingOtp) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    final phone = _phoneController.text.trim();

    await (widget.phoneAuthService ?? PhoneAuthService()).sendOtp(
      phone: phone,
      resendToken: _resendToken,
      onCodeSent: (verificationId, token) {
        if (!mounted) return;
        setState(() {
          _isSendingOtp = false;
          _verificationId = verificationId;
          _resendToken = token;
          _currentPhase = 2;
          _errorMessage = null;
        });
        _startCountdown();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _otpFocusNode.requestFocus();
        });
      },
      onError: (err) {
        if (!mounted) return;
        HapticFeedback.vibrate();
        setState(() {
          _isSendingOtp = false;
          _errorMessage = err;
        });
      },
    );
  }

  Future<void> _handleResendOtp() async {
    if (_otpCountdown > 0 || _isSendingOtp || _isVerifyingOtp) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    final phone = _phoneController.text.trim();

    await (widget.phoneAuthService ?? PhoneAuthService()).sendOtp(
      phone: phone,
      resendToken: _resendToken,
      onCodeSent: (verificationId, token) {
        if (!mounted) return;
        setState(() {
          _isSendingOtp = false;
          _verificationId = verificationId;
          _resendToken = token;
          _otpController.clear();
        });
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi lại mã xác nhận tới $phone'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isSendingOtp = false;
          _errorMessage = err;
        });
      },
    );
  }

  Future<void> _handleVerifyOtp([String? pin]) async {
    final code = pin ?? _otpController.text.trim();
    if (code.length != 6 || _isVerifyingOtp || _isSendingOtp) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
    });

    try {
      // 1. Xác thực OTP với Firebase để lấy idToken
      final idToken = await (widget.phoneAuthService ?? PhoneAuthService())
          .verifyOtpAndGetToken(verificationId: _verificationId, smsCode: code);

      // 2. Gửi idToken lên backend đăng nhập
      final res = await AuthApiService().loginByPhone(firebaseIdToken: idToken);

      // 3. Cập nhật hồ sơ người dùng
      final data = res['data'] ?? res;
      final user = data['user'] ?? data;
      if (user != null) {
        if (user['fullName'] != null) {
          UserProfileService().updateName(user['fullName'].toString());
        }
        if (user['phone'] != null) {
          UserProfileService().updatePhone(user['phone'].toString());
        }
        if (user['email'] != null) {
          UserProfileService().updateEmail(user['email'].toString());
        }
      }

      // 4. Đồng bộ FCM Token
      NotificationService().syncTokenWithBackend();

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _countdownTimer?.cancel();
      Navigator.of(context).pop(); // Đóng bottom sheet
      widget.onSuccess(); // Điều hướng vào Dashboard
    } on ApiException catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _isVerifyingOtp = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _isVerifyingOtp = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _editPhone() {
    if (_isSendingOtp || _isVerifyingOtp) return;
    _countdownTimer?.cancel();
    setState(() {
      _currentPhase = 1;
      _otpController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final defaultPinTheme = PinTheme(
      width: 48,
      height: 58,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: textDark,
        fontFamily: 'Be Vietnam Pro',
      ),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderLight, width: 1.5),
      ),
    );

    return PopScope(
      canPop: _currentPhase == 1 && !_isSendingOtp && !_isVerifyingOtp,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop &&
            !_isSendingOtp &&
            !_isVerifyingOtp &&
            _currentPhase == 2) {
          _editPhone();
        }
      },
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: bottomInset > 0 ? bottomInset + 20 : 36,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AuthStepSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthGuide(
                  mood: _isSendingOtp || _isVerifyingOtp
                      ? GuideMood.waiting
                      : GuideMood.guiding,
                  message: _currentPhase == 1
                      ? 'Mình sẽ gửi mã xác minh đến số điện thoại của bạn.'
                      : 'Nhập mã SMS để đăng nhập nhé!',
                ),
                // Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (_currentPhase == 1) ...[
                  // Header Phase 1
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          LucideIcons.phone,
                          color: primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đăng nhập bằng SĐT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Nhận mã OTP bảo mật qua tin nhắn SMS',
                              style: TextStyle(
                                fontSize: 13,
                                color: textMuted,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Input Phone
                  const Text(
                    'Số điện thoại',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                      letterSpacing: 1.1,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                    decoration: InputDecoration(
                      hintText: '0912 345 123',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9FB3C8),
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(
                        Icons.phone_iphone_rounded,
                        color: primaryBlue,
                        size: 22,
                      ),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: borderLight,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: borderLight,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _handleSendOtp(),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: dangerRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: dangerRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Button Gửi mã
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_isPhoneValid && !_isSendingOtp)
                          ? _handleSendOtp
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSendingOtp
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Gửi mã xác nhận OTP',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nhập 6 số OTP',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                          Text(
                            PhoneFormatter.formatMasked(
                              _phoneController.text.trim(),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _isSendingOtp || _isVerifyingOtp
                            ? null
                            : _editPhone,
                        child: const Text('Đổi số'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pinput
                  Center(
                    child: Pinput(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      length: 6,
                      autofocus: true,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryBlue, width: 2),
                        ),
                      ),
                      submittedPinTheme: defaultPinTheme.copyWith(
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryBlue, width: 1.5),
                        ),
                      ),
                      errorPinTheme: defaultPinTheme.copyWith(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: dangerRed, width: 1.8),
                        ),
                      ),
                      onCompleted: (pin) => _handleVerifyOtp(pin),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: dangerRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: dangerRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Resend timer
                  Center(
                    child: _otpCountdown > 0
                        ? Text(
                            'Gửi lại mã sau 0:${_otpCountdown.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: textMuted,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          )
                        : GestureDetector(
                            onTap: _handleResendOtp,
                            child: const Text(
                              'Gửi lại mã xác nhận',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: primaryBlue,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Button Xác nhận
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          (_otpController.text.length == 6 && !_isVerifyingOtp)
                          ? () => _handleVerifyOtp()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isVerifyingOtp
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                    ),
                  ),
                ],
                if (widget.onRegister != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có tài khoản? Đăng ký mới không cần đăng nhập trước.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textMuted, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: _isSendingOtp || _isVerifyingOtp
                        ? null
                        : () {
                            final phone = _phoneController.text.trim();
                            Navigator.of(context).pop();
                            widget.onRegister!(phone);
                          },
                    child: const Text('Tạo tài khoản mới bằng số điện thoại'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
