import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'constants/app_colors.dart';
import 'widgets/app_motion.dart';
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

Future<void> _initFirebaseInBackground() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 4));
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService().initialize().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('Firebase background initialization note: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
  // Read cached tokens locally (<5ms) so first frame paints immediately
  await ApiClient().init();
  runApp(const SmartOrderButtonApp());
  // Initialize Firebase & FCM asynchronously without blocking app startup
  _initFirebaseInBackground();
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
          splashFactory: InkSparkle.splashFactory,
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              for (final platform in TargetPlatform.values)
                platform: const AppPageTransitionsBuilder(),
            },
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF0F172A),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            centerTitle: true,
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            showDragHandle: false,
            dragHandleColor: Color(0xFFCBD5E1),
            dragHandleSize: Size(40, 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF0F172A),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          textTheme: const TextTheme(
            titleLarge: SampleA.title,
            titleMedium: SampleA.section,
            bodyLarge: SampleA.body,
            bodyMedium: SampleA.body,
            bodySmall: SampleA.caption,
          ),
          inputDecorationTheme: InputDecorationThemeData(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            errorMaxLines: 6,
            helperMaxLines: 6,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0E6BA8),
                width: 1.5,
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: SampleA.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size(48, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              textStyle: SampleA.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F7FB),
          fontFamily: SampleA.fontFamily,
          fontFamilyFallback: const [
            'Inter',
            'Segoe UI',
            'Roboto',
            'sans-serif',
          ],
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0E6BA8),
            primary: const Color(0xFF0E6BA8),
            secondary: AppColors.accent,
            surface: AppColors.bgCard,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
