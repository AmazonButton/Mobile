import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile_service.dart';
import 'dashboard_screen.dart';

/// Màn hình Đăng ký & Onboarding thiết bị Smart Order Button
/// Thiết kế chuẩn theo Figma: "Một nút nhấn. Năm bước kết nối"
class SignUpScreen extends StatefulWidget {
  final int initialStep; // 0: Chào mừng, 1: Bước 1, 2: Bước 2, 3: Bước 3, 4: Bước 4, 5: Bước 5

  const SignUpScreen({
    super.key,
    this.initialStep = 0,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late final PageController _pageController;
  late int _currentStep;

  // ── Figma Design Tokens ──
  static const Color figmaBlue = Color(0xFF1877F2);
  static const Color figmaBlueLight = Color(0xFFEFF6FF);
  static const Color figmaBlueBorder = Color(0xFFBFDBFE);
  static const Color figmaDark = Color(0xFF0F172A);
  static const Color figmaMuted = Color(0xFF64748B);
  static const Color figmaBorder = Color(0xFFE2E8F0);
  static const Color figmaBg = Colors.white;
  static const Color figmaInputBg = Color(0xFFF8FAFC);
  static const Color figmaSuccess = Color(0xFF16A34A);
  static const Color figmaDanger = Color(0xFFEF4444);

  // ── Step 1 Form Controllers & State ──
  final TextEditingController _fullNameController = TextEditingController(text: 'Minh');
  final TextEditingController _phoneController = TextEditingController(text: '0912345123');
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  String? _nameError;
  String? _phoneError;

  // Confirmed identity
  String _confirmedFullName = 'Minh';
  String _confirmedPhone = '0912345123';

  // ── Step 2 OTP State ──
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  int _otpCountdown = 45;
  Timer? _otpTimer;
  bool _isOtpVerifying = false;
  String? _otpError;

  // ── Step 3 Bluetooth State ──
  // 3a: Wake device, 3b: Select device, 3c: Pairing
  int _step3SubPhase = 0; // 0: Wake device, 1: Searching/Select, 2: Pairing
  final String _selectedDeviceName = 'Nút nhấn · A3F9';
  bool _isScanningBle = false;

  // ── Step 4 WiFi State ──
  // 4a: Select WiFi, 4b: Password, 4c: 3-stage Connecting
  int _step4SubPhase = 0; // 0: Select WiFi, 1: Password, 2: 3-stage Connecting
  String _selectedWifiSsid = 'Nhà Minh';
  final TextEditingController _wifiPasswordController = TextEditingController(text: '12345678');
  bool _isWifiPasswordObscured = true;
  int _wifiConnectProgressStage = 0; // 0: Sent WiFi, 1: Connecting Router, 2: Registering Cloud, 3: Done

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: _currentStep);

    _fullNameController.addListener(_validateStep1);
    _phoneController.addListener(_validateStep1);
    _otpController.addListener(() => setState(() {}));
    _wifiPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _otpTimer?.cancel();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    HapticFeedback.lightImpact();
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleBack() {
    HapticFeedback.lightImpact();
    if (_currentStep == 0) {
      Navigator.of(context).pop();
      return;
    }

    if (_currentStep == 3 && _step3SubPhase > 0) {
      setState(() => _step3SubPhase--);
      return;
    }

    if (_currentStep == 4 && _step4SubPhase > 0) {
      setState(() => _step4SubPhase--);
      return;
    }

    _goToStep(_currentStep - 1);
  }

  // ── Step 1 Validation ──
  void _validateStep1() {
    final name = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isNotEmpty && name.length < 2) {
      _nameError = 'Họ và tên tối thiểu 2 ký tự';
    } else {
      _nameError = null;
    }

    if (phone.isNotEmpty && (!phone.startsWith('0') || phone.length != 10)) {
      _phoneError = 'Số điện thoại phải gồm 10 số (bắt đầu bằng 0)';
    } else {
      _phoneError = null;
    }
    setState(() {});
  }

  bool get _isStep1Valid {
    final name = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    return name.length >= 2 && phone.startsWith('0') && phone.length == 10;
  }

  void _submitStep1() {
    if (!_isStep1Valid) return;
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    _confirmedFullName = _fullNameController.text.trim();
    _confirmedPhone = _phoneController.text.trim();

    UserProfileService().updateName(_confirmedFullName);
    UserProfileService().updatePhone(_confirmedPhone);

    _startOtpCountdown();
    _goToStep(2);
  }

  // ── Step 2 OTP ──
  void _startOtpCountdown() {
    _otpTimer?.cancel();
    setState(() => _otpCountdown = 45);
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_otpCountdown > 0) {
        setState(() => _otpCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResendOtp() {
    if (_otpCountdown > 0) return;
    HapticFeedback.lightImpact();
    _startOtpCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã gửi lại mã xác nhận tới $_confirmedPhone'),
        backgroundColor: figmaBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _verifyOtp([String? pin]) async {
    final code = pin ?? _otpController.text.trim();
    if (code.length != 6 || _isOtpVerifying) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isOtpVerifying = true;
      _otpError = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (code == '000000') {
      HapticFeedback.vibrate();
      setState(() {
        _isOtpVerifying = false;
        _otpError = 'Mã xác nhận chưa chính xác. Vui lòng kiểm tra lại.';
      });
      return;
    }

    HapticFeedback.mediumImpact();
    _otpTimer?.cancel();
    setState(() {
      _isOtpVerifying = false;
      _step3SubPhase = 0;
    });
    _goToStep(3);
  }

  // ── Step 3 BLE ──
  void _startBleDiscovery() {
    HapticFeedback.lightImpact();
    setState(() {
      _step3SubPhase = 1;
      _isScanningBle = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _isScanningBle = false;
      });
    });
  }

  void _connectBleDevice() {
    HapticFeedback.mediumImpact();
    setState(() => _step3SubPhase = 2);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _step4SubPhase = 0);
      _goToStep(4);
    });
  }

  // ── Step 4 WiFi ──
  void _submitWifiNetwork() {
    HapticFeedback.lightImpact();
    setState(() => _step4SubPhase = 1);
  }

  void _startWifiProvisioning() {
    if (_wifiPasswordController.text.isEmpty) return;
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _step4SubPhase = 2;
      _wifiConnectProgressStage = 0;
    });

    // 3-stage provisioning progression
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _wifiConnectProgressStage = 1);
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() => _wifiConnectProgressStage = 2);
    });

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      setState(() => _wifiConnectProgressStage = 3);
      HapticFeedback.heavyImpact();
      _goToStep(5);
    });
  }

  // ── Step 5 Complete ──
  void _finishAndGoToApp() {
    HapticFeedback.heavyImpact();
    UserProfileService().updateName(_confirmedFullName);
    UserProfileService().updatePhone(_confirmedPhone);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  // ── Help Modal ──
  void _showHelpBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: figmaBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: figmaBlueLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.helpCircle, color: figmaBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cần hỗ trợ cài đặt?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: figmaDark,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpItem(
                  '1. Kích hoạt nút bấm',
                  'Nhấn giữ nút tròn khoảng 6 giây cho đến khi đèn LED nhấp nháy xanh dương liên tục.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  '2. Mạng Wi-Fi tương thích',
                  'Nút bấm IoT chỉ hỗ trợ băng tần 2.4GHz. Vui lòng không chọn mạng 5GHz.',
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  '3. Quyền Bluetooth',
                  'Đảm bảo Bluetooth trên điện thoại đã bật và cấp quyền tìm kiếm thiết bị gần đây.',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: figmaBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Đã hiểu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: figmaDark,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(
            fontSize: 13,
            color: figmaMuted,
            height: 1.4,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
      ],
    );
  }

  String _formatMaskedPhone(String phone) {
    if (phone.length < 10) return phone;
    return '+84 ${phone.substring(1, 3)}xx xxx ${phone.substring(phone.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: figmaBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar & Stepper (ẩn trên màn hình Chào mừng để giống Figma)
            if (_currentStep > 0) _buildTopStepperHeader() else _buildWelcomeHeader(),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildStep1Page(),
                  _buildStep2Page(),
                  _buildStep3Page(),
                  _buildStep4Page(),
                  _buildStep5Page(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Top Header on Welcome Screen
  // ─────────────────────────────────────────────────────────────
  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: figmaDark, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.helpCircle, color: figmaMuted, size: 22),
            onPressed: _showHelpBottomSheet,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Top Stepper Navigation (Segmented Pill + Labels)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopStepperHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: figmaDark, size: 22),
                onPressed: _handleBack,
              ),
              const SizedBox(width: 4),
              // Segmented 5-pill progress bar
              Expanded(
                child: Row(
                  children: List.generate(5, (index) {
                    final isFilled = index < _currentStep;
                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: isFilled ? figmaBlue : figmaBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(LucideIcons.helpCircle, color: figmaMuted, size: 22),
                onPressed: _showHelpBottomSheet,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CÀI ĐẶT THIẾT BỊ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: figmaMuted,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
                Text(
                  'Bước $_currentStep/5',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: figmaBlue,
                    fontFamily: 'Be Vietnam Pro',
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
  // 0. Welcome Screen (Chào mừng)
  // ─────────────────────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          // Mascot Illustration
          Center(
            child: Image.asset(
              'assets/illustrations/welcome.png',
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.sparkles),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 32),

          // Title & Subtitle
          const Text(
            'Cùng cài đặt thiết bị của bạn nhé!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: figmaDark,
              height: 1.25,
              fontFamily: 'Be Vietnam Pro',
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chỉ mất khoảng 2 phút.',
              style: TextStyle(
                fontSize: 15,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Feature pill card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: figmaInputBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: figmaBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: figmaBlueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.sparkles, color: figmaBlue, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Một nút nhấn nhỏ. Kết nối thật dễ.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: figmaDark,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Bottom CTAs
          _buildPrimaryButton(
            label: 'Bắt đầu',
            onTap: () => _goToStep(1),
          ),
          const SizedBox(height: 8),
          _buildSecondaryButton(
            label: 'Tôi đã có tài khoản',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. Step 1: Resident Identity (Họ tên và số điện thoại)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep1Page() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Mascot
          Center(
            child: Image.asset(
              'assets/illustrations/step1_identity.png',
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.user),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Bạn tên là gì?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: figmaDark,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chúng mình sẽ dùng tên này để chào bạn.',
            style: TextStyle(
              fontSize: 15,
              color: figmaMuted,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 24),

          // Field: Full Name
          const Text(
            'Họ và tên',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: figmaMuted,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fullNameController,
            focusNode: _fullNameFocus,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: figmaDark,
              fontFamily: 'Be Vietnam Pro',
            ),
            decoration: InputDecoration(
              hintText: 'Nhập họ và tên',
              hintStyle: const TextStyle(color: figmaMuted, fontSize: 16, fontWeight: FontWeight.normal),
              filled: true,
              fillColor: figmaInputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: figmaBorder, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _nameError != null ? figmaDanger : figmaBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: figmaBlue, width: 2),
              ),
            ),
          ),
          if (_nameError != null) ...[
            const SizedBox(height: 6),
            Text(_nameError!, style: const TextStyle(color: figmaDanger, fontSize: 12)),
          ],

          const SizedBox(height: 18),

          // Field: Phone
          const Text(
            'Số điện thoại',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: figmaMuted,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: figmaDark,
              letterSpacing: 1.1,
              fontFamily: 'Be Vietnam Pro',
            ),
            decoration: InputDecoration(
              hintText: '0912 345 123',
              hintStyle: const TextStyle(color: figmaMuted, fontSize: 16, fontWeight: FontWeight.normal),
              filled: true,
              fillColor: figmaInputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: figmaBorder, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _phoneError != null ? figmaDanger : figmaBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: figmaBlue, width: 2),
              ),
            ),
          ),
          if (_phoneError != null) ...[
            const SizedBox(height: 6),
            Text(_phoneError!, style: const TextStyle(color: figmaDanger, fontSize: 12)),
          ],

          const SizedBox(height: 40),

          // Primary Button
          _buildPrimaryButton(
            label: 'Gửi mã xác nhận',
            isEnabled: _isStep1Valid,
            onTap: _submitStep1,
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Bằng việc tiếp tục, bạn đồng ý với Điều khoản và Chính sách bảo mật.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Step 2: SMS OTP Verification (Mã xác nhận)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep2Page() {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 62,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: figmaDark,
        fontFamily: 'Be Vietnam Pro',
      ),
      decoration: BoxDecoration(
        color: figmaInputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: figmaBorder, width: 1.5),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Image.asset(
              'assets/illustrations/step2_otp.png',
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.mail),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Nhập mã gồm 6 số',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: figmaDark,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mã đã gửi tới số điện thoại của bạn.',
            style: TextStyle(
              fontSize: 15,
              color: figmaMuted,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 18),

          // Masked phone row & "Sửa số" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMaskedPhone(_confirmedPhone),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: figmaDark,
                  fontFamily: 'Be Vietnam Pro',
                ),
              ),
              GestureDetector(
                onTap: () => _goToStep(1),
                child: const Text(
                  'Sửa số',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: figmaBlue,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 6-digit Pinput
          Center(
            child: Pinput(
              controller: _otpController,
              focusNode: _otpFocusNode,
              length: 6,
              autofocus: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: BoxDecoration(
                  color: figmaInputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: figmaBlue, width: 2),
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                decoration: BoxDecoration(
                  color: figmaInputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: figmaBlue, width: 1.5),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyWith(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: figmaDanger, width: 1.8),
                ),
              ),
              preFilledWidget: const Text(
                '—',
                style: TextStyle(color: figmaMuted, fontSize: 16),
              ),
              onCompleted: (pin) => _verifyOtp(pin),
            ),
          ),

          if (_otpError != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _otpError!,
                style: const TextStyle(
                  color: figmaDanger,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Countdown / Resend code
          Center(
            child: _otpCountdown > 0
                ? Text(
                    'Gửi lại mã sau 0:${_otpCountdown.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: figmaMuted,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  )
                : GestureDetector(
                    onTap: _handleResendOtp,
                    child: const Text(
                      'Gửi lại mã',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: figmaBlue,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 48),

          // Confirm button
          _buildPrimaryButton(
            label: _isOtpVerifying ? 'Đang xác thực...' : 'Xác nhận',
            isEnabled: _otpController.text.length == 6 && !_isOtpVerifying,
            onTap: () => _verifyOtp(),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Mã có hiệu lực trong 5 phút.',
              style: TextStyle(
                fontSize: 12,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Step 3: Hardware Bluetooth Pairing (Đánh thức & Ghép nối)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep3Page() {
    if (_step3SubPhase == 0) {
      // 3A: Đánh thức thiết bị
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                'assets/illustrations/step3_wake_device.png',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.bluetooth),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đánh thức thiết bị của bạn',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: figmaDark,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nhấn giữ nút khoảng 6 giây, đến khi đèn xanh nhấp nháy.',
              style: TextStyle(
                fontSize: 15,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 24),

            // Signal Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: figmaBlueLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: figmaBlueBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.radio, color: figmaBlue, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xanh dương nhấp nháy',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: figmaDark,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Thiết bị đã sẵn sàng để tìm thấy.',
                          style: TextStyle(
                            fontSize: 13,
                            color: figmaMuted,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            _buildPrimaryButton(
              label: 'Đèn đã nhấp nháy xanh',
              onTap: _startBleDiscovery,
            ),
            const SizedBox(height: 8),
            _buildSecondaryButton(
              label: 'Không thấy đèn?',
              onTap: _showHelpBottomSheet,
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    } else if (_step3SubPhase == 1) {
      // 3B: Tìm thấy thiết bị rồi!
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                _isScanningBle
                    ? 'assets/illustrations/step3_searching.png'
                    : 'assets/illustrations/step3_select_device.png',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.bluetooth),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isScanningBle ? 'Đang tìm thiết bị...' : 'Tìm thấy thiết bị rồi!',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: figmaDark,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isScanningBle ? 'Xin vui lòng đưa nút bấm lại gần điện thoại.' : 'Đây có phải nút nhấn của bạn không?',
              style: const TextStyle(
                fontSize: 15,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 24),

            if (!_isScanningBle) ...[
              // Device Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: figmaBlueLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: figmaBlue, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: figmaBlueBorder),
                          ),
                          child: const Icon(LucideIcons.disc, color: figmaBlue, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDeviceName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: figmaDark,
                                  fontFamily: 'Be Vietnam Pro',
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Ở gần bạn · Tín hiệu mạnh',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: figmaMuted,
                                  fontFamily: 'Be Vietnam Pro',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.checkCircle2, color: figmaBlue, size: 24),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Đã chọn · Sẵn sàng ghép nối',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: figmaBlue,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Đối chiếu 4 ký tự A3F9 trên thiết bị của bạn.',
                style: TextStyle(fontSize: 13, color: figmaMuted),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: figmaBlue),
                ),
              ),
            ],

            const Spacer(),

            _buildPrimaryButton(
              label: 'Kết nối',
              isEnabled: !_isScanningBle,
              onTap: _connectBleDevice,
            ),
            const SizedBox(height: 8),
            _buildSecondaryButton(
              label: 'Tìm lại thiết bị',
              onTap: _startBleDiscovery,
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    } else {
      // 3C: Đang ghép nối
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(flex: 1),
            Image.asset(
              'assets/illustrations/step3_pairing.png',
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.bluetooth),
            ),
            const SizedBox(height: 32),
            const Text(
              'Đang ghép nối...',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: figmaDark,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đang thiết lập kênh giao tiếp an toàn qua Bluetooth.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: figmaBlue),
            const Spacer(flex: 2),
          ],
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. Step 4: WiFi Provisioning (Cấp mạng Wi-Fi)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep4Page() {
    if (_step4SubPhase == 0) {
      // 4A: Chọn WiFi
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                'assets/illustrations/step4_select_wifi.png',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.wifi),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chọn WiFi cho thiết bị',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: figmaDark,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn mạng 2.4GHz bạn muốn dùng.',
              style: TextStyle(
                fontSize: 15,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 20),

            // WiFi Options
            _buildWifiItem(
              ssid: 'Nhà Minh',
              desc: '2.4GHz · Điện thoại đang dùng',
              isSelected: _selectedWifiSsid == 'Nhà Minh',
              isSupported: true,
              onTap: () => setState(() => _selectedWifiSsid = 'Nhà Minh'),
            ),
            const SizedBox(height: 10),
            _buildWifiItem(
              ssid: 'Nhà Minh_5G',
              desc: '5GHz · Không được hỗ trợ',
              isSelected: false,
              isSupported: false,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nút bấm chỉ hỗ trợ Wi-Fi băng tần 2.4GHz!'),
                    backgroundColor: figmaDanger,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildWifiItem(
              ssid: 'Phòng khách',
              desc: '2.4GHz · Tín hiệu vừa',
              isSelected: _selectedWifiSsid == 'Phòng khách',
              isSupported: true,
              onTap: () => setState(() => _selectedWifiSsid = 'Phòng khách'),
            ),

            const Spacer(),

            _buildPrimaryButton(
              label: 'Tiếp tục',
              onTap: _submitWifiNetwork,
            ),
            const SizedBox(height: 8),
            _buildSecondaryButton(
              label: 'Nhập tên mạng thủ công',
              onTap: () {},
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    } else if (_step4SubPhase == 1) {
      // 4B: Nhập mật khẩu WiFi
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                'assets/illustrations/step4_wifi_pwd.png',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.lock),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nhập mật khẩu WiFi',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: figmaDark,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kết nối nút nhấn với mạng nhà bạn.',
              style: TextStyle(
                fontSize: 15,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 20),

            // Network header card with "Đổi" button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: figmaInputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: figmaBorder),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.wifi, color: figmaBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedWifiSsid,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: figmaDark,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '2.4GHz',
                          style: TextStyle(fontSize: 12, color: figmaMuted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _step4SubPhase = 0),
                    child: const Text(
                      'Đổi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: figmaBlue,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Mật khẩu WiFi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _wifiPasswordController,
              obscureText: _isWifiPasswordObscured,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: figmaDark,
                fontFamily: 'Be Vietnam Pro',
              ),
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu WiFi',
                hintStyle: const TextStyle(color: figmaMuted, fontSize: 15),
                filled: true,
                fillColor: figmaInputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isWifiPasswordObscured ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: figmaMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isWifiPasswordObscured = !_isWifiPasswordObscured),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: figmaBorder, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: figmaBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: figmaBlue, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Note card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: figmaInputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: figmaBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.keyRound, color: figmaMuted, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nhập mật khẩu của mạng $_selectedWifiSsid, không phải mật khẩu tài khoản.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: figmaMuted,
                        height: 1.4,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildPrimaryButton(
              label: 'Kết nối WiFi',
              isEnabled: _wifiPasswordController.text.isNotEmpty,
              onTap: _startWifiProvisioning,
            ),
            const SizedBox(height: 8),
            _buildSecondaryButton(
              label: 'Cần giúp đỡ',
              onTap: _showHelpBottomSheet,
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    } else {
      // 4C: Tiến trình 3 giai đoạn kết nối WiFi
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                'assets/illustrations/step4_wifi_connecting.png',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.wifi),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đang kết nối WiFi...',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: figmaDark,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_selectedDeviceName → $_selectedWifiSsid',
              style: const TextStyle(
                fontSize: 15,
                color: figmaMuted,
                fontFamily: 'Be Vietnam Pro',
              ),
            ),
            const SizedBox(height: 28),

            // 3-Stage Progress Card
            _buildConnectionStageItem(
              title: 'Gửi thông tin WiFi tới thiết bị',
              subtitle: _wifiConnectProgressStage >= 1 ? 'Đã gửi' : 'Đang xử lý',
              isCompleted: _wifiConnectProgressStage >= 1,
              isInProgress: _wifiConnectProgressStage == 0,
            ),
            const SizedBox(height: 12),
            _buildConnectionStageItem(
              title: 'Thiết bị đang vào mạng',
              subtitle: _wifiConnectProgressStage >= 2
                  ? 'Đã vào mạng'
                  : (_wifiConnectProgressStage == 1 ? 'Đang xử lý' : 'Chờ gửi WiFi'),
              isCompleted: _wifiConnectProgressStage >= 2,
              isInProgress: _wifiConnectProgressStage == 1,
            ),
            const SizedBox(height: 12),
            _buildConnectionStageItem(
              title: 'Đang đăng ký với hệ thống',
              subtitle: _wifiConnectProgressStage >= 3
                  ? 'Thành công'
                  : (_wifiConnectProgressStage == 2 ? 'Đang xử lý' : 'Chờ thiết bị vào mạng'),
              isCompleted: _wifiConnectProgressStage >= 3,
              isInProgress: _wifiConnectProgressStage == 2,
            ),

            const Spacer(),

            // Disabled state button during connection
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: figmaBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Đang kết nối',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildSecondaryButton(
              label: 'Cần giúp đỡ',
              onTap: _showHelpBottomSheet,
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Tối đa 60 giây cho toàn bộ quá trình.',
                style: TextStyle(fontSize: 12, color: figmaMuted),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
  }

  Widget _buildWifiItem({
    required String ssid,
    required String desc,
    required bool isSelected,
    required bool isSupported,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? figmaBlueLight : (isSupported ? figmaInputBg : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? figmaBlue : figmaBorder,
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.wifi,
              color: isSupported ? (isSelected ? figmaBlue : figmaDark) : figmaMuted,
              size: 20,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ssid,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSupported ? figmaDark : figmaMuted,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSupported ? figmaMuted : figmaDanger,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.lock, color: figmaMuted, size: 16),
            if (isSelected) ...[
              const SizedBox(width: 10),
              const Icon(LucideIcons.checkCircle2, color: figmaBlue, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStageItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isInProgress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInProgress ? figmaBlueLight : figmaInputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInProgress ? figmaBlueBorder : figmaBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          if (isCompleted)
            const Icon(LucideIcons.checkCircle2, color: figmaSuccess, size: 24)
          else if (isInProgress)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: figmaBlue, strokeWidth: 2.2),
            )
          else
            const Icon(LucideIcons.circleDashed, color: figmaMuted, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: figmaDark,
                    fontFamily: 'Be Vietnam Pro',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isCompleted ? figmaSuccess : (isInProgress ? figmaBlue : figmaMuted),
                    fontWeight: isCompleted || isInProgress ? FontWeight.w600 : FontWeight.normal,
                    fontFamily: 'Be Vietnam Pro',
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
  // 5. Step 5: Complete & Celebrate (Hoàn thành)
  // ─────────────────────────────────────────────────────────────
  Widget _buildStep5Page() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Image.asset(
              'assets/illustrations/step5_complete.png',
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _buildFallbackIllustration(LucideIcons.partyPopper),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 24),

          Text(
            'Xong rồi, $_confirmedFullName!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: figmaDark,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Thiết bị của bạn đã sẵn sàng. Thử nhấn nút trên thiết bị xem sao.',
            style: TextStyle(
              fontSize: 15,
              color: figmaMuted,
              height: 1.4,
              fontFamily: 'Be Vietnam Pro',
            ),
          ),
          const SizedBox(height: 28),

          // Success Device Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: figmaBlueLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: figmaBlue, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: figmaBlueBorder),
                      ),
                      child: const Icon(LucideIcons.disc, color: figmaBlue, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDeviceName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: figmaDark,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_selectedWifiSsid · 2.4GHz',
                            style: const TextStyle(
                              fontSize: 13,
                              color: figmaMuted,
                              fontFamily: 'Be Vietnam Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.checkCircle2, color: figmaSuccess, size: 24),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(LucideIcons.check, color: figmaSuccess, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Đã kết nối',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: figmaSuccess,
                        fontFamily: 'Be Vietnam Pro',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Đèn xanh lá = kết nối thành công.',
            style: TextStyle(fontSize: 13, color: figmaMuted),
          ),

          const Spacer(),

          _buildPrimaryButton(
            label: 'Vào ứng dụng',
            onTap: _finishAndGoToApp,
          ),
          const SizedBox(height: 8),
          _buildSecondaryButton(
            label: 'Thêm thiết bị khác',
            onTap: () {
              setState(() {
                _step3SubPhase = 0;
              });
              _goToStep(3);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI Helpers (Buttons, Illustration fallback)
  // ─────────────────────────────────────────────────────────────
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: figmaBlue,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isEnabled ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: figmaBlue,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Be Vietnam Pro',
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIllustration(IconData icon) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: figmaBlueLight,
        shape: BoxShape.circle,
        border: Border.all(color: figmaBlueBorder, width: 2),
      ),
      child: Center(
        child: Icon(icon, color: figmaBlue, size: 56),
      ),
    );
  }
}
