import 'stock_service.dart';
import '../models/order_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class OrdersApiService {
  static final OrdersApiService _instance = OrdersApiService._internal();
  factory OrdersApiService() => _instance;
  OrdersApiService._internal();

  final ApiClient _client = ApiClient();
  final Set<String> _ordering = {};

  /// Lấy danh sách lịch sử đơn hàng của người dùng được ánh xạ thành strongly-typed OrderModel
  Future<List<OrderModel>> getOrders({String? status}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await _client.get(ApiConfig.orders, queryParams: query);
    final data = response['data'] ?? response;
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return OrderModel.fromJson(item);
        } else if (item is Map) {
          return OrderModel.fromJson(Map<String, dynamic>.from(item));
        }
        return OrderModel.fromJson({});
      }).toList();
    }
    return [];
  }

  /// Lấy thông tin chi tiết một đơn hàng theo ID
  Future<Map<String, dynamic>> getOrderById(String id) async {
    final response = await _client.get(ApiConfig.orderDetail(id));
    return response['data'] ?? response;
  }

  /// Đặt hàng siêu tốc 1 chạm bằng deviceId của nút bấm IoT
  Future<Map<String, dynamic>> quickReorder({required String deviceId}) async {
    final id = deviceId.trim();
    if (!_ordering.add(id)) {
      throw ApiException(message: 'Đang xử lý đặt hàng', statusCode: 409);
    }
    try {
      await StockService.instance.verify(id);
      final response = await _client.post(
        ApiConfig.ordersQuickReorder,
        body: {'deviceId': id},
      );
      await StockService.instance.refreshDevice(id);
      return response;
    } catch (error) {
      await StockService.instance.refreshDevice(id);
      if (error is ApiException &&
          error.errorCode != 'MOBILE_STOCK_UNAVAILABLE' &&
          (error.message.contains('P0007') ||
              error.message.toLowerCase().contains('không đủ tồn kho'))) {
        throw ApiException(
          message:
              'Sản phẩm vừa hết hoặc không đủ số lượng. Vui lòng kiểm tra lại tồn kho.',
          statusCode: error.statusCode,
          errorCode: 'MOBILE_STOCK_UNAVAILABLE',
        );
      }
      rethrow;
    } finally {
      _ordering.remove(id);
    }
  }

  /// Hủy đơn hàng với lý do cụ thể
  Future<Map<String, dynamic>> cancelOrder(String id, {String? reason}) async {
    final response = await _client.post(
      ApiConfig.orderCancel(id),
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return response;
  }

  /// Giả lập sự kiện nút bấm vật lý tạo đơn hàng
  Future<Map<String, dynamic>> simulateButtonPress({
    required String deviceId,
    String eventType = 'SINGLE_PRESS',
  }) async {
    final response = await _client.post(
      ApiConfig.ordersSimulatePress,
      body: {'deviceId': deviceId, 'eventType': eventType},
    );
    return response;
  }
}
