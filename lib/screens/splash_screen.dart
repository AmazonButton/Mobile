import 'dart:async';
import 'dart:math' as math;
import '../widgets/app_motion.dart';
import '../widgets/sample_a.dart';
import 'package:flutter/material.dart';
import '../services/services.dart';
import 'dashboard_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glideController;
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isTextShown = false;
  bool _isNavigated = false;
  Timer? _navTimer;
  late final Future<bool> _authCheckFuture;

  Future<bool> _preloadAuth() async {
    try {
      final apiClient = ApiClient();
      if (!apiClient.isAuthenticated) {
        await apiClient.ensureAuthenticated();
      }
      return apiClient.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    // Pre-check auth in parallel while splash animation plays
    _authCheckFuture = _preloadAuth();

    // Snappy logo glide (~760ms, strong ease-out)
    _glideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );

    // Subtle Wi-Fi wave pulse + gentle float while logo glides (respects reduced motion)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Wordmark & tagline fade in cleanly while staying completely still
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppMotion.easeOut,
    );

    _glideController.addListener(_onGlideProgress);
    _glideController.forward().then((_) {
      if (!mounted) return;
      _navTimer?.cancel();
      _navTimer = Timer(const Duration(milliseconds: 140), _navigateNext);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.allowAmbient(context)) {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  void _onGlideProgress() {
    if (_glideController.value >= 0.2 && !_isTextShown) {
      setState(() => _isTextShown = true);
      _fadeController.forward();
    }
  }

  Future<void> _navigateNext() async {
    if (_isNavigated || !mounted) return;
    _isNavigated = true;

    final isAuthenticated = await _authCheckFuture;
    if (!mounted) return;

    if (isAuthenticated) {
      NotificationService().syncTokenWithBackend();
    }

    final Widget targetScreen = isAuthenticated
        ? const DashboardScreen()
        : const WelcomeScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.easeOut,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.975, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _glideController.removeListener(_onGlideProgress);
    _glideController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateNext,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Phần 1: Biểu tượng Logo của anh chuyển động mượt (chạy từ trái vào + tỏa sóng nhẹ)
              SizedBox(
                width: 260,
                height: 150,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _glideController,
                    _pulseController,
                  ]),
                  builder: (context, _) {
                    final glideT = AppMotion.easeOut.transform(
                      _glideController.value.clamp(0.0, 1.0),
                    );
                    final slideX = -115.0 * (1.0 - glideT);
                    final floatY =
                        math.sin(_pulseController.value * math.pi * 2) * 3.0;
                    final tilt =
                        (1.0 - _glideController.value.clamp(0.0, 1.0)) * -0.06;
                    final pulseScale = 0.85 + (_pulseController.value * 0.45);
                    final pulseOpacity = (1.0 - _pulseController.value) * 0.22;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle ocean-blue signal ripple behind moving logo
                        Transform.translate(
                          offset: Offset(slideX, floatY),
                          child: Transform.scale(
                            scale: pulseScale,
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0E6BA8)
                                      .withValues(alpha: pulseOpacity),
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Top icon slice of assets/smart_order_button_logo.png
                        Transform.translate(
                          offset: Offset(slideX, floatY),
                          child: Transform.rotate(
                            angle: tilt,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.topCenter,
                                heightFactor: 0.72,
                                child: Image.asset(
                                  'assets/smart_order_button_logo.png',
                                  width: 230,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.shopping_cart_rounded,
                                    size: 84,
                                    color: Color(0xFF0E6BA8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Phần 2: Chữ SMARTOrderBUTTON giữ nguyên vị trí cố định + hiện mượt
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    ClipRect(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        heightFactor: 0.28,
                        child: Image.asset(
                          'assets/smart_order_button_logo.png',
                          width: 230,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Text(
                            'SMARTOrderBUTTON',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0E6BA8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                        'Gửi hàng, theo dõi và giao mọi món hàng quanh thành phố — chỉ với một nút bấm.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                          fontFamily: SampleA.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 4),

              FadeTransition(
                opacity: _fadeAnimation,
                child: TextButton(
                  onPressed: _navigateNext,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade400,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  child: const Text('Bỏ qua →'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
