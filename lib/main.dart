import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'constants/app_colors.dart';
import 'widgets/sample_a.dart';
import 'providers/providers.dart';
import 'screens/splash_screen.dart';
import 'services/services.dart';

/// Top-level background message entry-point for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Graceful fallback for test or unconfigured environments
  }
}

/// Global navigator key for notification deep-linking and app-wide navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }
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
        ChangeNotifierProvider(
          create: (_) => OrderProvider()..startLiveUpdates(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'SmartOrder — Management & Delivery',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: const TextTheme(
            titleLarge: SampleA.title,
            titleMedium: SampleA.section,
            bodyLarge: SampleA.body,
            bodyMedium: SampleA.body,
            bodySmall: SampleA.caption,
          ),
          inputDecorationTheme: const InputDecorationThemeData(
            errorMaxLines: 6,
            helperMaxLines: 6,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              textStyle: SampleA.body,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              textStyle: SampleA.body,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          scaffoldBackgroundColor: AppColors.bgPage,
          fontFamily: SampleA.fontFamily,
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
