import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum OrderStatus { success, info, warning, danger }

class OrderModel {
  final String id;
  final String customerName;
  final String apartment;
  final String product;
  final String time;
  final OrderStatus status;
  final String statusText;

  const OrderModel({
    required this.id,
    required this.customerName,
    required this.apartment,
    required this.product,
    required this.time,
    required this.status,
    required this.statusText,
  });

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

  static List<OrderModel> get sampleOrders => const [
    OrderModel(
      id: 'SOB-20260919-001',
      customerName: 'Trần Văn Minh',
      apartment: 'A1-1205',
      product: 'Bình Gas 12kg',
      time: '21:15',
      status: OrderStatus.success,
      statusText: 'Đã giao',
    ),
    OrderModel(
      id: 'SOB-20260919-002',
      customerName: 'Nguyễn Thị Lan',
      apartment: 'B2-0803',
      product: 'Nước Lavie 19L',
      time: '20:48',
      status: OrderStatus.info,
      statusText: 'Đang giao',
    ),
    OrderModel(
      id: 'SOB-20260919-003',
      customerName: 'Phạm Hoàng Nam',
      apartment: 'A3-1510',
      product: 'Gạo ST25 5kg',
      time: '20:30',
      status: OrderStatus.warning,
      statusText: 'Chờ xử lý',
    ),
    OrderModel(
      id: 'SOB-20260919-004',
      customerName: 'Lê Thị Hương',
      apartment: 'C1-0402',
      product: 'Bình Gas 12kg',
      time: '20:15',
      status: OrderStatus.success,
      statusText: 'Đã giao',
    ),
    OrderModel(
      id: 'SOB-20260919-005',
      customerName: 'Đỗ Minh Tuấn',
      apartment: 'B1-0906',
      product: 'Giấy vệ sinh',
      time: '19:55',
      status: OrderStatus.danger,
      statusText: 'Đã hủy',
    ),
    OrderModel(
      id: 'SOB-20260919-006',
      customerName: 'Vũ Thị Mai',
      apartment: 'A2-0704',
      product: 'Nước Lavie 19L',
      time: '19:30',
      status: OrderStatus.success,
      statusText: 'Đã giao',
    ),
    OrderModel(
      id: 'SOB-20260919-007',
      customerName: 'Hoàng Đức Long',
      apartment: 'C2-1101',
      product: 'Gạo ST25 5kg',
      time: '19:12',
      status: OrderStatus.info,
      statusText: 'Đang giao',
    ),
    OrderModel(
      id: 'SOB-20260919-008',
      customerName: 'Bùi Thị Ngọc',
      apartment: 'A1-0308',
      product: 'Bình Gas 12kg',
      time: '18:50',
      status: OrderStatus.success,
      statusText: 'Đã giao',
    ),
    OrderModel(
      id: 'SOB-20260919-009',
      customerName: 'Trịnh Văn Khoa',
      apartment: 'B3-1407',
      product: 'Nước Lavie 19L',
      time: '18:20',
      status: OrderStatus.warning,
      statusText: 'Chờ xử lý',
    ),
    OrderModel(
      id: 'SOB-20260919-010',
      customerName: 'Ngô Thị Thảo',
      apartment: 'A3-0512',
      product: 'Giấy vệ sinh',
      time: '17:45',
      status: OrderStatus.success,
      statusText: 'Đã giao',
    ),
  ];
}
