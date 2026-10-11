import 'package:flutter/material.dart';
import '../signup_screen.dart';

/// Chuyển hướng toàn bộ luồng đăng ký & cài đặt nút cũ sang luồng mới theo Figma
class ButtonOnboardingScreen extends StatelessWidget {
  const ButtonOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignUpScreen(initialStep: 0);
  }
}
