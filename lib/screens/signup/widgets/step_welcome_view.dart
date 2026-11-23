import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../widgets/app_motion.dart';
import '../../../widgets/auth_guide.dart';
import 'signup_theme.dart';
import 'signup_ui_components.dart';

/// Step 0: Welcome view with animated mascot companion & interactive swipeable
/// 3-slide onboarding deck that stays crisp and reachable at every text scale.
class StepWelcomeView extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onLogin;

  const StepWelcomeView({
    super.key,
    required this.onStart,
    required this.onLogin,
  });

  @override
  State<StepWelcomeView> createState() => _StepWelcomeViewState();
}

class _StepWelcomeViewState extends State<StepWelcomeView> {
  int _slideIndex = 0;

  static const _slides = [
    (
      icon: LucideIcons.zap,
      badge: 'Đặt hàng 1 chạm',
      title: 'Một nút nhấn nhỏ. Kết nối thật dễ.',
      subtitle: 'Bấm nhẹ nút vật lý là giao nước, gas tận cửa trong 15–25 phút.',
      mascotMsg: 'Xin chào! Mình sẽ đồng hành cùng bạn.',
      mood: GuideMood.welcome,
      accent: Color(0xFF0E6BA8),
      softBg: Color(0xFFE0F2FE),
    ),
    (
      icon: LucideIcons.bluetooth,
      badge: 'Ghép BLE 30 giây',
      title: 'Tự động tìm nút & nạp Wi-Fi nhanh.',
      subtitle: 'Nhấn giữ nút 5 giây, kết nối Bluetooth trực tiếp không cần cài phức tạp.',
      mascotMsg: 'Ghép Bluetooth và nạp Wi-Fi cực nhanh!',
      mood: GuideMood.guiding,
      accent: Color(0xFF2563EB),
      softBg: Color(0xFFEFF6FF),
    ),
    (
      icon: LucideIcons.shieldCheck,
      badge: 'An toàn & Đổi mới 1-1',
      title: 'Bảo mật IoT chuẩn HMAC-SHA256.',
      subtitle: 'Cửa sổ 60s hủy đơn nếu bấm nhầm, đại lý chính hãng freeship 5km.',
      mascotMsg: 'An tâm tuyệt đối, bấm là giao ngay!',
      mood: GuideMood.happy,
      accent: Color(0xFF059669),
      softBg: Color(0xFFECFDF5),
    ),
  ];

  Widget _buildSlideCard(({
    IconData icon,
    String badge,
    String title,
    String subtitle,
    String mascotMsg,
    GuideMood mood,
    Color accent,
    Color softBg,
  }) slide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: slide.accent.withValues(alpha: 0.16)),
        boxShadow: AppMotion.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: slide.softBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(slide.icon, color: slide.accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: slide.softBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    slide.badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: slide.accent,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slide.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.15,
                    height: 1.2,
                    color: SignupTheme.figmaDark,
                    fontFamily: SignupTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slide.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.32,
                    color: SignupTheme.figmaMuted,
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

  @override
  Widget build(BuildContext context) {
    final current = _slides[_slideIndex.clamp(0, _slides.length - 1)];
    final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final deckHeight = (138.0 * (1.0 + (textScale - 1.0) * 0.85)).clamp(138.0, 256.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),
                  StaggeredReveal(
                    index: 0,
                    child: AuthGuide(
                      large: true,
                      mood: current.mood,
                      message: current.mascotMsg,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title & Subtitle
                  const StaggeredReveal(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Một nút bấm. Kết nối dễ dàng.',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: SignupTheme.figmaDark,
                            height: 1.22,
                            fontFamily: SignupTheme.fontFamily,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Cùng bắt đầu với Smart Order Button nhé!',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: SignupTheme.figmaMuted,
                            fontFamily: SignupTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interactive Swipeable 3-Slide Onboarding Deck
                  StaggeredReveal(
                    index: 2,
                    child: HeroSlideDeck(
                      height: deckHeight,
                      viewportFraction: 0.94,
                      activeDotColor: current.accent,
                      autoPlayInterval: const Duration(milliseconds: 4600),
                      onPageChanged: (i) {
                        if (mounted) setState(() => _slideIndex = i);
                      },
                      slides: _slides.map(_buildSlideCard).toList(),
                    ),
                  ),

                  const Spacer(flex: 2),
                  const SizedBox(height: 14),

                  // Bottom CTAs
                  StaggeredReveal(
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SignupPrimaryButton(
                          label: 'Bắt đầu',
                          onTap: widget.onStart,
                        ),
                        const SizedBox(height: 10),
                        SignupSecondaryButton(
                          label: 'Tôi đã có tài khoản rồi',
                          onTap: widget.onLogin,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
