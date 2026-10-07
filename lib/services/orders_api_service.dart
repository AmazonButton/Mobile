import 'api_client.dart';
import 'api_config.dart';

class OrdersApiService {
  static final OrdersApiService _instance = OrdersApiService._internal();
  factory OrdersApiService() => _instance;
  OrdersApiService._internal();

  final ApiClient _client = ApiClient();

  /// Lấy danh sách lịch sử đơn hàng của người dùng
  Future<List<dynamic>> getOrders({String? status}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await _client.get(ApiConfig.orders, queryParams: query);
    final data = response['data'] ?? response;
    if (data is List) {
      return data;
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
    final response = await _client.post(
      ApiConfig.ordersQuickReorder,
      body: {'deviceId': deviceId.trim()},
    );
    return response;
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
