import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'signup/widgets/step_welcome_view.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFD),
    body: SafeArea(
      child: StepWelcomeView(
        onStart: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SignUpScreen(initialStep: 1)),
        ),
        onLogin: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
      ),
    ),
  );
}
