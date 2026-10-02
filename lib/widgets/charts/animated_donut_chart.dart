import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/chart_data_model.dart';

class AnimatedDonutChartCard extends StatefulWidget {
  const AnimatedDonutChartCard({super.key});

  @override
  State<AnimatedDonutChartCard> createState() => _AnimatedDonutChartCardState();
}

class _AnimatedDonutChartCardState extends State<AnimatedDonutChartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sweepAnimation;
  int? _hoveredIndex;

  final List<DonutChartItem> _items = DonutChartItem.sampleDonutItems;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _sweepAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tỷ lệ sản phẩm',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 400;

              final donutWidget = SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _sweepAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(170, 170),
                          painter: _DonutChartPainter(
                            items: _items,
                            progress: _sweepAnimation.value,
                            hoveredIndex: _hoveredIndex,
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '1,842',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Tổng đơn',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final legendWidget = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final bool isHovered = _hoveredIndex == idx;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = idx),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? AppColors.bgPage
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isHovered
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isHovered
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${item.percentage.toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isHovered
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    Center(child: donutWidget),
                    const SizedBox(height: 16),
                    legendWidget,
                  ],
                );
              }

              return Row(
                children: [
                  donutWidget,
                  const SizedBox(width: 24),
                  Expanded(child: legendWidget),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutChartItem> items;
  final double progress;
  final int? hoveredIndex;

  _DonutChartPainter({
    required this.items,
    required this.progress,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 68.0;
    const strokeWidthNormal = 24.0;
    const strokeWidthHover = 28.0;

    double startAngle = -math.pi / 2;
    const gapAngle = 0.04;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isHovered = hoveredIndex == i;
      final sweepAngle = (item.percentage / 100) * 2 * math.pi * progress;

      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? strokeWidthHover : strokeWidthNormal
        ..strokeCap = StrokeCap.round;

      final effectiveSweep = math.max(0.0, sweepAngle - gapAngle);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        effectiveSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}
