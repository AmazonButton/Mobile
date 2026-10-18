import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'signup_theme.dart';
import 'signup_ui_components.dart';

/// Step 5: Onboarding completion celebrate view with connected device card and app entry CTA.
class StepSuccessView extends StatelessWidget {
  final String fullName;
  final String deviceName;
  final String wifiSsid;
  final VoidCallback onFinish;
  final VoidCallback onAddAnotherDevice;

  const StepSuccessView({
    super.key,
    required this.fullName,
    this.deviceName = 'Nút nhấn · A3F9',
    this.wifiSsid = 'Nhà Minh',
    required this.onFinish,
    required this.onAddAnotherDevice,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Image.asset(
                      'assets/illustrations/step5_complete.png',
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SignupFallbackIllustration(icon: LucideIcons.partyPopper),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 24),

                  Text(
                    'Xong rồi, $fullName!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: SignupTheme.figmaDark,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Thiết bị của bạn đã sẵn sàng. Thử nhấn nút trên thiết bị xem sao.',
                    style: TextStyle(
                      fontSize: 15,
                      color: SignupTheme.figmaMuted,
                      height: 1.4,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Success Device Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: SignupTheme.figmaBlueLight,
                      borderRadius: BorderRadius.circular(20),
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
                                border: Border.all(color: SignupTheme.figmaBlueBorder),
                              ),
                              child: const Icon(LucideIcons.disc, color: SignupTheme.figmaBlue, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deviceName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: SignupTheme.figmaDark,
                                      fontFamily: SignupTheme.fontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$wifiSsid · 2.4GHz',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: SignupTheme.figmaMuted,
                                      fontFamily: SignupTheme.fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.checkCircle2, color: SignupTheme.figmaSuccess, size: 24),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(LucideIcons.check, color: SignupTheme.figmaSuccess, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Đã kết nối',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: SignupTheme.figmaSuccess,
                                fontFamily: SignupTheme.fontFamily,
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
                    style: TextStyle(fontSize: 13, color: SignupTheme.figmaMuted),
                  ),

                  const Spacer(),

                  SignupPrimaryButton(
                    label: 'Vào ứng dụng',
                    onTap: onFinish,
                  ),
                  const SizedBox(height: 8),
                  SignupSecondaryButton(
                    label: 'Thêm thiết bị khác',
                    onTap: onAddAnotherDevice,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
