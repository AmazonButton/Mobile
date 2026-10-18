import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'providers/providers.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().init();
  runApp(const SmartOrderButtonApp());
}

class SmartOrderButtonApp extends StatelessWidget {
  const SmartOrderButtonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
