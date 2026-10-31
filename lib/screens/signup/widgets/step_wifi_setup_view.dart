import '../../../widgets/auth_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'signup_theme.dart';
import 'signup_ui_components.dart';

/// Step 4: WiFi provisioning view handling network selection, password input, and 3-stage connection progress.
class StepWifiSetupView extends StatefulWidget {
  final String selectedDeviceName;
  final VoidCallback onWifiConnected;

  const StepWifiSetupView({
    super.key,
    this.selectedDeviceName = 'Nút nhấn · A3F9',
    required this.onWifiConnected,
  });

  @override
  State<StepWifiSetupView> createState() => StepWifiSetupViewState();
}

class StepWifiSetupViewState extends State<StepWifiSetupView> {
  int _step4SubPhase = 0; // 0: Select WiFi, 1: Password, 2: 3-stage Connecting
  String _selectedWifiSsid = 'Nhà Minh';
  final TextEditingController _wifiPasswordController = TextEditingController(
    text: '12345678',
  );
  bool _isWifiPasswordObscured = true;
  int _wifiConnectProgressStage =
      0; // 0: Sent WiFi, 1: Connecting Router, 2: Registering Cloud, 3: Done

  @override
  void initState() {
    super.initState();
    _wifiPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _wifiPasswordController.dispose();
    super.dispose();
  }

  /// Allows parent orchestrator to handle back navigation across subphases
  bool handleBack() {
    if (_step4SubPhase > 0) {
      setState(() => _step4SubPhase--);
      return true; // handled
    }
    return false; // not handled, parent should pop or go to previous step
  }

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
      widget.onWifiConnected();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: _buildSubPhaseContent()),
          ),
        );
      },
    );
  }

  Widget _buildSubPhaseContent() {
    if (_step4SubPhase == 0) {
      // 4A: Chọn WiFi
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AuthGuide(
            message: 'Cùng kết nối nút bấm với Wi-Fi nhà bạn nhé!',
            mood: _step4SubPhase == 2 ? GuideMood.waiting : GuideMood.guiding,
          ),
          const SizedBox(height: 24),
          const Text(
            'Chọn WiFi cho thiết bị',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn mạng 2.4GHz bạn muốn dùng.',
            style: TextStyle(
              fontSize: 15,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
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
                  backgroundColor: SignupTheme.figmaDanger,
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

          SignupPrimaryButton(label: 'Tiếp tục', onTap: _submitWifiNetwork),
          const SizedBox(height: 8),
          SignupSecondaryButton(label: 'Nhập tên mạng thủ công', onTap: () {}),
          const SizedBox(height: 16),
        ],
      );
    } else if (_step4SubPhase == 1) {
      // 4B: Nhập mật khẩu WiFi
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AuthGuide(
            message: 'Cùng kết nối nút bấm với Wi-Fi nhà bạn nhé!',
            mood: _step4SubPhase == 2 ? GuideMood.waiting : GuideMood.guiding,
          ),
          const SizedBox(height: 24),
          const Text(
            'Nhập mật khẩu WiFi',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kết nối nút nhấn với mạng nhà bạn.',
            style: TextStyle(
              fontSize: 15,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 20),

          // Network header card with "Đổi" button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: SignupTheme.figmaInputBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SignupTheme.figmaBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.wifi,
                  color: SignupTheme.figmaBlue,
                  size: 20,
                ),
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
                          color: SignupTheme.figmaDark,
                          fontFamily: SignupTheme.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '2.4GHz',
                        style: TextStyle(
                          fontSize: 12,
                          color: SignupTheme.figmaMuted,
                        ),
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
                      color: SignupTheme.figmaBlue,
                      fontFamily: SignupTheme.fontFamily,
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
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _wifiPasswordController,
            obscureText: _isWifiPasswordObscured,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu WiFi',
              hintStyle: const TextStyle(
                color: SignupTheme.figmaMuted,
                fontSize: 15,
              ),
              filled: true,
              fillColor: SignupTheme.figmaInputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isWifiPasswordObscured
                      ? LucideIcons.eyeOff
                      : LucideIcons.eye,
                  color: SignupTheme.figmaMuted,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _isWifiPasswordObscured = !_isWifiPasswordObscured,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: SignupTheme.figmaBorder,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: SignupTheme.figmaBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: SignupTheme.figmaBlue,
                  width: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Note card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SignupTheme.figmaInputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SignupTheme.figmaBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.keyRound,
                  color: SignupTheme.figmaMuted,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nhập mật khẩu của mạng $_selectedWifiSsid, không phải mật khẩu tài khoản.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: SignupTheme.figmaMuted,
                      height: 1.4,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          SignupPrimaryButton(
            label: 'Kết nối WiFi',
            isEnabled: _wifiPasswordController.text.isNotEmpty,
            onTap: _startWifiProvisioning,
          ),
          const SizedBox(height: 8),
          SignupSecondaryButton(
            label: 'Cần giúp đỡ',
            onTap: () => showSignupHelpBottomSheet(context),
          ),
          const SizedBox(height: 24),
        ],
      );
    } else {
      // 4C: Tiến trình 3 giai đoạn kết nối WiFi
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AuthGuide(
            message: 'Cùng kết nối nút bấm với Wi-Fi nhà bạn nhé!',
            mood: _step4SubPhase == 2 ? GuideMood.waiting : GuideMood.guiding,
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang kết nối WiFi...',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.selectedDeviceName} → $_selectedWifiSsid',
            style: const TextStyle(
              fontSize: 15,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
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
                : (_wifiConnectProgressStage == 1
                      ? 'Đang xử lý'
                      : 'Chờ gửi WiFi'),
            isCompleted: _wifiConnectProgressStage >= 2,
            isInProgress: _wifiConnectProgressStage == 1,
          ),
          const SizedBox(height: 12),
          _buildConnectionStageItem(
            title: 'Đang đăng ký với hệ thống',
            subtitle: _wifiConnectProgressStage >= 3
                ? 'Thành công'
                : (_wifiConnectProgressStage == 2
                      ? 'Đang xử lý'
                      : 'Chờ thiết bị vào mạng'),
            isCompleted: _wifiConnectProgressStage >= 3,
            isInProgress: _wifiConnectProgressStage == 2,
          ),

          const Spacer(),

          // Disabled state button during connection
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: SignupTheme.figmaBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Đang kết nối',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: SignupTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SignupSecondaryButton(
            label: 'Cần giúp đỡ',
            onTap: () => showSignupHelpBottomSheet(context),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Tối đa 60 giây cho toàn bộ quá trình.',
              style: TextStyle(fontSize: 12, color: SignupTheme.figmaMuted),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
          color: isSelected
              ? SignupTheme.figmaBlueLight
              : (isSupported
                    ? SignupTheme.figmaInputBg
                    : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? SignupTheme.figmaBlue : SignupTheme.figmaBorder,
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.wifi,
              color: isSupported
                  ? (isSelected ? SignupTheme.figmaBlue : SignupTheme.figmaDark)
                  : SignupTheme.figmaMuted,
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
                      color: isSupported
                          ? SignupTheme.figmaDark
                          : SignupTheme.figmaMuted,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSupported
                          ? SignupTheme.figmaMuted
                          : SignupTheme.figmaDanger,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.lock,
              color: SignupTheme.figmaMuted,
              size: 16,
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              const Icon(
                LucideIcons.checkCircle2,
                color: SignupTheme.figmaBlue,
                size: 20,
              ),
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
        color: isInProgress
            ? SignupTheme.figmaBlueLight
            : SignupTheme.figmaInputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInProgress
              ? SignupTheme.figmaBlueBorder
              : SignupTheme.figmaBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          if (isCompleted)
            const Icon(
              LucideIcons.checkCircle2,
              color: SignupTheme.figmaSuccess,
              size: 24,
            )
          else if (isInProgress)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: SignupTheme.figmaBlue,
                strokeWidth: 2.2,
              ),
            )
          else
            const Icon(
              LucideIcons.circleDashed,
              color: SignupTheme.figmaMuted,
              size: 22,
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SignupTheme.figmaDark,
                    fontFamily: SignupTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isCompleted
                        ? SignupTheme.figmaSuccess
                        : (isInProgress
                              ? SignupTheme.figmaBlue
                              : SignupTheme.figmaMuted),
                    fontWeight: isCompleted || isInProgress
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontFamily: SignupTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
