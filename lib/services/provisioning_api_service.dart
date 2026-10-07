import 'api_client.dart';
import 'api_config.dart';

class ProvisioningApiService {
  static final ProvisioningApiService _instance = ProvisioningApiService._internal();
  factory ProvisioningApiService() => _instance;
  ProvisioningApiService._internal();

  final ApiClient _client = ApiClient();

  /// Khởi tạo phiên cấu hình thiết bị phần cứng
  Future<Map<String, dynamic>> createSession() async {
    final response = await _client.post(ApiConfig.provisioningSession);
    return response['data'] ?? response;
  }

  /// Xác thực nút bấm đã gia nhập mạng Wi-Fi thành công
  Future<Map<String, dynamic>> verifySession({
    required String sessionId,
    required String deviceId,
    String? buttonCode,
  }) async {
    final body = <String, dynamic>{
      'sessionId': sessionId,
      'deviceId': deviceId,
    };
    if (buttonCode != null && buttonCode.isNotEmpty) {
      body['buttonCode'] = buttonCode;
    }

    final response = await _client.post(
      ApiConfig.provisioningVerify,
      body: body,
    );
    return response['data'] ?? response;
  }

  /// Đổi cấu hình Wi-Fi cho nút bấm
  Future<Map<String, dynamic>> changeWifi({
    required String deviceId,
    required String ssid,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConfig.provisioningChangeWifi(deviceId),
      body: {
        'ssid': ssid,
        'password': password,
      },
    );
    return response;
  }
}
