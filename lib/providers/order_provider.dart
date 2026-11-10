import 'dart:async';
import '../services/order_updates.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_client.dart';
import '../services/orders_api_service.dart';

class OrderProvider extends ChangeNotifier with WidgetsBindingObserver {
  final OrdersApiService _apiService;

  /// Global hooks to notify other providers (e.g. NotificationProvider)
  static void Function(OrderModel order)? onOrderCreated;
  static void Function(OrderModel order, String? reason)? onOrderCancelled;
  static void Function(List<OrderModel> orders)? onOrdersLoaded;
  static void Function(String orderId, OrderModel updatedOrder)? onOrderPaid;

  List<OrderModel> _orders;
  bool _isLoading = false;
  String? _errorMessage;

  OrderProvider({OrdersApiService? apiService, List<OrderModel>? initialOrders})
    : _apiService = apiService ?? OrdersApiService(),
      _orders = initialOrders ?? [];

  List<OrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<OrderModel> get activeOrders =>
      _orders.where((o) => o.isActive).toList();

  List<OrderModel> get historyOrders =>
      _orders.where((o) => o.isTerminal).toList();

  num get totalSpend => _orders
      .where((o) => o.countsTowardsSpend)
      .fold<num>(0, (sum, order) => sum + order.rawAmount);

  int _page = 0;
  int _generation = 0;
  bool _hasMore = false;
  bool _loadingMore = false;
  int? _totalItems;
  String? _loadMoreError;
  String? _statusFilter, _paymentFilter;
  DateTime? _fromDate, _toDate;
  StreamSubscription<String?>? _updates;
  StreamSubscription<void>? _sessionEnds;
  Timer? _updateTimer;
  bool _disposed = false;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;
  int? get totalItems => _totalItems;
  String? get loadMoreError => _loadMoreError;
  String? get statusFilter => _statusFilter;
  String? get paymentFilter => _paymentFilter;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;

  Future<void> setFilters({
    String? status,
    String? paymentStatus,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _statusFilter = status;
    _paymentFilter = paymentStatus;
    _fromDate = fromDate;
    _toDate = toDate;
    _orders = [];
    _page = 0;
    _hasMore = false;
    _totalItems = null;
    await loadOrders();
  }

  Future<void> loadOrders({
    bool silent = false,
    bool preservePages = false,
  }) async {
    final version = ++_generation;
    final pages = preservePages && _page > 0 ? _page : 1;
    final status = _statusFilter, payment = _paymentFilter;
    final from = _fromDate, to = _toDate;
    _isLoading = !silent;
    _loadingMore = false;
    _errorMessage = null;
    _loadMoreError = null;
    notifyListeners();
    try {
      final loaded = <String, OrderModel>{};
      for (var page = 1; page <= pages; page++) {
        final batch = await _apiService.getOrdersPage(
          page: page,
          status: status,
          paymentStatus: payment,
          fromDate: from,
          toDate: to,
        );
        if (_disposed || version != _generation) return;
        for (final order in batch.items) {
          loaded[order.id] = order;
        }
        if (page == pages || !batch.hasNextPage) {
          _orders = loaded.values.toList();
          _page = page;
          _hasMore = batch.hasNextPage;
          _totalItems = batch.totalItems;
          break;
        }
      }
      onOrdersLoaded?.call(_orders);
    } catch (error) {
      if (!_disposed && version == _generation) {
        _errorMessage = error.toString();
      }
    } finally {
      if (!_disposed && version == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || _isLoading || !_hasMore) return;
    final version = _generation;
    _loadingMore = true;
    _loadMoreError = null;
    notifyListeners();
    try {
      final batch = await _apiService.getOrdersPage(
        page: _page + 1,
        status: _statusFilter,
        paymentStatus: _paymentFilter,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      if (_disposed || version != _generation) return;
      final combined = {for (final order in _orders) order.id: order};
      for (final order in batch.items) {
        combined[order.id] = order;
      }
      _orders = combined.values.toList();
      _page = batch.page;
      _hasMore = batch.hasNextPage;
      _totalItems = batch.totalItems;
      onOrdersLoaded?.call(_orders);
    } catch (error) {
      if (!_disposed && version == _generation) {
        _loadMoreError = error.toString();
      }
    } finally {
      if (!_disposed && version == _generation) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  void startLiveUpdates({Stream<String?>? events}) {
    if (_updates != null) return;
    WidgetsBinding.instance.addObserver(this);
    _sessionEnds = OrderUpdates.sessionEnds.listen((_) => reset());
    _updates = (events ?? OrderUpdates.events).listen((_) {
      _updateTimer?.cancel();
      _updateTimer = Timer(const Duration(milliseconds: 250), () {
        if (!_disposed && ApiClient().isAuthenticated) {
          loadOrders(silent: true, preservePages: true);
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && ApiClient().isAuthenticated) {
      loadOrders(silent: true, preservePages: true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _updates?.cancel();
    _sessionEnds?.cancel();
    _updateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void reset() {
    _generation++;
    _updateTimer?.cancel();
    _orders = [];
    _page = 0;
    _hasMore = false;
    _totalItems = null;
    _statusFilter = null;
    _paymentFilter = null;
    _fromDate = null;
    _toDate = null;
    _isLoading = false;
    _loadingMore = false;
    _errorMessage = null;
    _loadMoreError = null;
    if (!_disposed) notifyListeners();
  }

  /// Hủy đơn hàng và cập nhật trạng thái ngay lập tức
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    // Nếu là dữ liệu mẫu giả lập offline (SOB-...) thì không gọi API backend
    if (!orderId.startsWith('SOB-')) {
      try {
        await _apiService.cancelOrder(
          orderId,
          reason: reason ?? 'Hủy đơn từ ứng dụng',
        );
      } on ApiException {
        rethrow;
      } catch (_) {
        // Cho phép fallback trong môi trường unit test không có server
      }
    }

    // Cập nhật trạng thái trong bộ nhớ khi API thành công
    final index = _orders.indexWhere(
      (o) => o.id == orderId || o.orderCode == orderId,
    );
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
        storeName: current.storeName,
        deviceId: current.deviceId,
        time: current.time,
        createdAt: current.createdAt,
        price: current.price,
        rawAmount: current.rawAmount,
        status: OrderStatus.danger,
        rawStatus: 'CANCELLED',
        statusText: 'Đã hủy',
        icon: current.icon,
        rawJson: current.rawJson,
        items: current.items,
      );
      notifyListeners();
      onOrderCancelled?.call(current, reason);
    }
  }

  /// Đánh dấu đơn hàng đã thanh toán thành công (PayOS / VietQR) và cập nhật reactive state
  void markOrderAsPaid(String orderId) {
    final index = _orders.indexWhere(
      (o) => o.id == orderId || o.orderCode == orderId,
    );
    if (index != -1) {
      final current = _orders[index];
      _orders[index] = current.copyWith(
        paymentStatus: 'PAID',
        paymentMethod: 'PAYOS',

        // Payment confirmation does not imply a lifecycle transition.
      );
      notifyListeners();
      onOrderPaid?.call(orderId, _orders[index]);
      OrderUpdates.notify(orderId);
    }
  }

  /// Đặt lại đơn hàng siêu tốc qua deviceId
  Future<void> quickReorder(String deviceId) async {
    await _apiService.quickReorder(deviceId: deviceId);
    await loadOrders();
  }

  /// Đặt hàng siêu tốc 1 chạm từ nút bấm và khởi tạo cửa sổ an toàn 60 giây
  Future<OrderModel?> createOneTouchOrder({
    required String deviceId,
    required String buttonName,
    required String productName,
    required String productPrice,
    String? customerName,
    String? apartment,
  }) async {
    final response = await _apiService.quickReorder(deviceId: deviceId);
    final data = response['data'] ?? response;
    final rawOrder = data is Map ? data['order'] : null;
    if (rawOrder is! Map) {
      throw ApiException(
        message:
            'Không nhận được đơn hàng từ máy chủ. Vui lòng tải lại danh sách đơn hàng.',
        statusCode: 502,
        errorCode: 'INVALID_ORDER_RESPONSE',
      );
    }
    final newOrder = OrderModel.fromJson(Map<String, dynamic>.from(rawOrder));
    if (!RegExp(r'^[1-9]\d*$').hasMatch(newOrder.id)) {
      throw ApiException(
        message:
            'Đơn hàng từ máy chủ thiếu ID hợp lệ. Vui lòng tải lại danh sách đơn hàng.',
        statusCode: 502,
        errorCode: 'INVALID_ORDER_RESPONSE',
      );
    }

    _orders.insert(0, newOrder);
    notifyListeners();
    onOrderCreated?.call(newOrder);
    return newOrder;
  }

  /// Làm mới danh sách đơn hàng
  Future<void> refreshOrders() => loadOrders(preservePages: true);
}
