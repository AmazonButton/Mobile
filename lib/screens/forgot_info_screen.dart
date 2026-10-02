import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';


class ForgotInfoScreen extends StatefulWidget {
  const ForgotInfoScreen({super.key});

  @override
  State<ForgotInfoScreen> createState() => _ForgotInfoScreenState();
}

class _ForgotInfoScreenState extends State<ForgotInfoScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isFocused = false;
  bool _isLoading = false;
  String? _errorText;
  double _shakeOffset = 0;

  static const Color primaryBlue = Color(0xFF1D5B9F);
  static const Color accentBlue = Color(0xFF2B78E4);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color textDark = Color(0xFF102A43);
  static const Color textMuted = Color(0xFF627D98);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+([.-][a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (!_focusNode.hasFocus && _controller.text.isNotEmpty) {
        _validate(_controller.text);
      }
    });
    _controller.addListener(() {
      if (_errorText != null) setState(() => _errorText = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) {
      setState(() => _errorText = 'Vui lòng nhập Email hoặc Số điện thoại');
      return _errorText;
    }
    if (raw.contains('@')) {
      if (!_emailRegex.hasMatch(raw) || raw.contains('@.') || raw.contains('..')) {
        setState(() => _errorText = 'Email không đúng định dạng (VD: name@gmail.com)');
        return _errorText;
      }
    } else if (RegExp(r'^\d+$').hasMatch(raw)) {
      if (!raw.startsWith('0')) {
        setState(() => _errorText = 'Số điện thoại phải bắt đầu bằng số 0');
        return _errorText;
      }
      if (raw.length < 10) {
        setState(() => _errorText = 'Phải gồm đúng 10 số (hiện có ${raw.length}/10)');
        return _errorText;
      }
      if (raw.length > 10) {
        setState(() => _errorText = 'Số điện thoại không được quá 10 số');
        return _errorText;
      }
    } else {
      setState(() => _errorText = 'Vui lòng nhập Email hợp lệ hoặc số điện thoại');
      return _errorText;
    }
    setState(() => _errorText = null);
    return null;
  }

  Future<void> _triggerShake() async {
    for (int i = 0; i < 3; i++) {
      setState(() => _shakeOffset = 9);
      await Future.delayed(const Duration(milliseconds: 60));
      setState(() => _shakeOffset = -9);
      await Future.delayed(const Duration(milliseconds: 60));
    }
    setState(() => _shakeOffset = 0);
  }

  void _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final error = _validate(_controller.text);
    if (error != null) {
      await _triggerShake();
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSuccessSheet();
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SuccessSheet(contact: _controller.text.trim()),
    );
  }

  IconData get _inputIcon {
    final text = _controller.text;
    if (text.contains('@')) return Icons.email_outlined;
    if (RegExp(r'^\d').hasMatch(text)) return Icons.phone_outlined;
    return Icons.person_search_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // Dải gradient top
              Container(
                height: 4,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryLight, primaryBlue, Color(0xFFF5862B)],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Nút Back
                      _BackButton()
                          .animate()
                          .fade(duration: 350.ms)
                          .slideY(begin: -0.2, end: 0, curve: Curves.easeOut),

                      const SizedBox(height: 32),

                      // Icon minh hoạ
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryBlue.withValues(alpha: 0.12),
                                accentBlue.withValues(alpha: 0.07),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: primaryBlue,
                            size: 40,
                          ),
                        )
                            .animate()
                            .fade(duration: 400.ms, delay: 100.ms)
                            .scale(
                                begin: const Offset(0.6, 0.6),
                                end: const Offset(1, 1),
                                curve: Curves.elasticOut,
                                duration: 700.ms,
                                delay: 100.ms),
                      ),

                      const SizedBox(height: 28),

                      // Tiêu đề
                      const Text(
                        'Quên thông tin?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      )
                          .animate()
                          .fade(duration: 400.ms, delay: 150.ms)
                          .slideY(begin: 0.15, end: 0, curve: Curves.easeOut, duration: 400.ms, delay: 150.ms),

                      const SizedBox(height: 10),

                      // Subtitle
                      const Text(
                        'Vui lòng nhập Email hoặc Số điện thoại đã đăng ký. Chúng tôi sẽ gửi mã xác nhận (OTP) để khôi phục.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                          .animate()
                          .fade(duration: 400.ms, delay: 220.ms)
                          .slideY(begin: 0.15, end: 0, curve: Curves.easeOut, duration: 400.ms, delay: 220.ms),

                      const SizedBox(height: 32),

                      // Input + Shake
                      Transform.translate(
                        offset: Offset(_shakeOffset, 0),
                        child: _InputField(
                          controller: _controller,
                          focusNode: _focusNode,
                          isFocused: _isFocused,
                          hasError: _errorText != null,
                          inputIcon: _inputIcon,
                        ),
                      )
                          .animate()
                          .fade(duration: 400.ms, delay: 300.ms)
                          .slideY(begin: 0.15, end: 0, curve: Curves.easeOut, duration: 400.ms, delay: 300.ms),

                      // Error text trượt xuống
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: _errorText != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, size: 14, color: errorRed),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        _errorText!,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: errorRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 32),

                      // Nút Submit
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: (_errorText == null && _controller.text.isNotEmpty)
                              ? [
                                  BoxShadow(
                                    color: primaryBlue.withValues(alpha: 0.30),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            disabledBackgroundColor: primaryBlue.withValues(alpha: 0.5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(scale: anim, child: child),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey('text'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.send_rounded, size: 18),
                                      SizedBox(width: 10),
                                      Text(
                                        'Gửi mã xác nhận',
                                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      )
                          .animate()
                          .fade(duration: 400.ms, delay: 380.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut, duration: 400.ms, delay: 380.ms),

                      const SizedBox(height: 24),

                      // Link quay lại
                      Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text.rich(
                            TextSpan(
                              style: TextStyle(fontSize: 13.5, color: textMuted),
                              children: [
                                TextSpan(text: 'Nhớ ra rồi? '),
                                TextSpan(
                                  text: 'Đăng nhập ngay',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: primaryBlue),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ).animate().fade(duration: 400.ms, delay: 460.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF102A43)),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Quay lại',
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool hasError;
  final IconData inputIcon;

  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.hasError,
    required this.inputIcon,
  });

  static const Color accentBlue = Color(0xFF2B78E4);
  static const Color textDark = Color(0xFF102A43);
  static const Color errorRed = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? errorRed : (isFocused ? accentBlue : Colors.grey.shade300),
          width: isFocused || hasError ? 1.8 : 1.2,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: accentBlue.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              inputIcon,
              key: ValueKey(inputIcon),
              size: 22,
              color: hasError ? errorRed : (isFocused ? accentBlue : Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.emailAddress,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 15, color: textDark, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Email hoặc Số điện thoại',
                hintStyle: TextStyle(fontSize: 14.5, color: Colors.grey.shade400, fontWeight: FontWeight.w400),
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () => controller.clear(),
              child: Icon(Icons.cancel_rounded, size: 18, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP Bottom Sheet – Pinput + Countdown + Auto-submit
// ─────────────────────────────────────────────────────────────────────────────
class _SuccessSheet extends StatefulWidget {
  final String contact;
  const _SuccessSheet({required this.contact});

  @override
  State<_SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends State<_SuccessSheet> {
  // ── Controllers ──
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();

  // ── State ──
  bool _isVerifying = false;
  bool _isSuccess = false;
  int _secondsLeft = 299; // 4:59
  late final Stream<int> _timerStream;

  // ── Design tokens ──
  static const Color primaryBlue = Color(0xFF1D5B9F);
  static const Color accentBlue = Color(0xFF2B78E4);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color textDark = Color(0xFF102A43);
  static const Color textMuted = Color(0xFF627D98);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    // Đếm ngược 1 giây/lần
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => i);
    _timerStream.listen((tick) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  String get _timerText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _handleCompleted(String pin) async {
    // 1. Thu bàn phím
    FocusScope.of(context).unfocus();
    // 2. Hiển thị loading
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    // 3. Giả lập thành công
    setState(() {
      _isVerifying = false;
      _isSuccess = true;
    });
    // 4. Đợi animation rồi đóng sheet
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _handleResend() {
    _pinController.clear();
    setState(() {
      _secondsLeft = 299;
      _isVerifying = false;
      _isSuccess = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _pinFocus.requestFocus();
    });
  }

  // ── Pinput theme ──
  PinTheme get _defaultTheme => PinTheme(
        width: 48,
        height: 56,
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
      );

  PinTheme get _focusedTheme => _defaultTheme.copyWith(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentBlue, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: accentBlue.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      );

  PinTheme get _submittedTheme => _defaultTheme.copyWith(
        decoration: BoxDecoration(
          color: primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryBlue, width: 1.5),
        ),
      );

  PinTheme get _errorTheme => _defaultTheme.copyWith(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: errorRed, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.contact.contains('@');
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ──
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 20),

            // ── Success Icon ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: _isSuccess
                  ? Container(
                      key: const ValueKey('success'),
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFECFDF5),
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: successGreen, size: 38),
                    )
                  : Container(
                      key: const ValueKey('mail'),
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFECFDF5),
                      ),
                      child: const Icon(Icons.mark_email_read_rounded,
                          color: successGreen, size: 36),
                    ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    curve: Curves.elasticOut,
                    duration: 650.ms)
                .fade(duration: 300.ms),

            const SizedBox(height: 16),

            // ── Title ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isSuccess ? 'Xác thực thành công! 🎉' : 'Nhập mã xác nhận',
                key: ValueKey(_isSuccess),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            )
                .animate()
                .fade(duration: 350.ms, delay: 120.ms)
                .slideY(begin: 0.15, end: 0, duration: 350.ms, delay: 120.ms),

            const SizedBox(height: 8),

            // ── Subtitle ──
            Text(
              'Mã OTP vừa được gửi đến ${isEmail ? "email" : "SĐT"}\n${widget.contact}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: textMuted, height: 1.5),
            ).animate().fade(duration: 350.ms, delay: 200.ms),

            const SizedBox(height: 24),

            // ── Pinput 6 ô ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isVerifying
                  ? const Padding(
                      key: ValueKey('loading'),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: primaryBlue,
                        ),
                      ),
                    )
                  : _isSuccess
                      ? const Padding(
                          key: ValueKey('done'),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Icon(Icons.verified_rounded,
                              color: successGreen, size: 40),
                        )
                      : Pinput(
                          key: const ValueKey('pin'),
                          length: 6,
                          controller: _pinController,
                          focusNode: _pinFocus,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          defaultPinTheme: _defaultTheme,
                          focusedPinTheme: _focusedTheme,
                          submittedPinTheme: _submittedTheme,
                          errorPinTheme: _errorTheme,
                          cursor: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 9),
                                width: 22,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: accentBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          animationCurve: Curves.easeOutBack,
                          animationDuration:
                              const Duration(milliseconds: 180),
                          pinputAutovalidateMode:
                              PinputAutovalidateMode.onSubmit,
                          onCompleted: _handleCompleted,
                          hapticFeedbackType:
                              HapticFeedbackType.lightImpact,
                        ),
            ).animate().fade(duration: 350.ms, delay: 280.ms),

            const SizedBox(height: 20),

            // ── Countdown / Resend ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _secondsLeft > 0
                  ? Row(
                      key: const ValueKey('timer'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 15, color: textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Gửi lại mã sau ',
                          style: const TextStyle(
                              fontSize: 13, color: textMuted),
                        ),
                        Text(
                          _timerText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    )
                  : TextButton.icon(
                      key: const ValueKey('resend'),
                      onPressed: _handleResend,
                      icon: const Icon(Icons.refresh_rounded,
                          size: 16, color: primaryBlue),
                      label: const Text(
                        'Gửi lại mã',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ).animate().fade(duration: 350.ms, delay: 360.ms),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
