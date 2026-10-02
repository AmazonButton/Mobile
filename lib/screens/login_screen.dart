import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _accountFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  // Validation States
  String? _accountError;
  String? _suggestedEmail;
  bool _hasAccountBlurred = false;

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

    // Nếu đã gõ đúng domain phổ biến thì không cần gợi ý
    if (_popularDomains.contains(domainPart)) return null;

    String? bestMatch;
    int lowestDistance = 999;

    for (final popularDomain in _popularDomains) {
      final distance = _levenshtein(domainPart, popularDomain);
      // Gõ sai nhẹ: khoảng cách chỉnh sửa 1 hoặc 2 ký tự
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
      _accountController.text = suggested;
      _accountController.selection = TextSelection.fromPosition(
        TextPosition(offset: suggested.length),
      );
      _suggestedEmail = null;
      _accountError = null;
      _validateAccount();
    });
  }

  // Password criteria states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _accountFocusNode.addListener(_onAccountFocusChange);
    _accountController.addListener(_onAccountChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _accountFocusNode.removeListener(_onAccountFocusChange);
    _accountFocusNode.dispose();
    _passwordFocusNode.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAccountFocusChange() {
    if (!_accountFocusNode.hasFocus) {
      // onBlur: Thực hiện validate tài khoản khi rời khỏi ô input
      final rawText = _accountController.text.trim();
      final isPhone = RegExp(r'^[0-9+]').hasMatch(rawText);

      setState(() {
        _hasAccountBlurred = true;
        if (!isPhone && rawText.contains('@')) {
          _suggestedEmail = _checkEmailTypo(rawText);
        }
        _validateAccount();
      });
    }
  }

  void _onAccountChanged() {
    final rawText = _accountController.text.trim();
    final isPhone = RegExp(r'^[0-9+]').hasMatch(rawText);

    setState(() {
      if (!isPhone && rawText.contains('@')) {
        _suggestedEmail = _checkEmailTypo(rawText);
      } else {
        _suggestedEmail = null;
      }

      if (_hasAccountBlurred) {
        _validateAccount();
      }
    });
  }

  void _validateAccount() {
    final rawText = _accountController.text.trim();
    if (rawText.isEmpty) {
      _accountError = 'Vui lòng nhập Email hoặc Số điện thoại';
      return;
    }

    // Tự động phân loại: nếu bắt đầu bằng số 0 hoặc toàn chữ số -> SĐT
    final isPhone = RegExp(r'^[0-9+]').hasMatch(rawText);

    if (isPhone) {
      if (!rawText.startsWith('0')) {
        _accountError = 'Số điện thoại phải bắt đầu bằng số 0';
      } else if (!RegExp(r'^0\d{9}$').hasMatch(rawText)) {
        _accountError = 'Số điện thoại phải gồm đúng 10 chữ số';
      } else {
        _accountError = null;
      }
    } else {
      // Strict Regex Validation:
      // Quét chặt chẽ các trường hợp thiếu thành phần: @.vn, abc@.com, abc@domain...
      if (!_strictEmailRegex.hasMatch(rawText) ||
          rawText.contains('@.') ||
          rawText.startsWith('@') ||
          rawText.contains('..')) {
        _accountError = 'Email không đúng định dạng (VD: example@domain.com)';
      } else {
        _accountError = null;
      }
    }
  }

  void _onPasswordChanged() {
    final text = _passwordController.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(text);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(text);
      _hasDigit = RegExp(r'[0-9]').hasMatch(text);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text);
    });
  }

  int get _passwordScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigit) score++;
    if (_hasSpecialChar) score++;
    return score;
  }

  double get _passwordStrengthProgress {
    final score = _passwordScore;
    if (_passwordController.text.isEmpty) return 0.0;
    if (score <= 2) return 0.33;
    if (score <= 4) return 0.66;
    return 1.0;
  }

  Color get _passwordStrengthColor {
    final score = _passwordScore;
    if (_passwordController.text.isEmpty) return const Color(0xFFE5E7EB);
    if (score <= 2) return const Color(0xFFEF4444); // Đỏ - Yếu
    if (score <= 4) return const Color(0xFFF59E0B); // Vàng - Trung bình
    return const Color(0xFF10B981); // Xanh lá - Mạnh
  }

  String get _passwordStrengthLabel {
    final score = _passwordScore;
    if (_passwordController.text.isEmpty) return '';
    if (score <= 2) return 'Yếu';
    if (score <= 4) return 'Trung bình';
    return 'Mạnh';
  }

  bool get _isAccountValid {
    final text = _accountController.text.trim();
    if (text.isEmpty) return false;
    final isPhone = RegExp(r'^[0-9+]').hasMatch(text);
    if (isPhone) {
      return RegExp(r'^0\d{9}$').hasMatch(text);
    }
    // Strict Regex Validation:
    return _strictEmailRegex.hasMatch(text) &&
        !text.contains('@.') &&
        !text.startsWith('@') &&
        !text.contains('..');
  }

  bool get _isPasswordValid {
    return _hasMinLength &&
        _hasUppercase &&
        _hasLowercase &&
        _hasDigit &&
        _hasSpecialChar;
  }

  bool get _isFormValid {
    return _isAccountValid && _isPasswordValid;
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
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

                      // ── 1. Header (Căn giữa logo & SmartOrder: flex-row, items-center, justify-center) ──
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/smart_order_button_logo.png',
                              height: 46,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/fpt_toggle_button.png',
                                height: 46,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error2, stackTrace2) =>
                                    const Icon(
                                  Icons.radio_button_checked,
                                  color: AppColors.accent,
                                  size: 38,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'SmartOrder',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E212D),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── 2. Welcome Heading (Margin-bottom hợp lý với Form) ──
                      const Text(
                        'Chào mừng trở lại',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 3. Input Tài khoản (Email hoặc SĐT - Chuẩn h-13 52px) ──
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _accountError != null
                                ? const Color(0xFFEF4444)
                                : (_suggestedEmail != null
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFE5E7EB)),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 22,
                              color: _accountError != null
                                  ? const Color(0xFFEF4444)
                                  : (_suggestedEmail != null
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF9CA3AF)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _accountController,
                                focusNode: _accountFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF111827),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  hintText: 'Email hoặc Số điện thoại',
                                  hintStyle: TextStyle(
                                    fontSize: 14.5,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Vùng cố định hiển thị lỗi & Gợi ý Typo (Chống giật layout - min-height 24px) ──
                      SizedBox(
                        height: 24,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _accountError != null
                              ? AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  opacity: 1.0,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4, top: 4),
                                    child: Text(
                                      _accountError!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFEF4444), // text-red-500
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
                                                color: Color(0xFF2563EB), // text-blue-500
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text.rich(
                                                  TextSpan(
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF2563EB), // text-blue-500
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

                      // ── 4. Input Mật khẩu (Chuẩn h-13 52px, items-center) ──
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 22,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF111827),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  hintText: 'Mật khẩu',
                                  hintStyle: TextStyle(
                                    fontSize: 14.5,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() =>
                                    _obscurePassword = !_obscurePassword);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 22,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── 5. Password Strength Meter (Thanh tiến trình mượt 300ms) ──
                      if (_passwordController.text.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Container(
                                  height: 4,
                                  color: const Color(0xFFE5E7EB),
                                  child: LayoutBuilder(
                                    builder: (context, boxConstraints) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          height: 4,
                                          width: boxConstraints.maxWidth *
                                              _passwordStrengthProgress,
                                          decoration: BoxDecoration(
                                            color: _passwordStrengthColor,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _passwordStrengthColor,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                              child: Text(_passwordStrengthLabel),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ── 6. Requirement Checklist (Dấu tick xanh lá mượt mà) ──
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF3F4F6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ChecklistItem(
                                label: 'Tối thiểu 8 ký tự',
                                isMet: _hasMinLength,
                              ),
                              const SizedBox(height: 6),
                              _ChecklistItem(
                                label: 'Có chữ hoa & chữ thường (A-Z, a-z)',
                                isMet: _hasUppercase && _hasLowercase,
                              ),
                              const SizedBox(height: 6),
                              _ChecklistItem(
                                label: 'Có ít nhất 1 chữ số (0-9)',
                                isMet: _hasDigit,
                              ),
                              const SizedBox(height: 6),
                              _ChecklistItem(
                                label: 'Có ký tự đặc biệt (!@#\$%^&*...)',
                                isMet: _hasSpecialChar,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // ── 7. Checkbox & Quên mật khẩu (Cùng baseline chính xác) ──
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
                                      activeColor: const Color(0xFF131722),
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
                            onTap: () {},
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── 8. Nút Đăng nhập (Disabled state mờ khi chưa valid) ──
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _isFormValid
                              ? const [
                                  BoxShadow(
                                    color: Color(0x3D131722),
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
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
                            backgroundColor: const Color(0xFF131722),
                            disabledBackgroundColor: const Color(0x52131722),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xA6FFFFFF),
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
                              color: Color(0xFFE5E7EB),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'Hoặc tiếp tục với',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Color(0xFFE5E7EB),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── 9. Social Login Buttons (Đồng bộ 52px, items-center) ──
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
                                color: Color(0xFF111827),
                              ),
                              onTap: _navigateToDashboard,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ── 10. Footer (Nhóm sát nhau, font-weight rõ nét) ──
                      Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _navigateToSignUp,
                          child: const Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontFamily: 'Be Vietnam Pro',
                              ),
                              children: [
                                TextSpan(text: 'Chưa có tài khoản? '),
                                TextSpan(
                                  text: 'Đăng ký',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
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
                              color: Color(0xFF111827),
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
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String label;
  final bool isMet;

  const _ChecklistItem({
    required this.label,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          ),
          alignment: Alignment.center,
          child: Icon(
            isMet ? Icons.check : Icons.circle,
            size: isMet ? 11 : 4,
            color: isMet ? Colors.white : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet ? const Color(0xFF065F46) : const Color(0xFF6B7280),
              fontFamily: 'Be Vietnam Pro',
            ),
            child: Text(label),
          ),
        ),
      ],
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
            color: const Color(0xFFE5E7EB),
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
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
