import '../../../widgets/auth_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'signup_theme.dart';
import 'signup_ui_components.dart';

/// Step 3: Hardware Bluetooth discovery and pairing view with 3 sub-phases (Wake, Search/Select, Pairing).
class StepBlePairingView extends StatefulWidget {
  final VoidCallback onPairingComplete;

  const StepBlePairingView({super.key, required this.onPairingComplete});

  @override
  State<StepBlePairingView> createState() => StepBlePairingViewState();
}

class StepBlePairingViewState extends State<StepBlePairingView> {
  int _step3SubPhase = 0; // 0: Wake device, 1: Searching/Select, 2: Pairing
  final String _selectedDeviceName = 'Nút nhấn · A3F9';
  bool _isScanningBle = false;

  /// Allows parent orchestrator to handle back navigation across subphases
  bool handleBack() {
    if (_step3SubPhase > 0) {
      setState(() => _step3SubPhase--);
      return true; // handled
    }
    return false; // not handled, parent should pop or go to previous step
  }

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
      widget.onPairingComplete();
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
    if (_step3SubPhase == 0) {
      // 3A: Đánh thức thiết bị
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AuthGuide(
            message: 'Đặt nút bấm ở gần điện thoại để cùng kết nối nhé!',
            mood: GuideMood.guiding,
          ),
          const SizedBox(height: 24),
          const Text(
            'Đánh thức thiết bị của bạn',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nhấn giữ nút khoảng 6 giây, đến khi đèn xanh nhấp nháy.',
            style: TextStyle(
              fontSize: 15,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 24),

          // Signal Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SignupTheme.figmaBlueLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SignupTheme.figmaBlueBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.radio,
                    color: SignupTheme.figmaBlue,
                    size: 22,
                  ),
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
                          color: SignupTheme.figmaDark,
                          fontFamily: SignupTheme.fontFamily,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Thiết bị đã sẵn sàng để tìm thấy.',
                        style: TextStyle(
                          fontSize: 13,
                          color: SignupTheme.figmaMuted,
                          fontFamily: SignupTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          SignupPrimaryButton(
            label: 'Đèn đã nhấp nháy xanh',
            onTap: _startBleDiscovery,
          ),
          const SizedBox(height: 8),
          SignupSecondaryButton(
            label: 'Không thấy đèn?',
            onTap: () => showSignupHelpBottomSheet(context),
          ),
          const SizedBox(height: 16),
        ],
      );
    } else if (_step3SubPhase == 1) {
      // 3B: Tìm thấy thiết bị rồi!
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AuthGuide(
            mood: _isScanningBle ? GuideMood.waiting : GuideMood.happy,
            message: _isScanningBle
                ? 'Mình đang tìm nút bấm ở gần bạn…'
                : 'Tìm thấy rồi! Hãy chọn nút bấm của bạn nhé.',
          ),
          const SizedBox(height: 24),
          Text(
            _isScanningBle ? 'Đang tìm thiết bị...' : 'Tìm thấy thiết bị rồi!',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isScanningBle
                ? 'Xin vui lòng đưa nút bấm lại gần điện thoại.'
                : 'Đây có phải nút nhấn của bạn không?',
            style: const TextStyle(
              fontSize: 15,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 24),

          if (!_isScanningBle) ...[
            // Device Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SignupTheme.figmaBlueLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: SignupTheme.figmaBlue, width: 2),
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
                          border: Border.all(
                            color: SignupTheme.figmaBlueBorder,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.disc,
                          color: SignupTheme.figmaBlue,
                          size: 24,
                        ),
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
                                color: SignupTheme.figmaDark,
                                fontFamily: SignupTheme.fontFamily,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Ở gần bạn · Tín hiệu mạnh',
                              style: TextStyle(
                                fontSize: 13,
                                color: SignupTheme.figmaMuted,
                                fontFamily: SignupTheme.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.checkCircle2,
                        color: SignupTheme.figmaBlue,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đã chọn · Sẵn sàng ghép nối',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SignupTheme.figmaBlue,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Đối chiếu 4 ký tự A3F9 trên thiết bị của bạn.',
              style: TextStyle(fontSize: 13, color: SignupTheme.figmaMuted),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: SignupTheme.figmaBlue),
              ),
            ),
          ],

          const Spacer(),

          SignupPrimaryButton(
            label: 'Kết nối',
            isEnabled: !_isScanningBle,
            onTap: _connectBleDevice,
          ),
          const SizedBox(height: 8),
          SignupSecondaryButton(
            label: 'Tìm lại thiết bị',
            onTap: _startBleDiscovery,
          ),
          const SizedBox(height: 16),
        ],
      );
    } else {
      // 3C: Đang ghép nối
      return Column(
        children: [
          const Spacer(flex: 1),
          Image.asset(
            'assets/illustrations/step3_pairing.png',
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const SignupFallbackIllustration(icon: LucideIcons.bluetooth),
          ),
          const SizedBox(height: 32),
          const Text(
            'Đang ghép nối...',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đang thiết lập kênh giao tiếp an toàn qua Bluetooth.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: SignupTheme.figmaBlue),
          const Spacer(flex: 2),
        ],
      );
    }
  }
}
