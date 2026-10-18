import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import '../../../utils/utils.dart';
import 'signup_theme.dart';
import 'signup_ui_components.dart';

/// Step 2: 6-digit SMS OTP verification with masked phone, countdown timer, and error handling.
class StepOtpVerification extends StatefulWidget {
  final String phone;
  final VoidCallback onEditPhone;
  final VoidCallback onVerified;

  const StepOtpVerification({
    super.key,
    required this.phone,
    required this.onEditPhone,
    required this.onVerified,
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
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _startOtpCountdown();
    _otpController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  void _startOtpCountdown() {
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

  void _handleResendOtp() {
    if (_otpCountdown > 0) return;
    HapticFeedback.lightImpact();
    _startOtpCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã gửi lại mã xác nhận tới ${widget.phone}'),
        backgroundColor: SignupTheme.figmaBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _verifyOtp([String? pin]) async {
    final code = pin ?? _otpController.text.trim();
    if (code.length != 6 || _isOtpVerifying) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isOtpVerifying = true;
      _otpError = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (code == '000000') {
      HapticFeedback.vibrate();
      setState(() {
        _isOtpVerifying = false;
        _otpError = 'Mã xác nhận chưa chính xác. Vui lòng kiểm tra lại.';
      });
      return;
    }

    HapticFeedback.mediumImpact();
    _otpTimer?.cancel();
    setState(() {
      _isOtpVerifying = false;
    });
    widget.onVerified();
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
          Center(
            child: Image.asset(
              'assets/illustrations/step2_otp.png',
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SignupFallbackIllustration(icon: LucideIcons.mail),
            ),
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
                onTap: widget.onEditPhone,
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
                  border: Border.all(color: SignupTheme.figmaDanger, width: 1.8),
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
                    onTap: _handleResendOtp,
                    child: const Text(
                      'Gửi lại mã',
                      style: TextStyle(
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
            isEnabled: _otpController.text.length == 6 && !_isOtpVerifying,
            onTap: () => _verifyOtp(),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Mã có hiệu lực trong 5 phút.',
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
