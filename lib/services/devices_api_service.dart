import 'paged_list_service.dart';
import '../models/device_model.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'products_api_service.dart';
import 'customer_buttons_api_service.dart';
import '../models/customer_button_contract.dart';

class DevicesApiService {
  static final DevicesApiService _instance = DevicesApiService._internal();
  factory DevicesApiService() => _instance;
  DevicesApiService._internal();

  final ApiClient _client = ApiClient();

  Future<Map<String, CustomerButtonContract>> _usageByButton() async {
    try {
      final contracts = await CustomerButtonsApiService().getMyButtons();
      return {
        for (final contract in contracts)
          for (final button in contract.buttons) button.id: contract,
      };
    } catch (_) {
      // Older servers and non-customer accounts may not expose custody data.
      // The order endpoint remains authoritative when this lookup is unavailable.
      return {};
    }
  }

  Map<String, dynamic> _withUsage(
    Map<String, dynamic> data,
    Map<String, CustomerButtonContract> usage,
  ) {
    final contract =
        usage[data['buttonId']?.toString() ?? data['id']?.toString()];
    if (contract == null) return data;
    return {
      ...data,
      'rentalId': contract.id,
      'rentalStatus': contract.status,
      if (data['canOrder'] is! bool && contract.canOrder != null)
        'canOrder': contract.canOrder,
    };
  }

  /// Lấy danh sách tất cả các nút bấm IoT của người dùng được ánh xạ thành DeviceModel
  Future<List<DeviceModel>> getDevices({String? status, String? search}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final data = await getAllApiPages(ApiConfig.devices, query: query);
    {
      final usage = data.any((item) => item['buttonId'] != null)
          ? await _usageByButton()
          : <String, CustomerButtonContract>{};
      final devices = data
          .map((item) => DeviceModel.fromJson(_withUsage(item, usage)))
          .toList();
      if (!devices.any((device) => device.imageUrl == null)) return devices;
      try {
        final products = await ProductsApiService().getProducts();
        final byId = <String, Map>{
          for (final product in products)
            if (product is Map &&
                (product['productId'] ?? product['id']) != null)
              (product['productId'] ?? product['id']).toString(): product,
        };
        return devices.map((device) {
          final product = byId[device.productId];
          if (device.imageUrl != null || product == null) return device;
          final enriched = DeviceModel.fromJson({
            'products': [
              {'product': product},
            ],
          });
          return device.copyWith(imageUrl: enriched.imageUrl);
        }).toList();
      } catch (_) {
        return devices;
      }
    }
  }

  /// Lấy thông tin chi tiết một nút bấm dạng strongly-typed DeviceModel
  Future<DeviceModel> getDeviceModelById(String id) async {
    final data = await getDeviceById(id);
    return DeviceModel.fromJson(data);
  }

  /// Lấy thông tin chi tiết một nút bấm
  Future<Map<String, dynamic>> getDeviceById(String id) async {
    final response = await _client.get(ApiConfig.deviceDetail(id));
    final data = Map<String, dynamic>.from(response['data'] ?? response);
    if (data['buttonId'] == null) return data;
    return _withUsage(data, await _usageByButton());
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
  Future<Map<String, dynamic>> configureByCode(
    Map<String, dynamic> payload,
  ) async {
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
    String? storeId,
    int? defaultQuantity,
    int? quantity,
    bool? isActive,
    String? roomLocation,
  }) async {
    final body = <String, dynamic>{};
    if (buttonName != null) body['buttonName'] = buttonName;
    if (productId != null) body['productId'] = productId;
    if (storeId != null) body['storeId'] = storeId;
    if (quantity != null || defaultQuantity != null) {
      body['quantity'] = quantity ?? defaultQuantity;
    }
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
  Future<Map<String, dynamic>> simulatePress(
    String id, {
    String eventType = 'SINGLE_PRESS',
  }) async {
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
