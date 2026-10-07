import 'api_client.dart';
import 'api_config.dart';

class DevicesApiService {
  static final DevicesApiService _instance = DevicesApiService._internal();
  factory DevicesApiService() => _instance;
  DevicesApiService._internal();

  final ApiClient _client = ApiClient();

  /// Lấy danh sách tất cả các nút bấm IoT của người dùng / cửa hàng
  Future<List<dynamic>> getDevices({String? status, String? search}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final response = await _client.get(ApiConfig.devices, queryParams: query);
    final data = response['data'] ?? response;
    if (data is List) {
      return data;
    }
    return [];
  }

  /// Lấy thông tin chi tiết một nút bấm
  Future<Map<String, dynamic>> getDeviceById(String id) async {
    final response = await _client.get(ApiConfig.deviceDetail(id));
    return response['data'] ?? response;
  }

  /// Tra cứu thiết bị theo mã PIN 6 số hoặc payload QR
  Future<Map<String, dynamic>> lookupCode(String code) async {
    final response = await _client.post(
      ApiConfig.devicesLookupCode,
      body: {'code': code.trim()},
    );
    return response['data'] ?? response;
  }

  /// Cấu hình và kích hoạt nút trực tiếp qua mã code / QR
  Future<Map<String, dynamic>> configureByCode(Map<String, dynamic> payload) async {
    final response = await _client.post(
      ApiConfig.devicesConfigureByCode,
      body: payload,
    );
    return response['data'] ?? response;
  }

  /// Khách hàng cập nhật cấu hình nút (tên phòng, đổi sản phẩm gán, số lượng đặt, trạng thái)
  Future<Map<String, dynamic>> updateCustomerConfig(
    String id, {
    String? buttonName,
    String? productId,
    int? defaultQuantity,
    bool? isActive,
    String? roomLocation,
  }) async {
    final body = <String, dynamic>{};
    if (buttonName != null) body['buttonName'] = buttonName;
    if (productId != null) body['productId'] = productId;
    if (defaultQuantity != null) body['defaultQuantity'] = defaultQuantity;
    if (isActive != null) body['isActive'] = isActive;
    if (roomLocation != null) body['roomLocation'] = roomLocation;


    final response = await _client.put(
      ApiConfig.deviceCustomerConfig(id),
      body: body,
    );
    return response['data'] ?? response;
  }

  /// Bật / Tắt trạng thái hoạt động của nút bấm
  Future<Map<String, dynamic>> toggleActive(String id, String status) async {
    final response = await _client.patch(
      ApiConfig.deviceToggleActive(id),
      body: {'status': status},
    );
    return response['data'] ?? response;
  }

  /// Giả lập nhấn nút từ app để kích hoạt tạo đơn hàng tự động
  Future<Map<String, dynamic>> simulatePress(String id, {String eventType = 'SINGLE_PRESS'}) async {
    final response = await _client.post(
      ApiConfig.deviceSimulatePress(id),
      body: {'eventType': eventType},
    );
    return response;
  }

  /// Lấy số liệu đo kiểm tín hiệu thiết bị (Pin, Wi-Fi RSSI)
  Future<Map<String, dynamic>> getTelemetry(String id) async {
    final response = await _client.get(ApiConfig.deviceTelemetry(id));
    return response['data'] ?? response;
  }

  /// Gán sản phẩm của cửa hàng vào nút bấm
  Future<Map<String, dynamic>> assignProduct(
    String deviceId, {
    required String productId,
    int quantity = 1,
  }) async {
    final response = await _client.post(
      ApiConfig.deviceAssignProduct(deviceId),
      body: {'productId': productId, 'quantity': quantity},
    );
    return response['data'] ?? response;
  }

  /// Xóa liên kết sản phẩm khỏi nút bấm
  Future<void> removeProduct(String deviceId) async {
    await _client.delete(ApiConfig.deviceRemoveProduct(deviceId));
  }
}
