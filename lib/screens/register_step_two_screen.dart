import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import '../models/user_profile_service.dart';
import 'main_layout.dart';

/// Step 2 of 2: Registration Screen (RegisterStepTwoScreen) for SmartTap
class RegisterStepTwoScreen extends StatefulWidget {
  final String? fullName;
  final String? phoneNumber;
  final String? email;

  const RegisterStepTwoScreen({
    super.key,
    this.fullName,
    this.phoneNumber,
    this.email,
  });

  @override
  State<RegisterStepTwoScreen> createState() => _RegisterStepTwoScreenState();
}

class _RegisterStepTwoScreenState extends State<RegisterStepTwoScreen> {
  // OTP state & controller
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  // Password controllers & focus nodes
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // Visibility states
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Focus states for dynamic borders
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  // Validation & Error states
  String? _otpError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Countdown timer for OTP resend
  int _resendSeconds = 59;
  Timer? _resendTimer;

  // Button state
  bool _isButtonPressed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    _passwordFocus.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocus.hasFocus;
        if (!_passwordFocus.hasFocus) {
          _validatePassword();
        }
      });
    });

    _confirmPasswordFocus.addListener(() {
      setState(() {
        _isConfirmPasswordFocused = _confirmPasswordFocus.hasFocus;
        if (!_confirmPasswordFocus.hasFocus) {
          _validateConfirmPassword();
        }
      });
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 59);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResendOtp() {
    if (_resendSeconds > 0) return;
    HapticFeedback.lightImpact();
    _startResendTimer();
    _showToast('Đã gửi lại mã OTP 6 số đến ${widget.phoneNumber ?? "số điện thoại của bạn"}');
  }

  void _validatePassword() {
    final text = _passwordController.text;
    if (text.isEmpty) {
      _passwordError = 'Vui lòng nhập mật khẩu';
    } else if (text.length < 8) {
      _passwordError = 'Mật khẩu phải có ít nhất 8 ký tự';
    } else {
      _passwordError = null;
    }
  }

  void _validateConfirmPassword() {
    final text = _confirmPasswordController.text;
    if (text.isEmpty) {
      _confirmPasswordError = 'Vui lòng xác nhận mật khẩu';
    } else if (text != _passwordController.text) {
      _confirmPasswordError = 'Mật khẩu xác nhận không khớp';
    } else {
      _confirmPasswordError = null;
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompleteRegistration() async {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    setState(() {
      // Validate OTP
      if (_otpController.text.trim().length != 6) {
        _otpError = 'Vui lòng nhập đủ 6 chữ số OTP';
      } else {
        _otpError = null;
      }

      // Validate passwords
      _validatePassword();
      _validateConfirmPassword();
    });

    if (_otpError != null || _passwordError != null || _confirmPasswordError != null) {
      HapticFeedback.vibrate();
      return;
    }

    // Start loading & simulate server registration
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // Update shared UserProfileService if names were provided in Step 1
    if (widget.fullName != null && widget.fullName!.trim().isNotEmpty) {
      UserProfileService().updateName(widget.fullName!.trim());
    }
    if (widget.phoneNumber != null && widget.phoneNumber!.trim().isNotEmpty) {
      UserProfileService().updatePhone(widget.phoneNumber!.trim());
    }
    if (widget.email != null && widget.email!.trim().isNotEmpty) {
      UserProfileService().updateEmail(widget.email!.trim());
    }

    setState(() => _isLoading = false);

    // Show congratulations modal and navigate
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.checkCheck,
                  color: Color(0xFF1D4ED8),
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đăng ký thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tài khoản SmartTap của ${widget.fullName ?? "bạn"} đã được tạo và kích hoạt an toàn. Chào mừng bạn gia nhập hệ sinh thái IoT!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Navigate into MainLayout (App Shell)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainLayout()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Bắt đầu sử dụng SmartTap',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pinput design tokens according to specification
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 52,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: const Color(0xFF1D4ED8), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: SafeArea(
        child: Column(
          children: [
            // ================= 1. HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: Color(0xFF1E293B),
                      size: 24,
                    ),
                    splashRadius: 22,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Tạo tài khoản',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Trailing Tag: soft blue pill badge saying "Bước 2/2"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // soft blue tint
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
                    ),
                    child: const Text(
                      'Bước 2/2',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8), // Primary Blue
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 350.ms).slideY(begin: -0.05),

            // Scrollable Content Form
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // ================= 2. OTP VERIFICATION SECTION =================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'XÁC THỰC SỐ ĐIỆN THOẠI',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8), // slate-400
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty
                              ? 'Vui lòng nhập mã 6 số vừa được gửi đến SĐT ${widget.phoneNumber}.'
                              : 'Vui lòng nhập mã 6 số vừa được gửi đến SĐT gõ ở bước 1.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Pinput Implementation
                        Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Pinput(
                              length: 6,
                              controller: _otpController,
                              focusNode: _otpFocusNode,
                              separatorBuilder: (index) => const SizedBox(width: 6),
                              defaultPinTheme: defaultPinTheme,
                              focusedPinTheme: focusedPinTheme,
                              submittedPinTheme: submittedPinTheme,
                              errorPinTheme: errorPinTheme,
                              forceErrorState: _otpError != null,
                              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                              showCursor: true,
                              cursor: Container(
                                width: 2,
                                height: 22,
                                color: const Color(0xFF1D4ED8),
                              ),
                              onChanged: (val) {
                                if (_otpError != null) {
                                  setState(() => _otpError = null);
                                }
                              },
                              onCompleted: (pin) {
                                HapticFeedback.lightImpact();
                                _passwordFocus.requestFocus();
                              },
                            ),
                          ),
                        ),

                        if (_otpError != null) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.alertCircle, size: 14, color: Color(0xFFEF4444)),
                                const SizedBox(width: 6),
                                Text(
                                  _otpError!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Resend OTP Row
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Chưa nhận được mã? ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: _resendSeconds == 0 ? _handleResendOtp : null,
                                child: Text(
                                  _resendSeconds > 0
                                      ? 'Gửi lại (${_resendSeconds}s)'
                                      : 'Gửi lại ngay',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: const Color(0xFF1D4ED8), // Primary Blue
                                    fontWeight: FontWeight.w700,
                                    decoration: _resendSeconds == 0
                                        ? TextDecoration.underline
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate(delay: 100.ms).fade(duration: 400.ms).slideY(begin: 0.08),

                    const SizedBox(height: 32),

                    // ================= 3. SECURITY SECTION =================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THIẾT LẬP BẢO MẬT',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8), // slate-400
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        _buildPasswordContainer(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          isFocused: _isPasswordFocused,
                          isVisible: _isPasswordVisible,
                          hintText: 'Mật khẩu (ít nhất 8 ký tự)',
                          errorText: _passwordError,
                          onToggleVisibility: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                          onChanged: (val) {
                            if (_passwordError != null) {
                              setState(() => _validatePassword());
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        // Confirm Password Field
                        _buildPasswordContainer(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          isFocused: _isConfirmPasswordFocused,
                          isVisible: _isConfirmPasswordVisible,
                          hintText: 'Xác nhận mật khẩu',
                          errorText: _confirmPasswordError,
                          onToggleVisibility: () {
                            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                          },
                          onChanged: (val) {
                            if (_confirmPasswordError != null) {
                              setState(() => _validateConfirmPassword());
                            }
                          },
                        ),

                        const SizedBox(height: 8),

                        // Password security requirements hint
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                _passwordController.text.length >= 8
                                    ? LucideIcons.check
                                    : LucideIcons.info,
                                size: 13,
                                color: _passwordController.text.length >= 8
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Mật khẩu tối thiểu 8 ký tự an toàn',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _passwordController.text.length >= 8
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF94A3B8),
                                    fontWeight: _passwordController.text.length >= 8
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate(delay: 200.ms).fade(duration: 400.ms).slideY(begin: 0.08),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),

            // ================= 4. BOTTOM ACTION BUTTON =================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isButtonPressed = true),
                onTapUp: (_) {
                  setState(() => _isButtonPressed = false);
                  if (!_isLoading) {
                    _handleCompleteRegistration();
                  }
                },
                onTapCancel: () => setState(() => _isButtonPressed = false),
                child: AnimatedScale(
                  scale: _isButtonPressed ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8), // Primary Solid Blue
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Hoàn tất đăng ký',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                LucideIcons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ).animate(delay: 300.ms).fade(duration: 400.ms).slideY(begin: 0.15),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordContainer({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required bool isVisible,
    required String hintText,
    required String? errorText,
    required VoidCallback onToggleVisibility,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFEF4444)
                  : (isFocused ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0)),
              width: isFocused || errorText != null ? 1.5 : 1.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                LucideIcons.lock,
                size: 19,
                color: errorText != null
                    ? const Color(0xFFEF4444)
                    : (isFocused ? const Color(0xFF1D4ED8) : const Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: !isVisible,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  isVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 19,
                  color: const Color(0xFF94A3B8),
                ),
                splashRadius: 20,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              children: [
                const Icon(LucideIcons.alertCircle, size: 13, color: Color(0xFFEF4444)),
                const SizedBox(width: 5),
                Text(
                  errorText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
