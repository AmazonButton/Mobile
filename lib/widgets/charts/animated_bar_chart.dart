import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/chart_data_model.dart';

class AnimatedBarChartCard extends StatefulWidget {
  const AnimatedBarChartCard({super.key});

  @override
  State<AnimatedBarChartCard> createState() => _AnimatedBarChartCardState();
}

class _AnimatedBarChartCardState extends State<AnimatedBarChartCard>
    with SingleTickerProviderStateMixin {
  int _selectedFilter = 0; // 0: 7 ngày, 1: 30 ngày, 2: Quý
  late AnimationController _chartController;
  int? _hoveredBarIndex;

  final List<List<BarChartItem>> _datasets = [
    // 7 days
    const [
      BarChartItem(label: 'T2', value: 186),
      BarChartItem(label: 'T3', value: 215),
      BarChartItem(label: 'T4', value: 198),
      BarChartItem(label: 'T5', value: 242),
      BarChartItem(label: 'T6', value: 268),
      BarChartItem(label: 'T7', value: 312),
      BarChartItem(label: 'CN', value: 248),
    ],
    // 30 days summary (4 weeks)
    const [
      BarChartItem(label: 'Tuần 1', value: 1420),
      BarChartItem(label: 'Tuần 2', value: 1680),
      BarChartItem(label: 'Tuần 3', value: 1890),
      BarChartItem(label: 'Tuần 4', value: 1750),
    ],
    // Quarter (3 months)
    const [
      BarChartItem(label: 'Tháng 7', value: 6540),
      BarChartItem(label: 'Tháng 8', value: 7210),
      BarChartItem(label: 'Tháng 9', value: 8150),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _chartController.forward();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  void _changeFilter(int index) {
    if (_selectedFilter == index) return;
    setState(() {
      _selectedFilter = index;
    });
    _chartController.reset();
    _chartController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _datasets[_selectedFilter];
    final maxValue = currentData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

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
          // ── Header: Title & Filters ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Đơn hàng theo thời gian',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.bgPage,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterButton('7 ngày', 0),
                    _buildFilterButton('30 ngày', 1),
                    _buildFilterButton('Quý', 2),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Chart Area ──
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: currentData.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final double targetHeightFraction = item.value / maxValue;

                final staggerStart = (idx * 0.08).clamp(0.0, 0.7);
                final staggerEnd = (staggerStart + 0.6).clamp(0.0, 1.0);

                final barAnim = CurvedAnimation(
                  parent: _chartController,
                  curve: Interval(staggerStart, staggerEnd, curve: Curves.easeOutBack),
                );

                final bool isHovered = _hoveredBarIndex == idx;

                return Expanded(
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredBarIndex = idx),
                    onExit: (_) => setState(() => _hoveredBarIndex = null),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isHovered ? 1.0 : 0.75,
                          child: Text(
                            '${item.value}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isHovered ? FontWeight.w800 : FontWeight.w600,
                              color: isHovered ? AppColors.accent : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Growing Bar
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedBuilder(
                              animation: barAnim,
                              builder: (context, _) {
                                return LayoutBuilder(
                                  builder: (context, barConstraints) {
                                    final maxHeight = barConstraints.maxHeight;
                                    final currentHeight =
                                        maxHeight * targetHeightFraction * barAnim.value;

                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: isHovered ? 34 : 28,
                                      height: currentHeight.clamp(0.0, maxHeight),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isHovered
                                              ? [AppColors.accentHover, AppColors.accent]
                                              : [AppColors.accent, const Color(0xFFE06B18)],
                                        ),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                        boxShadow: isHovered
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.accentGlow,
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                )
                                              ]
                                            : null,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Day label
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
                            color: isHovered ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, int index) {
    final bool isActive = _selectedFilter == index;

    return GestureDetector(
      onTap: () => _changeFilter(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
