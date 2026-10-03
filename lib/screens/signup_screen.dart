import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register_step_two_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  bool _isSubmitting = false;

  // Validation states
  String? _nameError;
  String? _phoneError;
  String? _emailError;

  bool _hasNameBlurred = false;
  bool _hasPhoneBlurred = false;
  bool _hasEmailBlurred = false;

  // Design tokens
  static const Color primaryBlue = Color(0xFF1D5B9F);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color textDark = Color(0xFF102A43);
  static const Color textMuted = Color(0xFF627D98);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _fullNameFocus.addListener(_onNameFocusChange);
    _phoneFocus.addListener(_onPhoneFocusChange);
    _emailFocus.addListener(_onEmailFocusChange);
    _fullNameController.addListener(_onNameChanged);
    _phoneController.addListener(_onPhoneChanged);
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _fullNameFocus.removeListener(_onNameFocusChange);
    _phoneFocus.removeListener(_onPhoneFocusChange);
    _emailFocus.removeListener(_onEmailFocusChange);
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // Name
  void _onNameFocusChange() {
    setState(() {
      if (!_fullNameFocus.hasFocus) {
        _hasNameBlurred = true;
        _validateName(_fullNameController.text);
      }
    });
  }

  void _onNameChanged() {
    setState(() {
      if (_hasNameBlurred) _validateName(_fullNameController.text);
    });
  }

  void _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _nameError = _hasNameBlurred ? 'Vui lòng nhập họ và tên' : null;
      return;
    }
    if (trimmed.length < 2) {
      _nameError = 'Họ và tên tối thiểu 2 ký tự';
      return;
    }
    if (!RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(trimmed)) {
      _nameError = 'Họ và tên không được chứa số hoặc ký tự đặc biệt';
      return;
    }
    _nameError = null;
  }

  bool get _isNameValid {
    final t = _fullNameController.text.trim();
    return t.length >= 2 && RegExp(r'^[\p{L}\s]+$', unicode: true).hasMatch(t);
  }

  // Phone
  void _onPhoneFocusChange() {
    setState(() {
      if (!_phoneFocus.hasFocus) {
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
    if (!raw.startsWith('0')) {
      _phoneError = 'Số điện thoại phải bắt đầu bằng số 0';
      return;
    }
    if (raw.length > 10) {
      _phoneError = 'Số điện thoại không được quá 10 số (hiện có ${raw.length} số)';
      return;
    }
    if (_hasPhoneBlurred && raw.length < 10) {
      _phoneError = 'Số điện thoại phải gồm đúng 10 số (hiện có ${raw.length}/10)';
      return;
    }
    _phoneError = null;
  }

  bool get _isPhoneValid {
    final t = _phoneController.text.trim();
    return t.length == 10 && t.startsWith('0') && RegExp(r'^0\d{9}$').hasMatch(t);
  }

  // Email
  void _onEmailFocusChange() {
    setState(() {
      if (!_emailFocus.hasFocus) {
        _hasEmailBlurred = true;
        _validateEmail(_emailController.text);
      }
    });
  }

  void _onEmailChanged() {
    setState(() {
      if (_hasEmailBlurred) _validateEmail(_emailController.text);
    });
  }

  void _validateEmail(String value) {
    final raw = value.trim().toLowerCase();
    if (raw.isEmpty) {
      _emailError = _hasEmailBlurred ? 'Vui lòng nhập địa chỉ email' : null;
      return;
    }
    if (!raw.endsWith('@gmail.com')) {
      _emailError = 'Email phải là địa chỉ @gmail.com (VD: name@gmail.com)';
      return;
    }
    final localPart = raw.split('@').first;
    if (localPart.isEmpty || !RegExp(r'^[a-z0-9._%+-]+$').hasMatch(localPart)) {
      _emailError = 'Email không hợp lệ (VD: name@gmail.com)';
      return;
    }
    _emailError = null;
  }

  bool get _isEmailValid {
    final raw = _emailController.text.trim().toLowerCase();
    if (!raw.endsWith('@gmail.com')) return false;
    final localPart = raw.split('@').first;
    return localPart.isNotEmpty && RegExp(r'^[a-z0-9._%+-]+$').hasMatch(localPart);
  }

  bool get _isFormValid => _isNameValid && _isPhoneValid && _isEmailValid;

  void _handleNextStep() {
    setState(() {
      _hasNameBlurred = true;
      _hasPhoneBlurred = true;
      _hasEmailBlurred = true;
      _validateName(_fullNameController.text);
      _validatePhone(_phoneController.text);
      _validateEmail(_emailController.text);
    });
    FocusScope.of(context).unfocus();
    if (!_isFormValid) return;

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegisterStepTwoScreen(
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            email: _emailController.text.trim(),
          ),
        ),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 1.0],
                colors: [Color(0xFFEBF4FE), Color(0xFFF7FAFD), Colors.white],
              ),
            ),
            child: Column(
              children: [
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
                        const SizedBox(height: 12),

                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderLight),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: textDark),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('Đã có tài khoản? ',
                                      style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w400)),
                                  Text('Đăng nhập',
                                      style: TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Tạo tài khoản',
                                      style: TextStyle(
                                          fontSize: 26, fontWeight: FontWeight.w800,
                                          color: textDark, letterSpacing: -0.5)),
                                  SizedBox(height: 4),
                                  Text('Thông tin cơ bản',
                                      style: TextStyle(fontSize: 15, color: textMuted, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryBlue.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.layers_outlined, size: 15, color: primaryBlue),
                                  SizedBox(width: 5),
                                  Text('Bước 1/2',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryBlue)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryBlue.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.badge_outlined, size: 16, color: primaryBlue),
                              SizedBox(width: 6),
                              Text('Vai trò: Khách hàng',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primaryBlue)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'THÔNG TIN CÁ NHÂN',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: Color(0xFF829AB1), letterSpacing: 1.2),
                        ),

                        const SizedBox(height: 16),

                        // Input Họ và tên
                        _buildInputField(
                          controller: _fullNameController,
                          focusNode: _fullNameFocus,
                          hintText: 'Họ và tên đầy đủ',
                          icon: Icons.person_outline_rounded,
                          hasError: _nameError != null,
                          isValid: _isNameValid,
                          textCapitalization: TextCapitalization.words,
                        ),
                        _buildErrorRow(_nameError),

                        const SizedBox(height: 4),

                        // Input Số điện thoại
                        _buildPhoneField(),
                        _buildErrorRow(_phoneError),

                        const SizedBox(height: 4),

                        // Input Email
                        _buildInputField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          hintText: 'Email (@gmail.com)',
                          icon: Icons.email_outlined,
                          hasError: _emailError != null,
                          isValid: _isEmailValid,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _buildErrorRow(_emailError),

                        const SizedBox(height: 28),

                        // Nút Submit
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
                                    ),
                                  ]
                                : [],
                          ),
                          child: ElevatedButton(
                            onPressed: (_isFormValid && !_isSubmitting) ? _handleNextStep : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              disabledBackgroundColor: primaryBlue.withValues(alpha: 0.35),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white.withValues(alpha: 0.65),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text('Tiếp theo',
                                          style: TextStyle(
                                              fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text.rich(
                              TextSpan(
                                style: TextStyle(fontSize: 13, color: textMuted),
                                children: [
                                  TextSpan(text: 'Đã có tài khoản? '),
                                  TextSpan(
                                    text: 'Đăng nhập',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: primaryBlue),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required bool hasError,
    required bool isValid,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final isFocused = focusNode.hasFocus;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? errorRed : (isFocused ? primaryBlue : borderLight),
          width: isFocused || hasError ? 1.6 : 1.2,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: primaryBlue.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22,
              color: hasError ? errorRed : (isFocused ? primaryBlue : textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14.5, color: textDark, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 14.5, color: Color(0xFF9FB3C8), fontWeight: FontWeight.w400),
                border: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isValid
                  ? const Icon(Icons.check_circle_rounded, key: ValueKey('valid'), size: 18, color: successGreen)
                  : hasError
                      ? const Icon(Icons.error_outline_rounded, key: ValueKey('error'), size: 18, color: errorRed)
                      : const SizedBox.shrink(key: ValueKey('none')),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    final isFocused = _phoneFocus.hasFocus;
    final hasError = _phoneError != null;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? errorRed : (isFocused ? primaryBlue : borderLight),
          width: isFocused || hasError ? 1.6 : 1.2,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: primaryBlue.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.phone_outlined, size: 22,
              color: hasError ? errorRed : (isFocused ? primaryBlue : textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14.5, color: textDark, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                isCollapsed: true,
                hintText: 'Số điện thoại (bắt đầu bằng 0)',
                hintStyle: TextStyle(fontSize: 14.5, color: Color(0xFF9FB3C8), fontWeight: FontWeight.w400),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_phoneController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: hasError
                        ? const Icon(Icons.error_outline_rounded, key: ValueKey('err'), size: 15, color: errorRed)
                        : (_isPhoneValid
                            ? const Icon(Icons.check_circle_rounded, key: ValueKey('ok'), size: 15, color: successGreen)
                            : const SizedBox.shrink(key: ValueKey('none'))),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_phoneController.text.length}/10',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasError ? errorRed : (_isPhoneValid ? successGreen : textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorRow(String? error) {
    return SizedBox(
      height: 24,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          opacity: error != null ? 1.0 : 0.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 13, color: errorRed),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    error ?? '',
                    style: const TextStyle(fontSize: 12, color: errorRed, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
