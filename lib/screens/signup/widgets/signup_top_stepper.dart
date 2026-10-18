import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'signup_theme.dart';

/// Top header bar displaying navigation back button, segmented progress pills, and help trigger.
class SignupTopStepper extends StatelessWidget {
  final int currentStep; // 0: Welcome, 1..5: Steps
  final VoidCallback onBack;
  final VoidCallback onHelp;

  const SignupTopStepper({
    super.key,
    required this.currentStep,
    required this.onBack,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStep == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: SignupTheme.figmaDark, size: 22),
              onPressed: onBack,
            ),
            IconButton(
              icon: const Icon(LucideIcons.helpCircle, color: SignupTheme.figmaMuted, size: 22),
              onPressed: onHelp,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: SignupTheme.figmaDark, size: 22),
                onPressed: onBack,
              ),
              const SizedBox(width: 4),
              // Segmented 5-pill progress bar
              Expanded(
                child: Row(
                  children: List.generate(5, (index) {
                    final isFilled = index < currentStep;
                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          color: isFilled ? SignupTheme.figmaBlue : SignupTheme.figmaBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(LucideIcons.helpCircle, color: SignupTheme.figmaMuted, size: 22),
                onPressed: onHelp,
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
                    color: SignupTheme.figmaMuted,
                    fontFamily: SignupTheme.fontFamily,
                  ),
                ),
                Text(
                  'Bước $currentStep/5',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: SignupTheme.figmaBlue,
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
