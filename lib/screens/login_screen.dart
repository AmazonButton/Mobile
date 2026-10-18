import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'forgot_info_screen.dart';
import '../services/services.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Validation States cho Email
  String? _emailError;
  String? _suggestedEmail;
  bool _hasEmailBlurred = false;

  // Validation States cho Mật khẩu
  String? _passwordError;
  bool _hasPasswordBlurred = false;

  // Màu sắc chủ đạo theo yêu cầu: Tone Xanh dương nhạt & Navy thanh lịch
  static const Color primaryBlue = Color(0xFF1D5B9F);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color textDark = Color(0xFF102A43);
  static const Color textMuted = Color(0xFF627D98);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF9FAFB);

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
    _passwordFocusNode.addListener(_onPasswordFocusChange);

    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    setState(() {
      if (!_emailFocusNode.hasFocus) {
        // onBlur: Kiểm tra định dạng Email khi người dùng rời khỏi ô input
        final rawText = _emailController.text.trim();
        _hasEmailBlurred = true;
        if (rawText.contains('@')) {
          _suggestedEmail = EmailValidator.checkTypo(rawText);
        }
        _validateEmail();
      }
    });
  }

  void _onEmailChanged() {
    final rawText = _emailController.text.trim();
    setState(() {
      if (rawText.contains('@')) {
        _suggestedEmail = EmailValidator.checkTypo(rawText);
      } else {
        _suggestedEmail = null;
      }

      if (_hasEmailBlurred) {
        _validateEmail();
      }
    });
  }

  void _validateEmail() {
    _emailError = EmailValidator.validate(_emailController.text, allowUsername: true);
  }

  void _onPasswordFocusChange() {
    setState(() {
      if (!_passwordFocusNode.hasFocus) {
        _hasPasswordBlurred = true;
        _validatePassword();
      }
    });
  }

  void _onPasswordChanged() {
    setState(() {
      if (_hasPasswordBlurred) {
        _validatePassword();
      }
    });
  }

  void _validatePassword() {
    if (!_hasPasswordBlurred) {
      _passwordError = null;
      return;
    }
    _passwordError = PasswordValidator.validate(_passwordController.text, minLength: 6);
  }

  bool get _isEmailValid {
    final text = _emailController.text.trim();
    if (text.isEmpty) return false;
    if (text.contains('@')) {
      return EmailValidator.isValid(text);
    }
    return text.length >= 3;
  }

  bool get _isPasswordValid {
    return _passwordController.text.isNotEmpty;
  }

  bool get _isFormValid {
    return _isEmailValid && _isPasswordValid;
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


  void _showSocialNotice(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đăng nhập bằng $provider đang được phát triển'),
        backgroundColor: const Color(0xFF64748B),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_isFormValid || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final res = await AuthApiService().login(
        email: email,
        password: password,
        rememberMe: _rememberMe,
      );
      final data = res['data'] ?? res;
      final user = data['user'] ?? data;
      if (user != null) {
        if (user['fullName'] != null) {
          UserProfileService().updateName(user['fullName'].toString());
        }
        if (user['email'] != null) {
          UserProfileService().updateEmail(user['email'].toString());
        }
        if (user['phone'] != null) {
          UserProfileService().updatePhone(user['phone'].toString());
        }
      }
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToDashboard();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
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
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (_) => _passwordFocusNode.requestFocus(),
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

                              // ── 4. Input Mật khẩu (Chuẩn h-13 52px, Ẩn/Hiện mật khẩu) ──
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: _passwordFocusNode.hasFocus ? Colors.white : inputBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _passwordError != null
                                        ? const Color(0xFFEF4444)
                                        : (_passwordFocusNode.hasFocus ? primaryBlue : borderLight),
                                    width: _passwordFocusNode.hasFocus || _passwordError != null ? 1.6 : 1.2,
                                  ),
                                  boxShadow: _passwordFocusNode.hasFocus
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
                                      Icons.lock_outline_rounded,
                                      size: 22,
                                      color: _passwordError != null
                                          ? const Color(0xFFEF4444)
                                          : (_passwordFocusNode.hasFocus ? primaryBlue : textMuted),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _passwordController,
                                        focusNode: _passwordFocusNode,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) {
                                          if (_isFormValid && !_isLoading) {
                                            _handleLogin();
                                          }
                                        },
                                        textAlignVertical: TextAlignVertical.center,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          color: textDark,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: const InputDecoration(
                                          isCollapsed: true,
                                          hintText: 'Mật khẩu',
                                          hintStyle: TextStyle(
                                            fontSize: 14.5,
                                            color: Color(0xFF9FB3C8),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: textMuted,
                                      ),
                                      splashRadius: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Vùng cố định lỗi Mật khẩu (Chống giật layout - min-height 24px) ──
                              SizedBox(
                                height: 24,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    opacity: _passwordError != null ? 1.0 : 0.0,
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
                                              _passwordError ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFEF4444),
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
                                    'Quên mật khẩu?',
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
                                    onTap: () => _showSocialNotice('Google'),
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
                                    onTap: () => _showSocialNotice('Apple'),
                                  ),
                                ),
                              ],
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
