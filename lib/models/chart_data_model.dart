import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BarChartItem {
  final String label;
  final int value;

  const BarChartItem({required this.label, required this.value});
}

class DonutChartItem {
  final String label;
  final double percentage;
  final Color color;

  const DonutChartItem({
    required this.label,
    required this.percentage,
    required this.color,
  });

  static List<DonutChartItem> get sampleDonutItems => const [
    DonutChartItem(
      label: 'Bình Gas 12kg',
      percentage: 35,
      color: AppColors.accent,
    ),
    DonutChartItem(
      label: 'Nước Lavie 19L',
      percentage: 28,
      color: AppColors.info,
    ),
    DonutChartItem(
      label: 'Gạo ST25 5kg',
      percentage: 18,
      color: AppColors.success,
    ),
    DonutChartItem(
      label: 'Giấy vệ sinh',
      percentage: 12,
      color: AppColors.purple,
    ),
    DonutChartItem(
      label: 'Khác',
      percentage: 7,
      color: AppColors.textMuted,
    ),
  ];
}
