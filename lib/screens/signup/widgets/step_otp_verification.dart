import '../../../widgets/auth_guide.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../../services/services.dart';
import '../../../utils/utils.dart';
import 'signup_theme.dart';
import 'signup_ui_components.dart';

/// Step 2: 6-digit SMS OTP verification with masked phone, countdown timer, and error handling.
class StepOtpVerification extends StatefulWidget {
  final String phone;
  final String fullName;
  final String verificationId;
  final VoidCallback onEditPhone;
  final VoidCallback onVerified;
  final Future<void> Function()? onResend;
  final PhoneAuthCredential? autoCredential;
  final ValueChanged<bool>? onBusyChanged;
  final PhoneAuthService? phoneAuthService;
  final AuthApiService? authApiService;

  const StepOtpVerification({
    super.key,
    required this.phone,
    required this.fullName,
    required this.verificationId,
    required this.onEditPhone,
    required this.onVerified,
    this.onResend,
    this.autoCredential,
    this.onBusyChanged,
    this.phoneAuthService,
    this.authApiService,
  });

  @override
  State<StepOtpVerification> createState() => _StepOtpVerificationState();
}

class _StepOtpVerificationState extends State<StepOtpVerification> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  int _otpCountdown = 45;
  Timer? _otpTimer;
  bool _isOtpVerifying = false;
  bool _isResending = false;
  bool _verified = false;
  String? _verifiedIdToken;
  PhoneAuthCredential? _attemptedAutoCredential;
  String? _otpError;
  bool get _isBusy => _isOtpVerifying || _isResending;

  @override
  void initState() {
    super.initState();
    _startOtpCountdown();
    _otpController.addListener(() => setState(() {}));
    _scheduleAutoVerification();
  }

  @override
  void didUpdateWidget(covariant StepOtpVerification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verificationId != widget.verificationId ||
        oldWidget.phone != widget.phone) {
      _otpController.clear();
      _otpError = null;
      _verifiedIdToken = null;
      _startOtpCountdown();
    }
    if (oldWidget.autoCredential != widget.autoCredential) {
      _scheduleAutoVerification();
    }
  }

  void _scheduleAutoVerification() {
    final credential = widget.autoCredential;
    if (credential == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.autoCredential == credential &&
          !_isBusy &&
          !_verified &&
          _attemptedAutoCredential != credential) {
        _attemptedAutoCredential = credential;
        _authenticate(
          () => (widget.phoneAuthService ?? PhoneAuthService())
              .verifyCredentialAndGetToken(credential),
        );
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpCountdown() {
    if (!mounted) return;
    _otpTimer?.cancel();
    setState(() => _otpCountdown = 45);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_otpCountdown > 0) {
        setState(() => _otpCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResendOtp() async {
    if (_otpCountdown > 0 || _isBusy || _verified || widget.onResend == null) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _isResending = true);
    widget.onBusyChanged?.call(true);

    try {
      await widget.onResend!();
      if (!mounted) return;
      _otpController.clear();
      _otpError = null;
      _verifiedIdToken = null;
      _startOtpCountdown();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: SignupTheme.figmaDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
        widget.onBusyChanged?.call(false);
        // Auto-verification may have arrived while the resend was pending.
        _scheduleAutoVerification();
      }
    }
  }

  Future<void> _verifyOtp([String? pin]) async {
    final code = pin ?? _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code) || widget.verificationId.isEmpty) {
      return;
    }
    await _authenticate(
      () =>
          (widget.phoneAuthService ?? PhoneAuthService()).verifyOtpAndGetToken(
            verificationId: widget.verificationId,
            smsCode: code,
          ),
    );
  }

  Future<void> _authenticate(Future<String> Function() getToken) async {
    if (_isBusy || _verified) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isOtpVerifying = true;
      _otpError = null;
    });
    widget.onBusyChanged?.call(true);

    try {
      // 1. Xác thực OTP qua Firebase và lấy idToken
      final idToken = _verifiedIdToken ?? await getToken();
      if (!mounted) return;
      _verifiedIdToken = idToken;

      // 2. Gửi idToken và Họ tên lên Backend NestJS để tạo/liên kết tài khoản
      final res = await (widget.authApiService ?? AuthApiService())
          .registerByPhone(firebaseIdToken: idToken, fullName: widget.fullName);
      if (!mounted) return;

      // 3. Cập nhật hồ sơ người dùng cục bộ
      final data = res['data'] ?? res;
      final user = data['user'] ?? data;
      if (user != null) {
        if (user['fullName'] != null) {
          UserProfileService().updateName(user['fullName'].toString());
        }
        if (user['phone'] != null) {
          UserProfileService().updatePhone(user['phone'].toString());
        }
      }

      // 4. Đồng bộ FCM notification token nếu có
      unawaited(NotificationService().syncTokenWithBackend());

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _otpTimer?.cancel();
      setState(() {
        _isOtpVerifying = false;
        _verified = true;
      });
      widget.onBusyChanged?.call(false);

      // Tiến sang Bước 3: BLE Discovery & Pairing
      widget.onVerified();
    } on ApiException catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _isOtpVerifying = false;
        _otpError = e.message;
      });
      widget.onBusyChanged?.call(false);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.vibrate();
      setState(() {
        _isOtpVerifying = false;
        _otpError = e.toString().replaceAll('Exception: ', '');
      });
      widget.onBusyChanged?.call(false);
      if (_verifiedIdToken == null) _scheduleAutoVerification();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 62,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: SignupTheme.figmaDark,
        fontFamily: SignupTheme.fontFamily,
      ),
      decoration: BoxDecoration(
        color: SignupTheme.figmaInputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SignupTheme.figmaBorder, width: 1.5),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AuthGuide(
            message: 'Nhập mã SMS để xác minh số điện thoại của bạn nhé!',
            mood: _isBusy ? GuideMood.waiting : GuideMood.guiding,
          ),
          const SizedBox(height: 24),

          const Text(
            'Nhập mã gồm 6 số',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mã đã gửi tới số điện thoại của bạn.',
            style: TextStyle(
              fontSize: 15,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 18),

          // Masked phone row & "Sửa số" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                PhoneFormatter.formatMasked(widget.phone),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: SignupTheme.figmaDark,
                  fontFamily: SignupTheme.fontFamily,
                ),
              ),
              GestureDetector(
                onTap: _isBusy || _verified ? null : widget.onEditPhone,
                child: const Text(
                  'Sửa số',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SignupTheme.figmaBlue,
                    fontFamily: SignupTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 6-digit Pinput
          Center(
            child: Pinput(
              controller: _otpController,
              focusNode: _otpFocusNode,
              length: 6,
              enabled: !_isBusy && !_verified,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: BoxDecoration(
                  color: SignupTheme.figmaInputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SignupTheme.figmaBlue, width: 2),
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                decoration: BoxDecoration(
                  color: SignupTheme.figmaInputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SignupTheme.figmaBlue, width: 1.5),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyWith(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SignupTheme.figmaDanger,
                    width: 1.8,
                  ),
                ),
              ),
              preFilledWidget: const Text(
                '—',
                style: TextStyle(color: SignupTheme.figmaMuted, fontSize: 16),
              ),
              onCompleted: (pin) => _verifyOtp(pin),
            ),
          ),

          if (_otpError != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _otpError!,
                style: const TextStyle(
                  color: SignupTheme.figmaDanger,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Countdown / Resend code
          Center(
            child: _otpCountdown > 0
                ? Text(
                    'Gửi lại mã sau 0:${_otpCountdown.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: SignupTheme.figmaMuted,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  )
                : GestureDetector(
                    onTap: _isBusy || _verified || widget.onResend == null
                        ? null
                        : _handleResendOtp,
                    child: Text(
                      _isResending ? 'Đang gửi lại mã...' : 'Gửi lại mã',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SignupTheme.figmaBlue,
                        fontFamily: SignupTheme.fontFamily,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 48),

          // Confirm button
          SignupPrimaryButton(
            label: _isOtpVerifying ? 'Đang xác thực...' : 'Xác nhận',
            isEnabled:
                (_otpController.text.length == 6 || _verifiedIdToken != null) &&
                !_isBusy &&
                !_verified,
            isLoading: _isOtpVerifying,
            onTap: () => _verifiedIdToken != null
                ? _authenticate(() async => _verifiedIdToken!)
                : _verifyOtp(),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Nếu mã hết hạn, vui lòng yêu cầu mã mới.',
              style: TextStyle(
                fontSize: 12,
                color: SignupTheme.figmaMuted,
                fontFamily: SignupTheme.fontFamily,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
