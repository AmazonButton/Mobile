import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/address_provider.dart';
import '../providers/device_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';
import '../providers/user_provider.dart';
import '../services/google_login_service.dart';
import '../services/services.dart';
import '../utils/validators.dart';
import '../widgets/app_motion.dart';
import '../widgets/auth_guide.dart';
import '../widgets/phone_login_bottom_sheet.dart';
import '../widgets/sample_a.dart';
import 'dashboard_screen.dart';
import 'forgot_info_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final GoogleLoginService? googleService;
  const LoginScreen({super.key, this.googleService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final _google = widget.googleService ?? GoogleLoginService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  int _step = 0; // Method selection, identifier, password.
  int _stepDirection = 1;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _loginSuccess = false;
  bool _obscurePassword = true;
  String? _activeDemoEmail;

  // Validation States cho Email
  String? _emailError;
  String? _suggestedEmail;
  bool _hasEmailBlurred = false;

  // Validation States cho Mật khẩu
  String? _passwordError;
  bool _hasPasswordBlurred = false;

  static const Color primaryBlue = SampleA.primary;
  static const Color textMuted = Color(0xFF627D98);

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

  Future<void> _resetSessionProviders() async {
    if (!mounted) return;
    context.read<DeviceProvider?>()?.reset();
    context.read<OrderProvider?>()?.reset();
    context.read<AddressProvider?>()?.reset();
    await context.read<NotificationProvider?>()?.clearAll();
  }

  void _applyUserSession(dynamic user) {
    final profile = UserProfileService()..reset();
    if (user is Map) {
      if (user['fullName'] != null) {
        profile.updateName(user['fullName'].toString());
      }
      if (user['email'] != null) {
        profile.updateEmail(user['email'].toString());
      }
      if (user['phone'] != null) {
        profile.updatePhone(user['phone'].toString());
      }
      profile.updateAvatarUrl(user['avatarUrl']?.toString());
      if (mounted) {
        context
            .read<UserProvider?>()
            ?.applyLoginUser(Map<String, dynamic>.from(user));
      }
    }
    if (mounted) {
      context.read<UserProvider?>()?.loadProfile();
    }
  }

  Future<void> _navigateToDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loginSuccess = true;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _navigateToSignUp({String phone = ''}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignUpScreen(initialStep: 1, initialPhone: phone),
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

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _activeDemoEmail = null;
    });
    try {
      final response = await _google.signIn();
      if (!mounted || response == null) return;
      final data = response['data'] ?? response;
      final user = data['user'] ?? response['user'];
      await _resetSessionProviders();
      if (!mounted) return;
      _applyUserSession(user);
      NotificationService().syncTokenWithBackend();
      await _navigateToDashboard();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Không thể đăng nhập Google. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted && !_loginSuccess) setState(() => _isLoading = false);
    }
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
      await _resetSessionProviders();
      if (!mounted) return;
      _applyUserSession(user);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeDemoEmail = null;
        });
        NotificationService().syncTokenWithBackend();
        _navigateToDashboard();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeDemoEmail = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeDemoEmail = null;
        });
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
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _stepDirection = step >= _step ? 1 : -1;
      _step = step;
    });
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
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return PopScope(
      canPop: _step == 0 && !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isLoading && _step > 0) _changeStep(_step - 1);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F9FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F9FC),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Chào mừng trở lại',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
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
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: SampleA.formWidth),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bước $_step/2',
                            style: const TextStyle(
                              color: textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _step == 1 ? 'Tài khoản' : 'Xác thực mật khẩu',
                            style: const TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: _step / 2),
                          duration: duration,
                          curve: AppMotion.easeOut,
                          builder: (_, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            color: primaryBlue,
                            backgroundColor: const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else
                      const SizedBox(height: 6),
                    AuthStepSize(
                      duration: duration,
                      alignment: Alignment.topCenter,
                      curve: AppMotion.easeOut,
                      child: AnimatedSwitcher(
                        duration: duration,
                        switchInCurve: AppMotion.easeOut,
                        switchOutCurve: AppMotion.easeOut,
                        transitionBuilder: (child, animation) {
                          if (reducedMotion) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          }
                          final slideOffset = Offset(
                            0.04 * _stepDirection,
                            0,
                          );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: slideOffset,
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
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

  void _quickLoginDemo(String email) {
    if (_isLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _activeDemoEmail = email);
    _emailController.text = email;
    _passwordController.text = 'Password123!';
    _hasEmailBlurred = false;
    _hasPasswordBlurred = false;
    _emailError = null;
    _passwordError = null;
    _handleLogin();
  }

  Widget _demoRoleCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Color softBg,
    required String email,
  }) {
    final isThisLoading = _isLoading && _activeDemoEmail == email;
    final disabled = _isLoading && !isThisLoading;

    return Expanded(
      child: TactilePress(
        scaleDown: disabled ? 1.0 : 0.96,
        borderRadius: BorderRadius.circular(14),
        onTap: _isLoading ? null : () => _quickLoginDemo(email),
        child: AnimatedOpacity(
          duration: AppMotion.fastDuration,
          opacity: disabled ? 0.55 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isThisLoading ? accent : const Color(0xFFE2E8F0),
                width: isThisLoading ? 1.5 : 1,
              ),
              boxShadow: AppMotion.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: softBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isThisLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accent,
                            ),
                          )
                        : Icon(icon, size: 17, color: accent),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _methodChoices() => [
    TactilePress(
      scaleDown: 0.97,
      borderRadius: BorderRadius.circular(16),
      child: OutlinedButton.icon(
        key: const ValueKey('googleLogin'),
        onPressed: _isLoading ? null : _handleGoogleLogin,
        icon: const Icon(Icons.account_circle_outlined, size: 20),
        label: const Text(
          'Tiếp tục với Google',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    const SizedBox(height: 12),
    _action('Đăng nhập bằng email', () => _changeStep(1)),
    const SizedBox(height: 12),
    TactilePress(
      scaleDown: 0.97,
      borderRadius: BorderRadius.circular(16),
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _openPhoneLoginSheet,
        icon: const Icon(LucideIcons.phone, size: 18),
        label: const Text(
          'Đăng nhập bằng số điện thoại / OTP',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0E6BA8),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    const SizedBox(height: 20),
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.sparkles, size: 14, color: Color(0xFF0E6BA8)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Đăng nhập nhanh theo vai trò',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'MK: Password123!',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _demoRoleCard(
                label: 'Khách hàng',
                subtitle: 'Mua sắm · Nút 1 chạm',
                icon: LucideIcons.shoppingBag,
                accent: const Color(0xFF0E6BA8),
                softBg: const Color(0xFFE0F2FE),
                email: 'customer@smartorder.local',
              ),
              const SizedBox(width: 8),
              _demoRoleCard(
                label: 'Chủ quán',
                subtitle: 'Đơn hàng · Kho · Ví',
                icon: LucideIcons.store,
                accent: const Color(0xFF047857),
                softBg: const Color(0xFFECFDF5),
                email: 'minhkhoi@smartorder.local',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _demoRoleCard(
                label: 'Nhân viên',
                subtitle: 'Kho nút · Bảo hành',
                icon: LucideIcons.wrench,
                accent: const Color(0xFF0E7490),
                softBg: const Color(0xFFECFEFF),
                email: 'staff@smartorder.local',
              ),
              const SizedBox(width: 8),
              _demoRoleCard(
                label: 'Admin',
                subtitle: 'Giám sát toàn sàn',
                icon: LucideIcons.shieldCheck,
                accent: const Color(0xFF4338CA),
                softBg: const Color(0xFFEEF2FF),
                email: 'admin@smartorder.local',
              ),
            ],
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
    TextButton(
      onPressed: _isLoading ? null : () => _navigateToSignUp(),
      child: const Text(
        'Tạo tài khoản mới bằng số điện thoại',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w700),
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
    const SizedBox(height: 22),
    _action('Tiếp tục', _isEmailValid ? _next : null),
  ];

  List<Widget> _passwordFields() => [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.userCheck, size: 16, color: primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _emailController.text.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
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
    const SizedBox(height: 10),
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
    const SizedBox(height: 14),
    _action(
      _isLoading ? 'Đang đăng nhập…' : 'Đăng nhập',
      _isFormValid && !_isLoading ? _handleLogin : null,
    ),
  ];

  Widget _action(String label, VoidCallback? onPressed) {
    final enabled = onPressed != null;
    return TactilePress(
      scaleDown: enabled ? 0.97 : 1.0,
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0E6BA8), Color(0xFF2563EB)],
                )
              : null,
          color: enabled ? null : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF94A3B8),
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
          ),
        ),
      ),
    );
  }
}
