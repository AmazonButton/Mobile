import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class StatCardsGrid extends StatelessWidget {
  final AnimationController animationController;

  const StatCardsGrid({
    super.key,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 700) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
        }

        final cards = [
          _StatCardData(
            icon: Icons.receipt_long_rounded,
            trend: '↑ 12%',
            isTrendUp: true,
            targetValue: 248,
            format: (v) => '${v.toInt()}',
            label: 'Tổng đơn hôm nay',
            staggerDelay: 0.05,
          ),
          _StatCardData(
            icon: Icons.attach_money_rounded,
            trend: '↑ 8.5%',
            isTrendUp: true,
            targetValue: 18.6,
            format: (v) => '${v.toStringAsFixed(1)}M',
            label: 'Doanh thu hôm nay (VNĐ)',
            staggerDelay: 0.10,
          ),
          _StatCardData(
            icon: Icons.sensors_rounded,
            trend: '↑ 2',
            isTrendUp: true,
            targetValue: 156,
            format: (v) => '${v.toInt()}',
            label: 'Thiết bị đang online',
            staggerDelay: 0.15,
          ),
          _StatCardData(
            icon: Icons.access_time_rounded,
            trend: '↓ 3',
            isTrendUp: false,
            targetValue: 17,
            format: (v) => '${v.toInt()}',
            label: 'Đơn chờ xử lý',
            staggerDelay: 0.20,
          ),
        ];

        if (crossAxisCount == 4) {
          return Row(
            children: cards.asMap().entries.map((entry) {
              final idx = entry.key;
              final data = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: idx < cards.length - 1 ? 20 : 0,
                  ),
                  child: _StatCardItem(
                    data: data,
                    parentAnimation: animationController,
                  ),
                ),
              );
            }).toList(),
          );
        }

        // 2 or 1 columns
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: cards.map((data) {
            final double itemWidth = crossAxisCount == 2
                ? (constraints.maxWidth - 20) / 2
                : constraints.maxWidth;
            return SizedBox(
              width: itemWidth,
              child: _StatCardItem(
                data: data,
                parentAnimation: animationController,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCardData {
  final IconData icon;
  final String trend;
  final bool isTrendUp;
  final double targetValue;
  final String Function(double) format;
  final String label;
  final double staggerDelay;

  const _StatCardData({
    required this.icon,
    required this.trend,
    required this.isTrendUp,
    required this.targetValue,
    required this.format,
    required this.label,
    required this.staggerDelay,
  });
}

class _StatCardItem extends StatefulWidget {
  final _StatCardData data;
  final AnimationController parentAnimation;

  const _StatCardItem({
    required this.data,
    required this.parentAnimation,
  });

  @override
  State<_StatCardItem> createState() => _StatCardItemState();
}

class _StatCardItemState extends State<_StatCardItem> {
  bool _isHovered = false;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _counterAnimation;

  @override
  void initState() {
    super.initState();

    final start = widget.data.staggerDelay;
    final end = (start + 0.65).clamp(0.0, 1.0);

    final curved = CurvedAnimation(
      parent: widget.parentAnimation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(curved);

    _counterAnimation = Tween<double>(
      begin: 0.0,
      end: widget.data.targetValue,
    ).animate(CurvedAnimation(
      parent: widget.parentAnimation,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered ? AppColors.accent.withValues(alpha: 0.3) : AppColors.borderLight,
              ),
              boxShadow: _isHovered ? AppColors.shadowLg : AppColors.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row: Icon & Trend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0x141B3A5C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.data.icon,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.data.isTrendUp
                            ? AppColors.successLight
                            : AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.data.trend,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.data.isTrendUp
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Animated Counter Value
                AnimatedBuilder(
                  animation: _counterAnimation,
                  builder: (context, _) {
                    return Text(
                      widget.data.format(_counterAnimation.value),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),

                // Label
                Text(
                  widget.data.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
