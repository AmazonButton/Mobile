import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'forgot_info_screen.dart';
import 'onboarding/button_onboarding_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  bool _rememberMe = false;
  bool _isLoading = false;

  // Validation States cho Email
  String? _emailError;
  String? _suggestedEmail;
  bool _hasEmailBlurred = false;

  // Validation States cho Số điện thoại
  String? _phoneError;
  bool _hasPhoneBlurred = false;

  // Màu sắc chủ đạo theo yêu cầu: Tone Xanh dương nhạt & Navy thanh lịch
  static const Color primaryBlue = Color(0xFF1D5B9F);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color textDark = Color(0xFF102A43);
  static const Color textMuted = Color(0xFF627D98);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF9FAFB);

  static const List<String> _popularDomains = [
    'gmail.com',
    'yahoo.com',
    'outlook.com',
    'icloud.com',
    'hotmail.com',
  ];

  static final RegExp _strictEmailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+([.-][a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$',
  );

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  String? _checkEmailTypo(String text) {
    if (!text.contains('@')) return null;
    final parts = text.split('@');
    if (parts.length != 2) return null;

    final localPart = parts[0].trim();
    final domainPart = parts[1].toLowerCase().trim();

    if (localPart.isEmpty || domainPart.isEmpty) return null;

    if (_popularDomains.contains(domainPart)) return null;

    String? bestMatch;
    int lowestDistance = 999;

    for (final popularDomain in _popularDomains) {
      final distance = _levenshtein(domainPart, popularDomain);
      if (distance <= 2 && distance < lowestDistance) {
        lowestDistance = distance;
        bestMatch = popularDomain;
      }
    }

    if (bestMatch != null) {
      return '$localPart@$bestMatch';
    }
    return null;
  }

  void _applySuggestion(String suggested) {
    setState(() {
      _emailController.text = suggested;
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: suggested.length),
      );
      _suggestedEmail = null;
      _emailError = null;
      _validateEmail();
    });
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _phoneFocusNode.addListener(_onPhoneFocusChange);

    _emailController.addListener(_onEmailChanged);
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _phoneFocusNode.removeListener(_onPhoneFocusChange);

    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    setState(() {
      if (!_emailFocusNode.hasFocus) {
        // onBlur: Kiểm tra định dạng Email khi người dùng rời khỏi ô input
        final rawText = _emailController.text.trim();
        _hasEmailBlurred = true;
        if (rawText.contains('@')) {
          _suggestedEmail = _checkEmailTypo(rawText);
        }
        _validateEmail();
      }
    });
  }

  void _onEmailChanged() {
    final rawText = _emailController.text.trim();
    setState(() {
      if (rawText.contains('@')) {
        _suggestedEmail = _checkEmailTypo(rawText);
      } else {
        _suggestedEmail = null;
      }

      if (_hasEmailBlurred) {
        _validateEmail();
      }
    });
  }

  void _validateEmail() {
    final rawText = _emailController.text.trim();
    if (rawText.isEmpty) {
      _emailError = 'Vui lòng nhập địa chỉ Email';
      return;
    }

    // Strict Regex Validation
    if (!_strictEmailRegex.hasMatch(rawText) ||
        rawText.contains('@.') ||
        rawText.startsWith('@') ||
        rawText.contains('..')) {
      _emailError = 'Email không đúng định dạng (VD: example@domain.com)';
    } else {
      _emailError = null;
    }
  }

  void _onPhoneFocusChange() {
    setState(() {
      if (!_phoneFocusNode.hasFocus) {
        _hasPhoneBlurred = true;
        _validatePhone(_phoneController.text);
      }
    });
  }

  void _onPhoneChanged() {
    setState(() {
      _validatePhone(_phoneController.text);
    });
  }

  void _validatePhone(String value) {
    final raw = value.trim();

    if (raw.isEmpty) {
      _phoneError = _hasPhoneBlurred ? 'Vui lòng nhập số điện thoại' : null;
      return;
    }

    // 1. Nhập số đầu phải là số 0, nếu không phải số 0 cảnh báo ngay
    if (!raw.startsWith('0')) {
      _phoneError = 'Số điện thoại phải bắt đầu bằng số 0';
      return;
    }

    // 2. Không được vượt quá 10 số, nếu vượt thông báo ngay cho người dùng
    if (raw.length > 10) {
      _phoneError = 'Số điện thoại không được vượt quá 10 số (hiện có ${raw.length} số)';
      return;
    }

    // 3. Khi người dùng đã rời khỏi ô và chưa đủ 10 số
    if (_hasPhoneBlurred && raw.length < 10) {
      _phoneError = 'Số điện thoại phải gồm đúng 10 số (hiện có ${raw.length}/10)';
      return;
    }

    _phoneError = null;
  }

  bool get _isEmailValid {
    final text = _emailController.text.trim();
    if (text.isEmpty) return false;
    return _strictEmailRegex.hasMatch(text) &&
        !text.contains('@.') &&
        !text.startsWith('@') &&
        !text.contains('..');
  }

  bool get _isPhoneValid {
    final text = _phoneController.text.trim();
    return text.length == 10 && text.startsWith('0') && RegExp(r'^0\d{9}$').hasMatch(text);
  }

  bool get _isFormValid {
    return _isEmailValid && _isPhoneValid;
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToButtonOnboarding() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ButtonOnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _handleLogin() {
    if (!_isFormValid) return;
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.35, 1.0],
              colors: [
                Color(0xFFEBF4FE), // Xanh nhạt sang trọng
                Color(0xFFF7FAFD), // Chuyển màu nhẹ nhàng
                Colors.white,      // Trắng sáng vùng dưới
              ],
            ),
          ),
          child: Column(
            children: [
              // Khối màu xanh cực nhạt / dải gradient trên cùng làm nổi bật header
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 28),

                              // ── 1. Header: Logo brand căn giữa ──
                              Center(
                                child: Image.asset(
                                  'assets/logo-brand.png',
                                  height: 56,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.radio_button_checked,
                                    color: primaryBlue,
                                    size: 46,
                                  ),
                                ),
                              ),


                              const SizedBox(height: 32),

                              // ── 2. Welcome Heading (Margin-bottom hợp lý với Form) ──
                              const Text(
                                'Chào mừng trở lại',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── 3. Input Email (Chuẩn h-13 52px, Strict Regex & Typo Suggestion) ──
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _emailFocusNode.hasFocus ? Colors.white : inputBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _emailError != null
                                        ? const Color(0xFFEF4444)
                                        : (_emailFocusNode.hasFocus
                                            ? primaryBlue
                                            : (_suggestedEmail != null
                                                ? primaryBlue
                                                : borderLight)),
                                    width: _emailFocusNode.hasFocus || _emailError != null ? 1.6 : 1.2,
                                  ),
                                  boxShadow: _emailFocusNode.hasFocus
                                      ? [
                                          BoxShadow(
                                            color: primaryBlue.withValues(alpha: 0.10),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 22,
                                      color: _emailError != null
                                          ? const Color(0xFFEF4444)
                                          : (_suggestedEmail != null
                                              ? primaryBlue
                                              : textMuted),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _emailController,
                                        focusNode: _emailFocusNode,
                                        keyboardType: TextInputType.emailAddress,
                                        textAlignVertical: TextAlignVertical.center,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          color: textDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: const InputDecoration(
                                          isCollapsed: true,
                                          hintText: 'Địa chỉ Email',
                                          hintStyle: TextStyle(
                                            fontSize: 14.5,
                                            color: Color(0xFF9FB3C8),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Vùng cố định lỗi & gợi ý Email (Chống giật layout - min-height 24px) ──
                              SizedBox(
                                height: 24,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _emailError != null
                                      ? AnimatedOpacity(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                          opacity: 1.0,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 4, top: 4),
                                            child: Text(
                                              _emailError!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFEF4444),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        )
                                      : (_suggestedEmail != null
                                          ? AnimatedOpacity(
                                              duration: const Duration(milliseconds: 250),
                                              curve: Curves.easeInOut,
                                              opacity: 1.0,
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 4, top: 3),
                                                child: GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () => _applySuggestion(_suggestedEmail!),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.auto_fix_high_rounded,
                                                        size: 14,
                                                        color: primaryBlue,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text.rich(
                                                          TextSpan(
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              color: primaryBlue,
                                                              fontFamily: 'Be Vietnam Pro',
                                                            ),
                                                            children: [
                                                              const TextSpan(text: 'Có phải ý bạn là '),
                                                              TextSpan(
                                                                text: _suggestedEmail!,
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.w700,
                                                                  decoration: TextDecoration.underline,
                                                                ),
                                                              ),
                                                              const TextSpan(text: '?'),
                                                            ],
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink()),
                                ),
                              ),

                              const SizedBox(height: 4),

                              // ── 4. Input Số điện thoại (Thay thế mật khẩu - Validator số 0 đầu & tối đa 10 số) ──
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _phoneFocusNode.hasFocus ? Colors.white : inputBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _phoneError != null
                                        ? const Color(0xFFEF4444)
                                        : (_phoneFocusNode.hasFocus ? primaryBlue : borderLight),
                                    width: _phoneFocusNode.hasFocus || _phoneError != null ? 1.6 : 1.2,
                                  ),
                                  boxShadow: _phoneFocusNode.hasFocus
                                      ? [
                                          BoxShadow(
                                            color: primaryBlue.withValues(alpha: 0.10),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 22,
                                      color: _phoneError != null
                                          ? const Color(0xFFEF4444)
                                          : (_phoneFocusNode.hasFocus ? primaryBlue : textMuted),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneController,
                                        focusNode: _phoneFocusNode,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly, // Chỉ cho nhập số
                                          LengthLimitingTextInputFormatter(15), // Giới hạn hợp lý để bắt sự kiện vượt 10
                                        ],
                                        textAlignVertical: TextAlignVertical.center,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          color: textDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: const InputDecoration(
                                          isCollapsed: true,
                                          hintText: 'Số điện thoại (bắt đầu bằng 0)',
                                          hintStyle: TextStyle(
                                            fontSize: 14.5,
                                            color: Color(0xFF9FB3C8),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    // Hiển thị bộ đếm số lượng ký tự và icon trạng thái
                                    if (_phoneController.text.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_phoneError != null)
                                              const Icon(
                                                Icons.error_outline_rounded,
                                                size: 15,
                                                color: Color(0xFFEF4444),
                                              )
                                            else if (_phoneController.text.length == 10 && _phoneController.text.startsWith('0'))
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                size: 15,
                                                color: Color(0xFF10B981),
                                              ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_phoneController.text.length}/10',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _phoneError != null
                                                    ? const Color(0xFFEF4444)
                                                    : (_phoneController.text.length == 10
                                                        ? const Color(0xFF10B981)
                                                        : textMuted),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // ── Vùng cố định lỗi Số điện thoại (Chống giật layout - min-height 24px) ──
                              SizedBox(
                                height: 24,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    opacity: _phoneError != null ? 1.0 : 0.0,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 4, top: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.error_outline_rounded,
                                            size: 13,
                                            color: Color(0xFFEF4444),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _phoneError ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFEF4444), // text-red-500
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                            // ── 5. Checkbox & Quên thông tin (Cùng baseline chính xác) ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () =>
                                        setState(() => _rememberMe = !_rememberMe),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (val) {
                                              setState(
                                                  () => _rememberMe = val ?? false);
                                            },
                                            activeColor: primaryBlue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFD1D5DB),
                                              width: 1.5,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Flexible(
                                          child: Text(
                                            'Duy trì đăng nhập',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF4B5563),
                                              fontWeight: FontWeight.w400,
                                              height: 1.2,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            const ForgotInfoScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1, 0),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            )),
                                            child: child,
                                          );
                                        },
                                        transitionDuration: const Duration(milliseconds: 300),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Quên thông tin?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryBlue,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ── 6. Nút Đăng nhập (Màu xanh chủ đạo, bo góc 16px, đổ bóng có chiều sâu) ──
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isFormValid
                                    ? [
                                        BoxShadow(
                                          color: primaryBlue.withValues(alpha: 0.28),
                                          blurRadius: 18,
                                          offset: const Offset(0, 7),
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ElevatedButton(
                                onPressed: (_isFormValid && !_isLoading)
                                    ? _handleLogin
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  disabledBackgroundColor:
                                      primaryBlue.withValues(alpha: 0.35),
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor:
                                      Colors.white.withValues(alpha: 0.65),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
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
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Divider: Hoặc tiếp tục với ──
                            Row(
                              children: const [
                                Expanded(
                                  child: Divider(
                                    color: borderLight,
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'Hoặc tiếp tục với',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: borderLight,
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ── 7. Social Login Buttons (Đồng bộ 52px, items-center) ──
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Google',
                                    iconWidget: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red.shade50,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFEA4335),
                                        ),
                                      ),
                                    ),
                                    onTap: _navigateToDashboard,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Apple',
                                    iconWidget: const Icon(
                                      Icons.apple,
                                      size: 22,
                                      color: textDark,
                                    ),
                                    onTap: _navigateToDashboard,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // ── Nút Bấm SmartOrder Onboarding Card ──
                            InkWell(
                              onTap: _navigateToButtonOnboarding,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFF5862B).withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5862B),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.touch_app_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cài đặt Nút Bấm SmartOrder',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1B3A5C),
                                              fontFamily: 'Be Vietnam Pro',
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Đăng ký & kết nối thiết bị căn hộ (5 bước)',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF627D98),
                                              fontFamily: 'Be Vietnam Pro',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: Color(0xFFF5862B),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),

                            // ── 8. Footer (Nhóm sát nhau, font-weight rõ nét) ──
                            Center(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _navigateToSignUp,
                                child: const Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textMuted,
                                      fontFamily: 'Be Vietnam Pro',
                                    ),
                                    children: [
                                      TextSpan(text: 'Chưa có tài khoản? '),
                                      TextSpan(
                                        text: 'Đăng ký',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            Center(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _navigateToDashboard,
                                child: const Text(
                                  'Tiếp tục với tư cách Khách →',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF102A43),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
