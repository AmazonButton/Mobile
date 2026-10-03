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

  // ── Step 3 Bluetooth Controllers & State ──
  bool _isScanningBle = false;
  String? _connectingDeviceId;
  String? _connectedDeviceId;
  String _pairedDeviceName = '';
  String _pairedDeviceMac = '';
  int _pairedDeviceRssi = -60;
  final List<Map<String, dynamic>> _discoveredDevices = [];

  // ── Step 4 Wi-Fi Controllers & State ──
  String _selectedSsid = 'CanHo_1205_2.4G';
  bool _isCustomSsid = false;
  final TextEditingController _customSsidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  bool _isWifiPasswordObscured = true;
  bool _isProvisioningWifi = false;
  String _wifiProvisionStatusText = '';
  String? _wifiProvisionError;
  bool _isWifiSuccess = false;

  static const List<Map<String, dynamic>> _mockWifiNetworks = [
    {
      'ssid': 'CanHo_1205_2.4G',
      'signal': 'Mạnh',
      'rssi': -46,
      'isRecommended': true,
      'security': 'WPA2/WPA3',
    },
    {
      'ssid': 'FPT_Telecom_A1_2.4G',
      'signal': 'Tốt',
      'rssi': -62,
      'isRecommended': false,
      'security': 'WPA2',
    },
    {
      'ssid': 'SmartHome_IoT_2.4G',
      'signal': 'Tốt',
      'rssi': -68,
      'isRecommended': false,
      'security': 'WPA2',
    },
    {
      'ssid': 'VNPT_Apartment_Guest',
      'signal': 'Trung bình',
      'rssi': -82,
      'isRecommended': false,
      'security': 'WPA2',
    },
  ];

  static const List<Map<String, dynamic>> _mockBlePeripherals = [
    {
      'id': 'sob-esp32-a1',
      'name': 'Smart Order Button #A1-1205',
      'mac': 'EC:62:60:88:1A:04',
      'rssi': -58,
      'isPairedBefore': false,
    },
    {
      'id': 'sob-esp32-new',
      'name': 'Smart Order Button (Mới)',
      'mac': 'EC:62:60:89:3F:12',
      'rssi': -74,
      'isPairedBefore': false,
    },
    {
      'id': 'sob-esp32-b2',
      'name': 'Smart Order Button #B2-0301',
      'mac': 'EC:62:60:92:44:8B',
      'rssi': -82,
      'isPairedBefore': true,
    },
  ];

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
    _wifiPasswordController.addListener(() => setState(() {}));
    _customSsidController.addListener(() => setState(() {}));
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
    _customSsidController.dispose();
    _wifiPasswordController.dispose();
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

  // ── Step 3 Bluetooth Methods ──
  void _startBleScan() {
    setState(() {
      _isScanningBle = true;
      _discoveredDevices.clear();
      _connectingDeviceId = null;
      _connectedDeviceId = null;
    });

    // Staggered simulation of discovering nearby Smart Order Buttons
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_isScanningBle) return;
      setState(() {
        _discoveredDevices.add(_mockBlePeripherals[0]);
      });
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted || !_isScanningBle) return;
      setState(() {
        _discoveredDevices.add(_mockBlePeripherals[1]);
      });
    });

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted || !_isScanningBle) return;
      setState(() {
        _discoveredDevices.add(_mockBlePeripherals[2]);
        _isScanningBle = false;
      });
    });
  }

  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    final deviceId = device['id'] as String;
    if (_connectingDeviceId != null || _connectedDeviceId != null) return;

    setState(() {
      _connectingDeviceId = deviceId;
    });

    // Simulate BLE GATT service discovery & bonding handshake
    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;

    setState(() {
      _connectingDeviceId = null;
      _connectedDeviceId = deviceId;
      _pairedDeviceName = device['name'] as String;
      _pairedDeviceMac = device['mac'] as String;
      _pairedDeviceRssi = device['rssi'] as int;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _goToStep(3); // Advance to Step 4 (Wi-Fi Provisioning)
  }

  // ── Step 4 Wi-Fi Provisioning Methods ──
  void _onSsidSelected(String ssid) {
    setState(() {
      if (ssid == '__custom__') {
        _isCustomSsid = true;
      } else {
        _isCustomSsid = false;
        _selectedSsid = ssid;
      }
      _wifiProvisionError = null;
    });
  }

  Future<void> _provisionWifi() async {
    final effectiveSsid = _isCustomSsid ? _customSsidController.text.trim() : _selectedSsid;
    final password = _wifiPasswordController.text;

    if (effectiveSsid.isEmpty) {
      setState(() => _wifiProvisionError = 'Vui lòng chọn hoặc nhập tên mạng Wi-Fi của căn hộ');
      return;
    }

    if (password.isEmpty) {
      setState(() => _wifiProvisionError = 'Vui lòng nhập mật khẩu Wi-Fi của căn hộ');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isProvisioningWifi = true;
      _wifiProvisionError = null;
      _wifiProvisionStatusText = 'Đang gửi thông tin mạng qua Bluetooth BLE...';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _wifiProvisionStatusText = 'Nút bấm đang kết nối tới "$effectiveSsid"...';
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // Simulation rule: "wrongpass" or "000000" triggers Wi-Fi authentication error
    if (password == 'wrongpass' || password == '000000') {
      setState(() {
        _isProvisioningWifi = false;
        _wifiProvisionError = 'Nút bấm không thể kết nối tới Wi-Fi "$effectiveSsid". Mật khẩu không chính xác hoặc tín hiệu mạng yếu. Vui lòng kiểm tra lại.';
      });
      return;
    }

    setState(() {
      _wifiProvisionStatusText = 'Đã xác thực và kết nối Wi-Fi thành công!';
      _isWifiSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _isProvisioningWifi = false;
    });

    _goToStep(4); // Advance to Step 5 (Commissioning Success)
  }

  void _goToStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= _stepsMeta.length) return;
    setState(() => _currentStep = stepIndex);
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    if (stepIndex == 2) {
      _startBleScan();
    }
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
                  _buildStep3Bluetooth(),
                  _buildStep4Wifi(),
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
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
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
  // 4. Step 3: BLE Discovery & Hardware Pairing (CAP-3)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep3Bluetooth() {
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
                  'BƯỚC 3 / 5',
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
                'Kết nối Bluetooth',
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
            'Tìm kiếm Nút Bấm SmartOrder',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bật Bluetooth trên điện thoại và đặt nút bấm ở gần (dưới 5m). Đèn LED trên nút bấm cần nhấp nháy xanh dương.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Radar Scan Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              children: [
                if (_isScanningBle) ...[
                  // Animated Pulsing Radar
                  SizedBox(
                    height: 130,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent.withValues(alpha: 0.12),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .scale(
                                begin: const Offset(0.7, 0.7),
                                end: const Offset(1.3, 1.3),
                                duration: 1500.ms,
                              )
                              .fadeOut(duration: 1500.ms),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryUltraLight,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(
                              Icons.bluetooth_searching_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đang quét sóng Bluetooth Low Energy (BLE)...',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryUltraLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bluetooth_connected_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _discoveredDevices.isEmpty
                                  ? 'Không tìm thấy thiết bị'
                                  : 'Tìm thấy ${_discoveredDevices.length} nút bấm gần bạn',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Chạm vào thiết bị để ghép nối',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _startBleScan,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Quét lại', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Discovered Devices List
          if (_discoveredDevices.isEmpty && !_isScanningBle) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  const Icon(Icons.bluetooth_disabled_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    'Không tìm thấy Smart Order Button',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hãy đảm bảo nút bấm đã bật nguồn và nhấn giữ 3 giây để vào chế độ ghép nối.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _startBleScan,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Thử quét lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _discoveredDevices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = _discoveredDevices[index];
                final deviceId = device['id'] as String;
                final isConnecting = _connectingDeviceId == deviceId;
                final isConnected = _connectedDeviceId == deviceId;
                final rssi = device['rssi'] as int;

                return InkWell(
                  onTap: (_connectingDeviceId != null || _connectedDeviceId != null)
                      ? null
                      : () => _connectToDevice(device),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? AppColors.successLight
                          : isConnecting
                              ? AppColors.accentLight
                              : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isConnected
                            ? AppColors.success
                            : isConnecting
                                ? AppColors.accent
                                : AppColors.borderLight,
                        width: isConnected || isConnecting ? 1.8 : 1.0,
                      ),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: Row(
                      children: [
                        // Button Device Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.primaryUltraLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.touch_app_rounded,
                            color: isConnected ? AppColors.success : AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Device Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device['name'] as String,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    device['mac'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isConnected
                                          ? AppColors.successLight
                                          : isConnecting
                                              ? AppColors.accentLight
                                              : AppColors.infoLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isConnected
                                          ? 'Đã kết nối'
                                          : isConnecting
                                              ? 'Đang kết nối...'
                                              : 'Chưa cài đặt',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isConnected
                                            ? AppColors.success
                                            : isConnecting
                                                ? AppColors.accent
                                                : AppColors.info,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Signal & Action
                        if (isConnecting)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.accent,
                            ),
                          )
                        else if (isConnected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 26,
                          )
                        else
                          Row(
                            children: [
                              _buildRssiBadge(rssi),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 22,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
              },
            ),
          ],

          const SizedBox(height: 24),

          // LED Instruction Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chỉ báo đèn LED trên nút bấm:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Xanh dương nhấp nháy: Đang phát tín hiệu BLE chờ ghép nối.\n• Xanh lá cây sáng: Đã kết nối thành công với điện thoại.\n• Đỏ: Mức pin yếu (dưới 15%), cần cắm sạc.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary.withValues(alpha: 0.8),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRssiBadge(int rssi) {
    Color color;
    IconData icon;

    if (rssi >= -65) {
      color = AppColors.success;
      icon = Icons.wifi_rounded;
    } else if (rssi >= -80) {
      color = AppColors.warning;
      icon = Icons.wifi_2_bar_rounded;
    } else {
      color = AppColors.danger;
      icon = Icons.wifi_1_bar_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$rssi dBm',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. Step 4: Wi-Fi Provisioning over BLE (CAP-4)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep4Wifi() {
    final effectiveSsid = _isCustomSsid ? _customSsidController.text.trim() : _selectedSsid;
    final isFormValid = effectiveSsid.isNotEmpty && _wifiPasswordController.text.isNotEmpty;

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
                  'BƯỚC 4 / 5',
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
                'Cài đặt Wi-Fi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Title & Subtitle
          const Text(
            'Cấu hình Wi-Fi cho Nút Bấm',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nút bấm SmartOrder cần kết nối mạng Wi-Fi căn hộ để gửi đơn hàng tự động ngay khi bạn bấm nút.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          // Paired Device Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bluetooth_connected_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pairedDeviceName.isNotEmpty ? _pairedDeviceName : 'Smart Order Button #A1-1205',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Đã kết nối Bluetooth (${_pairedDeviceMac.isNotEmpty ? _pairedDeviceMac : "EC:62:60:88:1A:04"} • $_pairedDeviceRssi dBm)',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Sẵn sàng nạp',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2.4GHz Hardware Constraint Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yêu cầu phần cứng: Mạng Wi-Fi 2.4GHz',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Chip ESP32 trên nút bấm chỉ hỗ trợ tần số 2.4GHz. Vui lòng chọn mạng có đuôi 2.4G hoặc tắt tạm thời mạng 5GHz nếu gặp lỗi.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.brown.shade800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Wi-Fi Selection Section
          _buildFieldLabel('Chọn mạng Wi-Fi căn hộ', isRequired: true),
          const SizedBox(height: 10),

          // List of Scanned Networks
          Column(
            children: [
              ..._mockWifiNetworks.map((net) {
                final ssid = net['ssid'] as String;
                final isSelected = !_isCustomSsid && _selectedSsid == ssid;
                final isRecommended = net['isRecommended'] as bool;
                final signal = net['signal'] as String;
                final rssi = net['rssi'] as int;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: _isProvisioningWifi ? null : () => _onSsidSelected(ssid),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentLight.withValues(alpha: 0.4) : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.borderLight,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected ? AppColors.shadowSm : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: isSelected ? AppColors.accent : AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      ssid,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (isRecommended) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryUltraLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Đề xuất',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Text(
                                      '2.4GHz',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const Text(
                                      ' • ',
                                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      'Sóng $signal ($rssi dBm)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildRssiBadge(rssi),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Option to enter other Wi-Fi
              InkWell(
                onTap: _isProvisioningWifi ? null : () => _onSsidSelected('__custom__'),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isCustomSsid ? AppColors.accentLight.withValues(alpha: 0.4) : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isCustomSsid ? AppColors.accent : AppColors.borderLight,
                      width: _isCustomSsid ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCustomSsid ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: _isCustomSsid ? AppColors.accent : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Nhập tên mạng Wi-Fi khác...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isCustomSsid) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customSsidController,
                  enabled: !_isProvisioningWifi,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên SSID Wi-Fi căn hộ (2.4GHz)',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.wifi_outlined, size: 20, color: AppColors.accent),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accent, width: 1.8),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 22),

          // Wi-Fi Password Field
          _buildFieldLabel('Mật khẩu Wi-Fi', isRequired: true),
          const SizedBox(height: 8),
          TextField(
            controller: _wifiPasswordController,
            obscureText: _isWifiPasswordObscured,
            enabled: !_isProvisioningWifi,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu Wi-Fi',
              hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.accent),
              suffixIcon: IconButton(
                icon: Icon(
                  _isWifiPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _isWifiPasswordObscured = !_isWifiPasswordObscured;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mật khẩu sẽ được mã hóa và truyền trực tiếp tới nút bấm qua Bluetooth bảo mật.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),

          // Error Message Banner (e.g. wrong password simulation)
          if (_wifiProvisionError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _wifiProvisionError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().shake(duration: 400.ms),
          ],

          const SizedBox(height: 24),

          // Primary Provision Button
          ElevatedButton(
            onPressed: (isFormValid && !_isProvisioningWifi) ? _provisionWifi : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white70,
              elevation: (isFormValid && !_isProvisioningWifi) ? 3 : 0,
              shadowColor: AppColors.accentGlow,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProvisioningWifi
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _wifiProvisionStatusText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                    ],
                  )
                : _isWifiSuccess
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Nạp Wi-Fi thành công!',
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
                          Icon(Icons.wifi_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Nạp Wi-Fi vào nút bấm',
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

          // Simulation Hint Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mẹo thử nghiệm: Nhập bất kỳ mật khẩu nào (ví dụ 12345678) để nạp thành công, hoặc nhập "wrongpass" để kiểm tra cơ chế báo lỗi sai mật khẩu và cho phép nhập lại.',
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
              'Tài khoản ${_confirmedFullName.isNotEmpty ? _confirmedFullName : "Cư dân"} (${_confirmedPhone.isNotEmpty ? _confirmedPhone : "0912345678"}) đã liên kết thành công với ${_pairedDeviceName.isNotEmpty ? _pairedDeviceName : "Smart Order Button"}. Mạng Wi-Fi: ${_isCustomSsid ? _customSsidController.text.trim() : _selectedSsid} (2.4GHz).',
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
