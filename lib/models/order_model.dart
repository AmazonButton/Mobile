import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../utils/formatters.dart';

enum OrderStatus { success, info, warning, danger }

class OrderModel {
  final String id;
  final String orderCode;
  final String customerName;
  final String apartment;
  final String product;
  final String title;
  final String buttonName;
  final String deviceId;
  final String time;
  final String price;
  final num rawAmount;
  final OrderStatus status;
  final String rawStatus;
  final String statusText;
  final IconData icon;
  final Map<String, dynamic>? rawJson;

  const OrderModel({
    required this.id,
    this.orderCode = '#ORD',
    required this.customerName,
    required this.apartment,
    required this.product,
    this.title = '',
    this.buttonName = 'Nút bấm IoT',
    this.deviceId = '',
    required this.time,
    this.price = '0đ',
    this.rawAmount = 0,
    required this.status,
    this.rawStatus = 'PENDING',
    required this.statusText,
    this.icon = LucideIcons.package,
    this.rawJson,
  });

  String get displayTitle => title.isNotEmpty ? title : product;

  bool get isPending => rawStatus == 'PENDING';
  bool get isShipping => rawStatus == 'SHIPPING';
  bool get isCompleted => rawStatus == 'COMPLETED' || rawStatus == 'DELIVERED';
  bool get isCancelled => rawStatus == 'CANCELLED';
  bool get isEmergencyCancellable => isPending;

  Color get statusColor {
    switch (status) {
      case OrderStatus.success:
        return AppColors.success;
      case OrderStatus.info:
        return AppColors.info;
      case OrderStatus.warning:
        return AppColors.warning;
      case OrderStatus.danger:
        return AppColors.danger;
    }
  }

  Color get statusBgColor {
    switch (status) {
      case OrderStatus.success:
        return AppColors.successLight;
      case OrderStatus.info:
        return AppColors.infoLight;
      case OrderStatus.warning:
        return AppColors.warningLight;
      case OrderStatus.danger:
        return AppColors.dangerLight;
    }
  }

  static String formatCurrency(num amount) => CurrencyFormatter.format(amount);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['orderStatus'] ?? json['status'] ?? 'PENDING').toString().toUpperCase();
    OrderStatus status = OrderStatus.warning;
    String statusText = 'Chờ xử lý';

    if (rawStatus == 'COMPLETED' || rawStatus == 'DELIVERED') {
      status = OrderStatus.success;
      statusText = 'Đã giao';
    } else if (rawStatus == 'SHIPPING') {
      status = OrderStatus.info;
      statusText = 'Đang giao';
    } else if (rawStatus == 'CONFIRMED' || rawStatus == 'PROCESSING') {
      status = OrderStatus.info;
      statusText = 'Đang xử lý';
    } else if (rawStatus == 'CANCELLED') {
      status = OrderStatus.danger;
      statusText = 'Đã hủy';
    } else if (rawStatus == 'PENDING') {
      status = OrderStatus.warning;
      statusText = 'Chờ xác nhận';
    }

    // Extract product and title
    String productName = 'Nhu yếu phẩm';
    String displayTitle = '';
    if (json['items'] is List && (json['items'] as List).isNotEmpty) {
      final first = (json['items'] as List).first;
      final qty = first['quantity'] ?? 1;
      final name = first['productNameSnapshot'] ?? first['product']?['productName'] ?? first['product']?['name'] ?? 'Sản phẩm';
      productName = name.toString();
      displayTitle = '${qty}x $name';
    } else if (json['orderItems'] is List && (json['orderItems'] as List).isNotEmpty) {
      final first = (json['orderItems'] as List).first;
      final qty = first['quantity'] ?? 1;
      final prod = first['product'];
      final name = prod != null && prod['name'] != null
          ? prod['name'].toString()
          : (first['productName']?.toString() ?? 'Sản phẩm');
      productName = name;
      displayTitle = '${qty}x $name';
    } else if (json['productName'] != null) {
      productName = json['productName'].toString();
      displayTitle = productName;
    } else if (json['product'] != null) {
      productName = json['product'].toString();
      displayTitle = productName;
    }

    if (displayTitle.isEmpty) {
      displayTitle = productName;
    }

    String timeStr = 'Vừa xong';
    if (json['createdAt'] != null) {
      final dt = DateTimeFormatter.tryParse(json['createdAt']);
      if (dt != null) {
        timeStr = DateTimeFormatter.formatOrderTime(dt);
      } else {
        timeStr = json['createdAt'].toString();
      }
    } else if (json['time'] != null) {
      timeStr = json['time'].toString();
    }

    final custName = json['customer']?['fullName'] ??
        json['customer']?['user']?['fullName'] ??
        json['customerName'] ??
        'Cư dân';

    final apt = json['deliveryAddress'] ?? json['apartment'] ?? 'Căn hộ';
    final id = json['orderId']?.toString() ?? json['orderNumber']?.toString() ?? json['id']?.toString() ?? 'SOB';
    final orderCode = json['orderCode']?.toString() ?? json['orderNumber']?.toString() ?? '#$id';
    final buttonName = json['button']?['buttonName']?.toString() ?? json['buttonName']?.toString() ?? 'Nút bấm IoT';
    final deviceId = json['button']?['deviceId']?.toString() ?? json['deviceId']?.toString() ?? '';

    final rawAmount = json['totalAmount'] ?? json['subtotalAmount'] ?? json['rawAmount'] ?? json['price'];
    final num amountNum = rawAmount is num ? rawAmount : (num.tryParse(rawAmount?.toString().replaceAll(RegExp(r'[^\d.]'), '') ?? '') ?? 0);
    final priceStr = json['priceFormatted']?.toString() ?? formatCurrency(amountNum);

    IconData icon = LucideIcons.package;
    final lowerTitle = displayTitle.toLowerCase();
    if (lowerTitle.contains('nước') || lowerTitle.contains('water') || lowerTitle.contains('lavie')) {
      icon = LucideIcons.droplets;
    } else if (lowerTitle.contains('gas') || lowerTitle.contains('petrolimex')) {
      icon = LucideIcons.flame;
    } else if (lowerTitle.contains('gạo') || lowerTitle.contains('rice') || lowerTitle.contains('st25')) {
      icon = LucideIcons.shoppingBag;
    }

    return OrderModel(
      id: id,
      orderCode: orderCode,
      customerName: custName.toString(),
      apartment: apt.toString(),
      product: productName,
      title: displayTitle,
      buttonName: buttonName,
      deviceId: deviceId,
      time: timeStr,
      price: priceStr,
      rawAmount: amountNum,
      status: status,
      rawStatus: rawStatus,
      statusText: statusText,
      icon: icon,
      rawJson: json,
    );
  }

  static List<OrderModel> get sampleOrders => const [
    OrderModel(
      id: 'SOB-20260919-001',
      orderCode: '#ORD-001',
      customerName: 'Trần Văn Minh',
      apartment: 'A1-1205',
      product: 'Bình Gas 12kg',
      title: '1x Bình Gas 12kg',
      buttonName: 'Nút Ban Công',
      deviceId: 'ESP32-A1',
      time: '21:15',
      price: '380.000đ',
      rawAmount: 380000,
      status: OrderStatus.success,
      rawStatus: 'COMPLETED',
      statusText: 'Đã giao',
      icon: LucideIcons.flame,
    ),
    OrderModel(
      id: 'SOB-20260919-002',
      orderCode: '#ORD-002',
      customerName: 'Nguyễn Thị Lan',
      apartment: 'B2-0803',
      product: 'Nước Lavie 19L',
      title: '1x Nước Lavie 19L',
      buttonName: 'Nút Bếp',
      deviceId: 'ESP32-B2',
      time: '20:48',
      price: '65.000đ',
      rawAmount: 65000,
      status: OrderStatus.info,
      rawStatus: 'SHIPPING',
      statusText: 'Đang giao',
      icon: LucideIcons.droplets,
    ),
    OrderModel(
      id: 'SOB-20260919-003',
      orderCode: '#ORD-003',
      customerName: 'Phạm Hoàng Nam',
      apartment: 'A3-1510',
      product: 'Gạo ST25 5kg',
      title: '1x Gạo ST25 5kg',
      buttonName: 'Nút Bếp',
      deviceId: 'ESP32-A3',
      time: '20:30',
      price: '165.000đ',
      rawAmount: 165000,
      status: OrderStatus.warning,
      rawStatus: 'PENDING',
      statusText: 'Chờ xử lý',
      icon: LucideIcons.shoppingBag,
    ),
    OrderModel(
      id: 'SOB-20260919-004',
      orderCode: '#ORD-004',
      customerName: 'Lê Thị Hương',
      apartment: 'C1-0402',
      product: 'Bình Gas 12kg',
      title: '1x Bình Gas 12kg',
      buttonName: 'Nút Ban Công',
      deviceId: 'ESP32-C1',
      time: '20:15',
      price: '380.000đ',
      rawAmount: 380000,
      status: OrderStatus.success,
      rawStatus: 'DELIVERED',
      statusText: 'Đã giao',
      icon: LucideIcons.flame,
    ),
    OrderModel(
      id: 'SOB-20260919-005',
      orderCode: '#ORD-005',
      customerName: 'Đỗ Minh Tuấn',
      apartment: 'B1-0906',
      product: 'Giấy vệ sinh',
      title: '1x Giấy vệ sinh',
      buttonName: 'Nút Phòng Khách',
      deviceId: 'ESP32-B1',
      time: '19:55',
      price: '85.000đ',
      rawAmount: 85000,
      status: OrderStatus.danger,
      rawStatus: 'CANCELLED',
      statusText: 'Đã hủy',
      icon: LucideIcons.package,
    ),
    OrderModel(
      id: 'SOB-20260919-006',
      orderCode: '#ORD-006',
      customerName: 'Vũ Thị Mai',
      apartment: 'A2-0704',
      product: 'Nước Lavie 19L',
      title: '1x Nước Lavie 19L',
      buttonName: 'Nút Bếp',
      deviceId: 'ESP32-A2',
      time: '19:30',
      price: '65.000đ',
      rawAmount: 65000,
      status: OrderStatus.success,
      rawStatus: 'COMPLETED',
      statusText: 'Đã giao',
      icon: LucideIcons.droplets,
    ),
    OrderModel(
      id: 'SOB-20260919-007',
      orderCode: '#ORD-007',
      customerName: 'Hoàng Đức Long',
      apartment: 'C2-1101',
      product: 'Gạo ST25 5kg',
      title: '1x Gạo ST25 5kg',
      buttonName: 'Nút Bếp',
      deviceId: 'ESP32-C2',
      time: '19:12',
      price: '165.000đ',
      rawAmount: 165000,
      status: OrderStatus.info,
      rawStatus: 'SHIPPING',
      statusText: 'Đang giao',
      icon: LucideIcons.shoppingBag,
    ),
    OrderModel(
      id: 'SOB-20260919-008',
      orderCode: '#ORD-008',
      customerName: 'Bùi Thị Ngọc',
      apartment: 'A1-0308',
      product: 'Bình Gas 12kg',
      title: '1x Bình Gas 12kg',
      buttonName: 'Nút Ban Công',
      deviceId: 'ESP32-A1',
      time: '18:50',
      price: '380.000đ',
      rawAmount: 380000,
      status: OrderStatus.success,
      rawStatus: 'COMPLETED',
      statusText: 'Đã giao',
      icon: LucideIcons.flame,
    ),
    OrderModel(
      id: 'SOB-20260919-009',
      orderCode: '#ORD-009',
      customerName: 'Trịnh Văn Khoa',
      apartment: 'B3-1407',
      product: 'Nước Lavie 19L',
      title: '1x Nước Lavie 19L',
      buttonName: 'Nút Bếp',
      deviceId: 'ESP32-B3',
      time: '18:20',
      price: '65.000đ',
      rawAmount: 65000,
      status: OrderStatus.warning,
      rawStatus: 'PENDING',
      statusText: 'Chờ xử lý',
      icon: LucideIcons.droplets,
    ),
    OrderModel(
      id: 'SOB-20260919-010',
      orderCode: '#ORD-010',
      customerName: 'Ngô Thị Thảo',
      apartment: 'A3-0512',
      product: 'Giấy vệ sinh',
      title: '1x Giấy vệ sinh',
      buttonName: 'Nút Phòng Khách',
      deviceId: 'ESP32-A3',
      time: '17:45',
      price: '85.000đ',
      rawAmount: 85000,
      status: OrderStatus.success,
      rawStatus: 'DELIVERED',
      statusText: 'Đã giao',
      icon: LucideIcons.package,
    ),
  ];
}
