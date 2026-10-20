import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum DeviceStatus { online, warning, offline }

class DeviceModel {
  final String id;
  final String name;
  final String room;
  final String product;
  final String price;
  final int battery;
  final String badgeText;
  final String signal;
  final DeviceStatus status;
  final String wifiSsid;
  final String? imageUrl;

  const DeviceModel({
    required this.id,
    this.name = 'Nút thông minh',
    required this.room,
    this.product = 'Nhu yếu phẩm',
    this.price = 'Giá tiêu chuẩn',
    required this.battery,
    this.badgeText = '20L',
    this.signal = 'Rất tốt',
    required this.status,
    this.wifiSsid = 'Home_Network_5G',
    this.imageUrl,
  });

  /// Backward-compatible alias for room
  String get location => room;

  bool get isOffline => status == DeviceStatus.offline;
  bool get isOnline => status != DeviceStatus.offline;

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

  DeviceModel copyWith({
    String? id,
    String? name,
    String? room,
    String? product,
    String? price,
    int? battery,
    String? badgeText,
    String? signal,
    DeviceStatus? status,
    String? wifiSsid,
    String? imageUrl,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      room: room ?? this.room,
      product: product ?? this.product,
      price: price ?? this.price,
      battery: battery ?? this.battery,
      badgeText: badgeText ?? this.badgeText,
      signal: signal ?? this.signal,
      status: status ?? this.status,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'ACTIVE').toString().toUpperCase();
    final rawBattery = json['batteryLevel'] ?? json['battery'] ?? 100;
    final int batteryInt = rawBattery is int ? rawBattery : (int.tryParse(rawBattery.toString()) ?? 100);

    DeviceStatus status = DeviceStatus.online;
    if (rawStatus == 'OFFLINE' || rawStatus == 'DISABLED') {
      status = DeviceStatus.offline;
    } else if (batteryInt <= 20) {
      status = DeviceStatus.warning;
    }

    final id = json['deviceId']?.toString() ?? json['id']?.toString() ?? 'ESP32';
    final name = json['buttonName']?.toString() ??
        json['name']?.toString() ??
        json['customName']?.toString() ??
        'Nút thông minh';
    final room = json['roomLocation']?.toString() ??
        json['room']?.toString() ??
        json['location']?.toString() ??
        'Khu vực trong nhà';

    String product = 'Nhu yếu phẩm';
    String price = 'Giá tiêu chuẩn';
    String badge = '20L';

    final rawProds = json['products'] ?? json['buttonProducts'];
    if (rawProds is List && rawProds.isNotEmpty) {
      final bp = rawProds.first;
      if (bp is Map) {
        final p = bp['product'];
        if (p is Map) {
          product = p['productName']?.toString() ?? p['name']?.toString() ?? product;
          final pPrice = p['basePrice'] ?? p['price'];
          if (pPrice != null) {
            final pStr = pPrice.toString();
            price = pStr.endsWith('đ') ? pStr : '${pStr}đ';
          }
        } else {
          product = bp['productName']?.toString() ?? bp['name']?.toString() ?? product;
          final bPrice = bp['basePrice'] ?? bp['price'];
          if (bPrice != null) {
            final bStr = bPrice.toString();
            price = bStr.endsWith('đ') ? bStr : '${bStr}đ';
          }
        }
      }
    } else if (json['product'] != null) {
      product = json['product'].toString();
    } else if (json['productName'] != null) {
      product = json['productName'].toString();
    }

    if (json['price'] != null) {
      final pr = json['price'].toString();
      price = pr.endsWith('đ') ? pr : '${pr}đ';
    }

    if (json['badgeText'] != null) {
      badge = json['badgeText'].toString();
    } else if (product.contains('Gas')) {
      badge = '12kg';
    } else if (product.contains('500ml') || product.contains('Aquafina')) {
      badge = '24 chai';
    } else if (product.contains('20L') || product.contains('19L')) {
      badge = '20L';
    }

    final signal = json['signal']?.toString() ?? (status == DeviceStatus.online ? 'Rất tốt' : 'Mất tín hiệu');
    final wifi = json['wifiSsid']?.toString() ?? json['wifi']?.toString() ?? 'Home_Network_5G';
    final img = json['imageUrl']?.toString() ?? json['productImageUrl']?.toString();

    return DeviceModel(
      id: id,
      name: name,
      room: room,
      product: product,
      price: price,
      battery: batteryInt,
      badgeText: badge,
      signal: signal,
      status: status,
      wifiSsid: wifi,
      imageUrl: img,
    );
  }

  static List<DeviceModel> get sampleDevices => const [
    DeviceModel(
      id: 'btn-1',
      name: 'Nút Bếp',
      room: 'Khu vực Bếp ăn',
      product: 'Nước Lavie 20L',
      price: '65.000đ',
      battery: 85,
      badgeText: '20L',
      signal: 'Rất tốt',
      status: DeviceStatus.online,
      wifiSsid: 'Home_Network_5G',
    ),
    DeviceModel(
      id: 'btn-2',
      name: 'Nút Phòng Khách',
      room: 'Bàn trà sofa',
      product: 'Aquafina 500ml · 24 chai',
      price: '98.000đ',
      battery: 15,
      badgeText: '24 chai',
      signal: 'Ổn định',
      status: DeviceStatus.warning,
      wifiSsid: 'Home_Network_5G',
    ),
    DeviceModel(
      id: 'btn-3',
      name: 'Nút Ban Công',
      room: 'Khu vực Ban công',
      product: 'Gas Petrolimex 12kg',
      price: '380.000đ',
      battery: 90,
      badgeText: '12kg',
      signal: 'Rất tốt',
      status: DeviceStatus.online,
      wifiSsid: 'Home_Network_5G',
    ),
  ];
}
