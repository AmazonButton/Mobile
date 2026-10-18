import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/orders_api_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrdersApiService _apiService;

  List<OrderModel> _orders;
  bool _isLoading = false;
  String? _errorMessage;

  OrderProvider({OrdersApiService? apiService, List<OrderModel>? initialOrders})
      : _apiService = apiService ?? OrdersApiService(),
        _orders = initialOrders ?? List.from(OrderModel.sampleOrders);

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<OrderModel> get activeOrders {
    return _orders
        .where((o) =>
            o.isPending ||
            o.isShipping ||
            o.rawStatus == 'PENDING' ||
            o.rawStatus == 'CONFIRMED' ||
            o.rawStatus == 'PROCESSING' ||
            o.rawStatus == 'SHIPPING')
        .toList();
  }

  List<OrderModel> get historyOrders {
    return _orders
        .where((o) =>
            o.isCompleted ||
            o.isCancelled ||
            (!o.isPending &&
                !o.isShipping &&
                o.rawStatus != 'PENDING' &&
                o.rawStatus != 'CONFIRMED' &&
                o.rawStatus != 'PROCESSING' &&
                o.rawStatus != 'SHIPPING'))
        .toList();
  }

  num get totalSpend {
    return historyOrders
        .where((o) => !o.isCancelled)
        .fold<num>(0, (sum, o) => sum + o.rawAmount);
  }

  /// Tải danh sách đơn hàng từ backend
  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _apiService.getOrders();
      _orders = fetched;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Hủy đơn hàng và cập nhật trạng thái ngay lập tức
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _apiService.cancelOrder(orderId, reason: reason ?? 'Hủy đơn từ ứng dụng');
    } catch (_) {
      // Optimistic update
    }
    
    // Cập nhật trạng thái trong bộ nhớ
    final index = _orders.indexWhere((o) => o.id == orderId || o.orderCode == orderId);
    if (index != -1) {
      final current = _orders[index];
      _orders[index] = OrderModel(
        id: current.id,
        orderCode: current.orderCode,
        customerName: current.customerName,
        apartment: current.apartment,
        product: current.product,
        title: current.title,
        buttonName: current.buttonName,
        deviceId: current.deviceId,
        time: current.time,
        price: current.price,
        rawAmount: current.rawAmount,
        status: OrderStatus.danger,
        rawStatus: 'CANCELLED',
        statusText: 'Đã hủy',
        icon: current.icon,
      );
      notifyListeners();
    }
  }

  /// Đặt lại đơn hàng siêu tốc qua deviceId
  Future<void> quickReorder(String deviceId) async {
    try {
      await _apiService.quickReorder(deviceId: deviceId);
      await loadOrders();
    } catch (_) {}
  }

  /// Làm mới danh sách đơn hàng
  Future<void> refreshOrders() => loadOrders();
}
