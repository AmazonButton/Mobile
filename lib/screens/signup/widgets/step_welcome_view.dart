import 'package:flutter/material.dart';
import '../../../widgets/auth_guide.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'signup_theme.dart';
import 'signup_ui_components.dart';

/// Step 0: Welcome view presenting the mascot illustration and onboarding introduction.
class StepWelcomeView extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onLogin;

  const StepWelcomeView({
    super.key,
    required this.onStart,
    required this.onLogin,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  const AuthGuide(
                    large: true,
                    mood: GuideMood.welcome,
                    message: 'Xin chào! Mình sẽ đồng hành cùng bạn.',
                  ),
                  const SizedBox(height: 28),

                  // Title & Subtitle
                  const Text(
                    'Một nút bấm. Kết nối dễ dàng.',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: SignupTheme.figmaDark,
                      height: 1.25,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cùng bắt đầu với Smart Order Button nhé!',
                      style: TextStyle(
                        fontSize: 15,
                        color: SignupTheme.figmaMuted,
                        fontFamily: SignupTheme.fontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feature pill card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: SignupTheme.figmaInputBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SignupTheme.figmaBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: SignupTheme.figmaBlueLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.sparkles,
                            color: SignupTheme.figmaBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Một nút nhấn nhỏ. Kết nối thật dễ.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: SignupTheme.figmaDark,
                              fontFamily: SignupTheme.fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Bottom CTAs
                  SignupPrimaryButton(label: 'Bắt đầu', onTap: onStart),
                  const SizedBox(height: 8),
                  SignupSecondaryButton(
                    label: 'Tôi đã có tài khoản rồi',
                    onTap: onLogin,
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
