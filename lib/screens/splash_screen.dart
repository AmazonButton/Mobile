import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _lottieController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isTextShown = false;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _lottieController.addListener(_onLottieProgress);
  }

  void _onLottieProgress() {
    // Khi xe chạy được 50% thời gian (0.5) và chữ chưa được hiện
    if (_lottieController.value >= 0.45 && !_isTextShown) {
      setState(() {
        _isTextShown = true;
      });
      _fadeController.forward();
    }
  }

  void _navigateToLogin() {
    if (_isNavigated || !mounted) return;
    _isNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _lottieController.removeListener(_onLottieProgress);
    _lottieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToLogin, // Cho phép chạm để chuyển nhanh nếu muốn
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),

                        // Chiếc xe chạy ngang qua
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: Lottie.asset(
                            'assets/scooter_anim.json',
                            controller: _lottieController,
                            onLoaded: (composition) {
                              _lottieController
                                ..duration = composition.duration
                                ..forward().then((_) {
                                  // Khi xe chạy xong hoàn toàn
                                  Future.delayed(
                                    const Duration(milliseconds: 200),
                                    _navigateToLogin,
                                  );
                                });
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback nếu Lottie gặp sự cố
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _fadeController.forward();
                                Future.delayed(
                                  const Duration(seconds: 2),
                                  _navigateToLogin,
                                );
                              });
                              return const Icon(
                                Icons.delivery_dining,
                                size: 120,
                                color: Color(0xFFF5862B),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Khối Tiêu Đề & Mô Tả mờ dần hiện lên (Fade In 800ms)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/smart_order_button_logo.png',
                                      width: 38,
                                      height: 38,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Image.asset(
                                        'assets/fpt_toggle_button.png',
                                        width: 38,
                                        height: 38,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error2, stackTrace2) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  RichText(
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Smart',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E1E1E),
                                            fontFamily: 'Be Vietnam Pro',
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Order',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF5862B),
                                            fontFamily: 'Be Vietnam Pro',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 36,
                                ),
                                child: Text(
                                  'Gửi hàng, theo dõi và giao mọi món hàng quanh thành phố — chỉ với một nút bấm.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Be Vietnam Pro',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 4),

                        // Nút bỏ qua nhỏ ở góc dưới
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: TextButton(
                            onPressed: _navigateToLogin,
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
