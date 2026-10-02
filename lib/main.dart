import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartOrderButtonApp());
}

class SmartOrderButtonApp extends StatelessWidget {
  const SmartOrderButtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartOrder — Management & Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgPage,
        fontFamily: 'Be Vietnam Pro',
        fontFamilyFallback: const [
          'Inter',
          'Segoe UI',
          'Roboto',
          'sans-serif',
        ],
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.bgCard,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
