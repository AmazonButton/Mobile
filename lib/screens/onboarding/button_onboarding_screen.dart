import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';
import '../../constants/app_colors.dart';
import '../dashboard_screen.dart';

class ButtonOnboardingScreen extends StatefulWidget {
  const ButtonOnboardingScreen({super.key});

  @override
  State<ButtonOnboardingScreen> createState() => _ButtonOnboardingScreenState();
}

class _ButtonOnboardingScreenState extends State<ButtonOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0: Step 1, 1: Step 2, 2: Step 3, 3: Step 4, 4: Step 5

  // ── Step 1 Form Controllers & State ──
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  String? _nameError;
  String? _phoneError;
  bool _hasNameBlurred = false;
  bool _hasPhoneBlurred = false;
  bool _agreedToTerms = true;
  bool _isStep1Submitting = false;

  // Stored onboarding data
  String _confirmedFullName = '';
  String _confirmedPhone = '';

  // ── Step 2 OTP Controllers & State ──
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  int _otpCountdown = 60;
  Timer? _otpTimer;
  bool _isOtpVerifying = false;
  String? _otpError;
  bool _isOtpSuccess = false;

  static const List<Map<String, dynamic>> _stepsMeta = [
    {
      'title': 'Định danh',
      'subtitle': 'Nhập thông tin',
      'icon': Icons.badge_outlined,
    },
    {
      'title': 'Xác thực OTP',
      'subtitle': 'Mã SMS 6 số',
      'icon': Icons.sms_outlined,
    },
    {
      'title': 'Bluetooth',
      'subtitle': 'Tìm nút bấm',
      'icon': Icons.bluetooth_searching_rounded,
    },
    {
      'title': 'Cài Wi-Fi',
      'subtitle': 'Cấp mạng 2.4GHz',
      'icon': Icons.wifi_rounded,
    },
    {
      'title': 'Hoàn tất',
      'subtitle': 'Kích hoạt nút',
      'icon': Icons.check_circle_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fullNameFocus.addListener(_onNameFocusChange);
    _phoneFocus.addListener(_onPhoneFocusChange);
    _fullNameController.addListener(_onNameChanged);
    _phoneController.addListener(_onPhoneChanged);
    _otpController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameFocus.removeListener(_onNameFocusChange);
    _phoneFocus.removeListener(_onPhoneFocusChange);
    _fullNameController.dispose();
    _phoneController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();

    _otpTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  // ── Step 1 Validation Logic ──
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
      if (_hasNameBlurred) {
        _validateName(_fullNameController.text);
      }
    });
  }

  void _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _nameError = _hasNameBlurred ? 'Vui lòng nhập họ và tên cư dân' : null;
      return;
    }
    if (trimmed.length < 2) {
      _nameError = 'Họ và tên phải có tối thiểu 2 ký tự';
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
    final raw = _phoneController.text.trim();
    return raw.startsWith('0') && raw.length == 10;
  }

  bool get _canProceedStep1 {
    return _isNameValid && _isPhoneValid && _agreedToTerms && !_isStep1Submitting;
  }

  Future<void> _submitStep1() async {
    _hasNameBlurred = true;
    _hasPhoneBlurred = true;
    _validateName(_fullNameController.text);
    _validatePhone(_phoneController.text);

    if (!_canProceedStep1) {
      setState(() {});
      return;
    }

    setState(() => _isStep1Submitting = true);

    // Simulate OTP trigger request
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isStep1Submitting = false;
      _confirmedFullName = _fullNameController.text.trim();
      _confirmedPhone = _phoneController.text.trim();
      _goToStep(1); // Advance to Step 2
      _startOtpCountdown();
    });
  }

  // ── Step 2 OTP Methods ──
  void _startOtpCountdown() {
    _otpTimer?.cancel();
    _otpCountdown = 60;
    _otpError = null;
    _isOtpSuccess = false;
    _otpController.clear();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpCountdown > 0) {
        setState(() => _otpCountdown--);
      } else {
        timer.cancel();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }

  void _handleResendOtp() {
    if (_otpCountdown > 0) return;
    _startOtpCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mã OTP mới đã được gửi lại tới $_confirmedPhone',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Be Vietnam Pro',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleChangePhone() {
    _otpTimer?.cancel();
    _goToStep(0);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  Future<void> _verifyOtp(String pin) async {
    if (pin.length != 6 || _isOtpVerifying) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isOtpVerifying = true;
      _otpError = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Simulation rule: "000000" triggers error, other 6-digit codes succeed
    if (pin == '000000') {
      setState(() {
        _isOtpVerifying = false;
        _otpError = 'Mã OTP không chính xác hoặc đã hết hạn. Vui lòng thử lại.';
      });
      return;
    }

    setState(() {
      _isOtpVerifying = false;
      _isOtpSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    _otpTimer?.cancel();
    _goToStep(2); // Advance to Step 3: Bluetooth Pairing
  }

  void _goToStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= _stepsMeta.length) return;
    setState(() => _currentStep = stepIndex);
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleBack() {
    if (_currentStep == 1) {
      _otpTimer?.cancel();
    }
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.primary,
          tooltip: 'Quay lại',
          onPressed: _handleBack,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryUltraLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Cài Đặt Nút Bấm SmartOrder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Stepper Navigation Header ──
            _buildStepperHeader(),

            // ── Stepper Pages ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Stepper controlled via logic
                children: [
                  _buildStep1Identity(),
                  _buildStep2Otp(),
                  _buildStep3BluetoothPreview(),
                  _buildStep4WifiPreview(),
                  _buildStep5SuccessPreview(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. Stepper Header with 5 Step Nodes
  // ─────────────────────────────────────────────────────────────
  Widget _buildStepperHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(_stepsMeta.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Divider line between nodes
                final stepBefore = index ~/ 2;
                final isCompleted = _currentStep > stepBefore;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.accent : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isCurrent = _currentStep == stepIndex;
              final isCompleted = _currentStep > stepIndex;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isCurrent ? 36 : 30,
                    height: isCurrent ? 36 : 30,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success
                          : isCurrent
                              ? AppColors.accent
                              : AppColors.bgPage,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.success
                            : isCurrent
                                ? AppColors.accent
                                : AppColors.border,
                        width: 2,
                      ),
                      boxShadow: isCurrent ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ] : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          : Text(
                              '${stepIndex + 1}',
                              style: TextStyle(
                                fontSize: isCurrent ? 14 : 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stepsMeta[stepIndex]['title'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? AppColors.primary
                          : isCompleted
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Step 1: Resident Identity Input (CAP-1)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep1Identity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'BƯỚC 1 / 5',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Định danh cư dân',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Title & Description
          const Text(
            'Nhập thông tin cư dân',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Số điện thoại và họ tên được dùng để xác thực quyền quản lý nút bấm Smart Order Button tại căn hộ của bạn.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Form Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Name Input
                _buildFieldLabel('Họ và tên cư dân', isRequired: true),
                const SizedBox(height: 8),
                TextField(
                  controller: _fullNameController,
                  focusNode: _fullNameFocus,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Nguyễn Văn An',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    suffixIcon: _fullNameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: AppColors.textMuted,
                            onPressed: () {
                              _fullNameController.clear();
                              _onNameChanged();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.bgPage,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _nameError != null ? AppColors.danger : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _nameError != null ? AppColors.danger : AppColors.primary,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
                if (_nameError != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _nameError!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Phone Input
                _buildFieldLabel('Số điện thoại di động', isRequired: true),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '0901 234 567',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      letterSpacing: 0,
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_iphone_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    suffixIcon: _isPhoneValid
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 20,
                          )
                        : _phoneController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                color: AppColors.textMuted,
                                onPressed: () {
                                  _phoneController.clear();
                                  _onPhoneChanged();
                                },
                              )
                            : null,
                    filled: true,
                    fillColor: AppColors.bgPage,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _phoneError != null ? AppColors.danger : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _phoneError != null ? AppColors.danger : AppColors.primary,
                        width: 1.8,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _submitStep1(),
                ),
                if (_phoneError != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _phoneError!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Terms agreement checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        activeColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) {
                          setState(() => _agreedToTerms = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                        child: const Text(
                          'Tôi cam kết thông tin số điện thoại chính chủ để nhận mã OTP và quản lý quyền đặt hàng căn hộ.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Primary Continue Button
          ElevatedButton(
            onPressed: _canProceedStep1 ? _submitStep1 : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white70,
              elevation: _canProceedStep1 ? 3 : 0,
              shadowColor: AppColors.accentGlow,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isStep1Submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tiếp tục — Gửi mã OTP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // Helper info card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mã xác thực SMS OTP gồm 6 chữ số sẽ được gửi ngay sau khi bấm Tiếp tục.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Step 2: SMS OTP Verification (CAP-2)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep2Otp() {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontFamily: 'Be Vietnam Pro',
      ),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpError != null ? AppColors.danger : AppColors.border,
          width: 1.5,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpError != null ? AppColors.danger : AppColors.accent,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (_otpError != null ? AppColors.danger : AppColors.accent).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.primaryUltraLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'BƯỚC 2 / 5',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Xác thực OTP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Title & Description
          const Text(
            'Nhập mã xác thực SMS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 8),

          // Phone info banner with edit button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phonelink_ring_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                      children: [
                        const TextSpan(text: 'Mã đã gửi tới số '),
                        TextSpan(
                          text: _confirmedPhone.isNotEmpty ? _confirmedPhone : '0901 234 567',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _handleChangePhone,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.accent,
                  ),
                  child: const Text(
                    'Đổi số',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Pinput Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              children: [
                Pinput(
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                  onChanged: (value) {
                    if (_otpError != null) setState(() => _otpError = null);
                  },
                  onCompleted: (pin) => _verifyOtp(pin),
                ),

                if (_otpError != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _otpError!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ).animate().shake(duration: 400.ms),
                ],

                const SizedBox(height: 22),

                // Countdown & Resend
                if (_otpCountdown > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Gửi lại mã sau 00:${_otpCountdown.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Chưa nhận được mã? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _handleResendOtp,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text(
                          'Gửi lại mã OTP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Primary Verify Button
          ElevatedButton(
            onPressed: (_otpController.text.length == 6 && !_isOtpVerifying)
                ? () => _verifyOtp(_otpController.text)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white70,
              elevation: (_otpController.text.length == 6 && !_isOtpVerifying) ? 3 : 0,
              shadowColor: AppColors.accentGlow,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isOtpVerifying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : _isOtpSuccess
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Xác thực thành công!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Xác nhận mã OTP',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
          ),

          const SizedBox(height: 18),

          // Simulation hint banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mẹo thử nghiệm: Nhập bất kỳ 6 số nào (ví dụ 123456) để xác thực, hoặc 000000 để thử lỗi sai mã.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. Step 3 Placeholder (For Story 3: Bluetooth Pairing)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep3BluetoothPreview() {
    return _buildStepPlaceholder(
      stepNumber: 3,
      title: 'Quét & Ghép nối Bluetooth',
      description: 'Đang chuẩn bị quét sóng BLE để phát hiện nút bấm Smart Order Button tại căn hộ...',
      icon: Icons.bluetooth_searching_rounded,
      actionText: 'Tiếp tục sang Bước 4 (Cài Wi-Fi) →',
      onNext: () => _goToStep(3),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. Step 4 Placeholder (For Story 4: Wi-Fi Provisioning)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep4WifiPreview() {
    return _buildStepPlaceholder(
      stepNumber: 4,
      title: 'Cài đặt Wi-Fi cho Nút Bấm',
      description: 'Nạp thông tin mạng Wi-Fi 2.4GHz của căn hộ vào nút bấm qua Bluetooth...',
      icon: Icons.wifi_rounded,
      actionText: 'Tiếp tục sang Bước 5 (Hoàn tất) →',
      onNext: () => _goToStep(4),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. Step 5 Placeholder (For Story 5: Success & Dashboard)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep5SuccessPreview() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 50,
                color: AppColors.success,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            const Text(
              'Cài đặt Nút Bấm Thành Công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Tài khoản $_confirmedFullName ($_confirmedPhone) đã sẵn sàng sử dụng nút bấm để đặt hàng.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Vào Bảng Điều Khiển →'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPlaceholder({
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required String actionText,
    required VoidCallback onNext,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryUltraLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bluetooth_searching_rounded, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Bước $stepNumber: $title',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: onNext,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}
