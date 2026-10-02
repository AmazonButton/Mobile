import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum DeviceStatus { online, warning, offline }

class DeviceModel {
  final String id;
  final String location;
  final int battery;
  final DeviceStatus status;

  const DeviceModel({
    required this.id,
    required this.location,
    required this.battery,
    required this.status,
  });

  bool get isOffline => status == DeviceStatus.offline;

  Color get batteryColor {
    if (isOffline || battery <= 15) {
      return AppColors.danger;
    }
    if (battery <= 30) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  Color get statusBgColor {
    if (isOffline || battery <= 15) {
      return AppColors.dangerLight;
    }
    if (battery <= 30) {
      return AppColors.warningLight;
    }
    return AppColors.successLight;
  }

  String get batteryText => isOffline ? 'Offline' : '$battery%';

  static List<DeviceModel> get sampleDevices => const [
    DeviceModel(
      id: 'ESP32-A1-1205',
      location: 'Tòa A1, Tầng 12, P.1205',
      battery: 8,
      status: DeviceStatus.warning,
    ),
    DeviceModel(
      id: 'ESP32-B2-0301',
      location: 'Tòa B2, Tầng 3, P.0301',
      battery: 12,
      status: DeviceStatus.warning,
    ),
    DeviceModel(
      id: 'ESP32-C1-0915',
      location: 'Tòa C1, Tầng 9, P.0915',
      battery: 0,
      status: DeviceStatus.offline,
    ),
    DeviceModel(
      id: 'ESP32-A3-0702',
      location: 'Tòa A3, Tầng 7, P.0702',
      battery: 18,
      status: DeviceStatus.warning,
    ),
    DeviceModel(
      id: 'ESP32-B1-1108',
      location: 'Tòa B1, Tầng 11, P.1108',
      battery: 65,
      status: DeviceStatus.online,
    ),
    DeviceModel(
      id: 'ESP32-A2-0406',
      location: 'Tòa A2, Tầng 4, P.0406',
      battery: 92,
      status: DeviceStatus.online,
    ),
  ];
}
