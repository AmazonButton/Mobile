import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../utils/formatters.dart';

enum OrderStatus { success, info, warning, danger }

class OrderItemInfo {
  final String name;
  final int quantity;
  final String price;
  final String? imageUrl;

  const OrderItemInfo({
    required this.name,
    this.quantity = 1,
    this.price = '',
    this.imageUrl,
  });
}

class OrderModel {
  final String id;
  final String orderCode;
  final String customerName;
  final String apartment;
  final String product;
  final String title;
  final String buttonName;
  final String storeName;
  final String deviceId;
  final String time;
  final DateTime? createdAt;
  final String price;
  final num rawAmount;
  final OrderStatus status;
  final String rawStatus;
  final String statusText;
  final String paymentStatus;
  final String paymentMethod;
  final IconData icon;
  final Map<String, dynamic>? rawJson;
  final List<OrderItemInfo> items;

  const OrderModel({
    required this.id,
    this.orderCode = '#ORD',
    required this.customerName,
    required this.apartment,
    required this.product,
    this.title = '',
    this.buttonName = 'Nút bấm IoT',
    this.storeName = '',
    this.deviceId = '',
    required this.time,
    this.createdAt,
    this.price = '0đ',
    this.rawAmount = 0,
    required this.status,
    this.rawStatus = 'PENDING',
    required this.statusText,
    this.paymentStatus = 'UNPAID',
    this.paymentMethod = 'COD',
    this.icon = LucideIcons.package,
    this.rawJson,
    this.items = const [],
  });

  String get displayTitle => title.isNotEmpty ? title : product;

  bool get isPending => rawStatus == 'PENDING';
  bool get isShipping => rawStatus == 'SHIPPING';
  bool get isCompleted => rawStatus == 'COMPLETED' || rawStatus == 'DELIVERED';
  bool get isCancelled => rawStatus == 'CANCELLED';

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';
  bool get isUnpaid => paymentStatus.toUpperCase() == 'UNPAID';
  bool get isPayos => paymentMethod.toUpperCase() == 'PAYOS';

  /// Số giây còn lại trong cửa sổ an toàn 60 giây
  int get remainingSafetySeconds {
    if (!isPending) return 0;
    if (createdAt == null) return 60;
    final elapsed = DateTime.now().difference(createdAt!).inSeconds;
    final remain = 60 - elapsed;
    return remain > 0 ? remain : 0;
  }

  /// Kiểm tra xem đơn hàng còn trong cửa sổ hủy khẩn cấp 60 giây hay không
  bool get isWithinSafetyWindow {
    if (!isPending) return false;
    if (createdAt == null) return true;
    return remainingSafetySeconds > 0;
  }

  bool get isEmergencyCancellable => isWithinSafetyWindow;

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

  static String? _productImage(Map item) {
    String? url(dynamic value) {
      if (value is! String) return null;
      final text = value.trim();
      final uri = Uri.tryParse(text);
      return uri != null &&
              (uri.scheme == 'https' || uri.scheme == 'http') &&
              uri.host.isNotEmpty
          ? text
          : null;
    }

    String? fromMap(Map source) {
      final direct = url(source['imageUrl']) ?? url(source['thumbnailUrl']);
      if (direct != null) return direct;
      final images = source['images'];
      if (images is List) {
        final ordered = [...images];
        ordered.sort((a, b) =>
            (b is Map && (b['isPrimary'] == true || b['isThumbnail'] == true) ? 1 : 0) -
            (a is Map && (a['isPrimary'] == true || a['isThumbnail'] == true) ? 1 : 0));
        for (final image in ordered) {
          final result = url(image is Map ? image['imageUrl'] : image);
          if (result != null) return result;
        }
      }
      return null;
    }

    return fromMap(item) ??
        (item['product'] is Map ? fromMap(item['product'] as Map) : null);
  }

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

    // Extract product and items list with robust fallback
    final rawItems = json['items'] ?? json['orderItems'];
    final List<OrderItemInfo> parsedItems = [];
    String productName = 'Nhu yếu phẩm';
    String displayTitle = '';

    if (rawItems is List && rawItems.isNotEmpty) {
      for (final item in rawItems) {
        if (item is Map) {
          final qty = item['quantity'] is num
              ? (item['quantity'] as num).toInt()
              : (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1);
          final name = item['productName'] ??
              item['productNameSnapshot'] ??
              item['product']?['productName'] ??
              item['product']?['name'] ??
              item['name'] ??
              'Sản phẩm';
          final pStr = item['unitPrice']?.toString() ?? item['finalUnitPrice']?.toString() ?? '';
          final img = _productImage(item);

          parsedItems.add(OrderItemInfo(
            name: name.toString(),
            quantity: qty,
            price: pStr,
            imageUrl: img,
          ));
        }
      }

      if (parsedItems.isNotEmpty) {
        final first = parsedItems.first;
        productName = first.name;
        if (parsedItems.length == 1) {
          displayTitle = '${first.quantity}x ${first.name}';
        } else {
          displayTitle = '${first.quantity}x ${first.name} (+${parsedItems.length - 1} món khác)';
        }
      }
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

    DateTime? parsedCreatedAt;
    String timeStr = 'Vừa xong';
    if (json['createdAt'] != null) {
      final dt = DateTimeFormatter.tryParse(json['createdAt']);
      if (dt != null) {
        parsedCreatedAt = dt;
        timeStr = DateTimeFormatter.formatOrderTime(dt);
      } else {
        timeStr = json['createdAt'].toString();
      }
    } else if (json['orderDate'] != null) {
      final dt = DateTimeFormatter.tryParse(json['orderDate']);
      if (dt != null) {
        parsedCreatedAt = dt;
        timeStr = DateTimeFormatter.formatOrderTime(dt);
      } else {
        timeStr = json['orderDate'].toString();
      }
    } else if (json['time'] != null) {
      timeStr = json['time'].toString();
    }

    final custName = json['customer']?['fullName'] ??
        json['customer']?['user']?['fullName'] ??
        json['customerName'] ??
        'Cư dân';

    final apt = json['deliveryAddress'] ?? json['apartment'] ?? 'Căn hộ';
    final id = json['orderId']?.toString() ?? json['id']?.toString() ?? json['orderNumber']?.toString() ?? 'SOB';
    final orderCode = json['orderCode']?.toString() ?? json['orderNumber']?.toString() ?? '#$id';

    // Robust Button Name extraction
    String buttonName = 'Nút bấm IoT';
    final buttonObj = json['button'];
    if (buttonObj is Map) {
      buttonName = buttonObj['buttonName']?.toString() ??
          buttonObj['name']?.toString() ??
          buttonObj['buttonCode']?.toString() ??
          'Nút bấm IoT';
    } else if (json['buttonName'] != null && json['buttonName'].toString().isNotEmpty) {
      buttonName = json['buttonName'].toString();
    }

    // Robust Store Name extraction
    String storeName = '';
    final storeObj = json['store'];
    if (storeObj is Map) {
      storeName = storeObj['name']?.toString() ?? storeObj['storeName']?.toString() ?? '';
    } else if (json['storeName'] != null && json['storeName'].toString().isNotEmpty) {
      storeName = json['storeName'].toString();
    }

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

    final paymentStatus = (json['paymentStatus'] ?? 'UNPAID').toString().toUpperCase();
    final paymentMethod = (json['paymentMethod'] ?? 'COD').toString().toUpperCase();

    return OrderModel(
      id: id,
      orderCode: orderCode,
      customerName: custName.toString(),
      apartment: apt.toString(),
      product: productName,
      title: displayTitle,
      buttonName: buttonName,
      storeName: storeName,
      deviceId: deviceId,
      time: timeStr,
      createdAt: parsedCreatedAt,
      price: priceStr,
      rawAmount: amountNum,
      status: status,
      rawStatus: rawStatus,
      statusText: statusText,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      icon: icon,
      rawJson: json,
      items: parsedItems,
    );
  }

  OrderModel copyWith({
    String? id,
    String? orderCode,
    String? customerName,
    String? apartment,
    String? product,
    String? title,
    String? buttonName,
    String? storeName,
    String? deviceId,
    String? time,
    DateTime? createdAt,
    String? price,
    num? rawAmount,
    OrderStatus? status,
    String? rawStatus,
    String? statusText,
    String? paymentStatus,
    String? paymentMethod,
    IconData? icon,
    Map<String, dynamic>? rawJson,
    List<OrderItemInfo>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      customerName: customerName ?? this.customerName,
      apartment: apartment ?? this.apartment,
      product: product ?? this.product,
      title: title ?? this.title,
      buttonName: buttonName ?? this.buttonName,
      storeName: storeName ?? this.storeName,
      deviceId: deviceId ?? this.deviceId,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      price: price ?? this.price,
      rawAmount: rawAmount ?? this.rawAmount,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      statusText: statusText ?? this.statusText,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      icon: icon ?? this.icon,
      rawJson: rawJson ?? this.rawJson,
      items: items ?? this.items,
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
