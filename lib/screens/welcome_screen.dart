import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'signup/widgets/step_welcome_view.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F8FC),
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.42, 1.0],
          colors: [
            Color(0xFFEAF4FF),
            Color(0xFFF7FAFE),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: SafeArea(
        child: StepWelcomeView(
          onStart: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SignUpScreen(initialStep: 1),
            ),
          ),
          onLogin: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      ),
    ),
  );
}
