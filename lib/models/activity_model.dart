import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ActivityType { order, device, user, alert, system }

class ActivityModel {
  final String icon;
  final ActivityType type;
  final String title;
  final String description;
  final String time;

  const ActivityModel({
    required this.icon,
    required this.type,
    required this.title,
    required this.description,
    required this.time,
  });

  Color get dotColor {
    switch (type) {
      case ActivityType.order:
        return AppColors.accent;
      case ActivityType.device:
        return AppColors.info;
      case ActivityType.user:
        return AppColors.purple;
      case ActivityType.alert:
        return AppColors.danger;
      case ActivityType.system:
        return AppColors.textSecondary;
    }
  }

  Color get dotBgColor {
    switch (type) {
      case ActivityType.order:
        return AppColors.accentLight;
      case ActivityType.device:
        return AppColors.infoLight;
      case ActivityType.user:
        return AppColors.purpleLight;
      case ActivityType.alert:
        return AppColors.dangerLight;
      case ActivityType.system:
        return AppColors.borderLight;
    }
  }

  static List<ActivityModel> get sampleActivities => const [
    ActivityModel(
      icon: '📦',
      type: ActivityType.order,
      title: 'Đơn mới',
      description: 'từ căn hộ A1-1205 — Bình Gas 12kg',
      time: '2 phút trước',
    ),
    ActivityModel(
      icon: '📡',
      type: ActivityType.device,
      title: 'ESP32-C1-0915',
      description: 'Thiết bị mất kết nối mạng',
      time: '15 phút trước',
    ),
    ActivityModel(
      icon: '✅',
      type: ActivityType.order,
      title: 'SOB-20260919-001',
      description: 'Đơn hàng đã giao thành công',
      time: '28 phút trước',
    ),
    ActivityModel(
      icon: '👤',
      type: ActivityType.user,
      title: 'Trần Thị Hoa (B3-0204)',
      description: 'Tài khoản mới đăng ký thành công',
      time: '45 phút trước',
    ),
    ActivityModel(
      icon: '🔋',
      type: ActivityType.alert,
      title: 'ESP32-A1-1205',
      description: 'Cảnh báo pin yếu: còn 8%',
      time: '1 giờ trước',
    ),
    ActivityModel(
      icon: '🚫',
      type: ActivityType.order,
      title: 'SOB-20260919-005',
      description: 'Đơn bị hủy bởi cư dân',
      time: '1.5 giờ trước',
    ),
    ActivityModel(
      icon: '⚙️',
      type: ActivityType.system,
      title: 'Cập nhật danh mục',
      description: 'Hệ thống thêm +2 sản phẩm mới',
      time: '2 giờ trước',
    ),
    ActivityModel(
      icon: '📡',
      type: ActivityType.device,
      title: 'ESP32-B1-1108',
      description: 'Thiết bị đã kết nối lại bình thường',
      time: '3 giờ trước',
    ),
  ];
}
