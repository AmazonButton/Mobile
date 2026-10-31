import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'forgot_info_screen.dart';
import '../services/services.dart';
import '../utils/validators.dart';
import '../widgets/phone_login_bottom_sheet.dart';
import '../widgets/auth_guide.dart';

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

  int _step = 0; // Method selection, identifier, password.
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _loginSuccess = false;
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
  static const Color textMuted = Color(0xFF627D98);
  static const Color borderLight = Color(0xFFE2E8F0);

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
    _emailError = EmailValidator.validate(
      _emailController.text,
      allowUsername: true,
    );
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
    _passwordError = PasswordValidator.validate(
      _passwordController.text,
      minLength: 6,
    );
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

  Future<void> _navigateToDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loginSuccess = true;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 280));
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _navigateToSignUp({String phone = ''}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SignUpScreen(initialStep: 1, initialPhone: phone),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 280),
      ),
    );
  }

  void _openPhoneLoginSheet() {
    PhoneLoginBottomSheet.show(
      context,
      onSuccess: _navigateToDashboard,
      onRegister: (phone) => _navigateToSignUp(phone: phone),
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
        NotificationService().syncTokenWithBackend();
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
            content: Text(
              'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
            ),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _changeStep(int step) {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
  }

  void _next() {
    setState(() {
      _hasEmailBlurred = true;
      _validateEmail();
    });
    if (_isEmailValid && _emailError == null) _changeStep(2);
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    return PopScope(
      canPop: _step == 0 && !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isLoading && _step > 0) _changeStep(_step - 1);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8FAFD),
          title: const Text('Chào mừng trở lại'),
          leading: BackButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_step > 0) {
                      _changeStep(_step - 1);
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthGuide(
                      mood: _loginSuccess
                          ? GuideMood.happy
                          : _isLoading
                          ? GuideMood.waiting
                          : GuideMood.guiding,
                      message: _loginSuccess
                          ? 'Đăng nhập thành công! Cùng bắt đầu nhé!'
                          : _isLoading
                          ? 'Mình đang kiểm tra thông tin của bạn…'
                          : _step == 0
                          ? 'Bạn muốn đăng nhập bằng cách nào?'
                          : _step == 1
                          ? 'Cho mình biết email hoặc tên đăng nhập của bạn nhé!'
                          : 'Chỉ còn mật khẩu nữa thôi!',
                    ),
                    if (_step > 0) ...[
                      Text(
                        'Bước $_step/2',
                        style: const TextStyle(color: textMuted),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _step / 2,
                        color: primaryBlue,
                        backgroundColor: borderLight,
                      ),
                      const SizedBox(height: 24),
                    ],
                    AuthStepSize(
                      duration: duration,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: duration,
                        child: Column(
                          key: ValueKey(_step),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _step == 0
                              ? _methodChoices()
                              : _step == 1
                              ? _identifierFields()
                              : _passwordFields(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _methodChoices() => [
    _action('Đăng nhập bằng email', () => _changeStep(1)),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: _openPhoneLoginSheet,
      icon: const Icon(Icons.phone_outlined),
      label: const Text(
        'Đăng nhập bằng số điện thoại / OTP',
        textAlign: TextAlign.center,
      ),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18)),
    ),
    const SizedBox(height: 24),
    TextButton(
      onPressed: () => _navigateToSignUp(),
      child: const Text(
        'Tạo tài khoản mới bằng số điện thoại',
        textAlign: TextAlign.center,
      ),
    ),
  ];

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    errorMaxLines: 3,
  );

  List<Widget> _identifierFields() => [
    TextField(
      key: const ValueKey('loginIdentifier'),
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.username],
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => _next(),
      decoration: _decoration(
        'Email hoặc tên đăng nhập',
        Icons.person_outline,
      ).copyWith(errorText: _emailError),
    ),
    if (_suggestedEmail != null)
      TextButton(
        onPressed: () => _applySuggestion(_suggestedEmail!),
        child: Text('Bạn có muốn dùng $_suggestedEmail?'),
      ),
    const SizedBox(height: 24),
    _action('Tiếp tục', _isEmailValid ? _next : null),
  ];

  List<Widget> _passwordFields() => [
    Text(
      _emailController.text.trim(),
      style: const TextStyle(color: textMuted),
    ),
    const SizedBox(height: 16),
    TextField(
      key: const ValueKey('loginPassword'),
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      enabled: !_isLoading,
      obscureText: _obscurePassword,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleLogin(),
      decoration: _decoration('Mật khẩu', Icons.lock_outline).copyWith(
        errorText: _passwordError,
        suffixIcon: IconButton(
          tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
    ),
    const SizedBox(height: 12),
    CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _rememberMe,
      onChanged: _isLoading
          ? null
          : (value) => setState(() => _rememberMe = value ?? false),
      title: const Text('Duy trì đăng nhập'),
    ),
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isLoading
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotInfoScreen()),
              ),
        child: const Text('Quên thông tin?'),
      ),
    ),
    const SizedBox(height: 16),
    _action(
      _isLoading ? 'Đang đăng nhập…' : 'Đăng nhập',
      _isFormValid && !_isLoading ? _handleLogin : null,
    ),
  ];

  Widget _action(String label, VoidCallback? onPressed) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
