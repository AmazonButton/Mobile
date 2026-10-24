import '../models/payos_payment_data.dart';
import 'api_client.dart';
import 'api_config.dart';

class PaymentsApiService {
  static final PaymentsApiService _instance = PaymentsApiService._internal();
  factory PaymentsApiService() => _instance;
  PaymentsApiService._internal();

  final ApiClient _client = ApiClient();

  /// Tạo liên kết thanh toán PayOS và dữ liệu VietQR cho một đơn hàng
  Future<PayosPaymentData> createPayosPaymentLink({
    required String orderId,
    String? description,
    String? returnUrl,
    String? cancelUrl,
  }) async {
    if (!RegExp(r'^[1-9]\d*$').hasMatch(orderId.trim())) {
      throw ApiException(
        message:
            'Đơn hàng này chưa có ID hợp lệ từ máy chủ. Vui lòng tải lại danh sách đơn hàng trước khi thanh toán.',
        statusCode: 400,
        errorCode: 'INVALID_ORDER_ID',
      );
    }
    final body = <String, dynamic>{
      'orderId': orderId.trim(),
      if (description != null && description.isNotEmpty)
        'description': description.trim(),
      if (returnUrl != null && returnUrl.isNotEmpty) 'returnUrl': returnUrl,
      if (cancelUrl != null && cancelUrl.isNotEmpty) 'cancelUrl': cancelUrl,
    };

    final response = await _client.post(
      ApiConfig.paymentsPayosCreateLink,
      body: body,
    );

    final data = response['data'] ?? response;
    if (data is Map<String, dynamic>) {
      return PayosPaymentData.fromJson(data);
    } else if (data is Map) {
      return PayosPaymentData.fromJson(Map<String, dynamic>.from(data));
    }

    throw ApiException(
      message:
          response['message']?.toString() ??
          'Dữ liệu tạo link thanh toán PayOS không hợp lệ',
      statusCode: response['statusCode'] is int ? response['statusCode'] : 400,
      errorCode: response['code']?.toString(),
    );
  }

  /// Lấy thông tin trạng thái link thanh toán PayOS theo ID hoặc mã
  Future<Map<String, dynamic>> getPaymentRequestInfo(String id) async {
    final response = await _client.get(ApiConfig.paymentsPayosRequest(id));
    return response['data'] is Map<String, dynamic>
        ? response['data']
        : (response is Map<String, dynamic> ? response : {});
  }

  /// Hủy liên kết thanh toán PayOS đang PENDING
  Future<Map<String, dynamic>> cancelPaymentLink(
    String id, {
    String? reason,
  }) async {
    final body = <String, dynamic>{
      if (reason != null && reason.isNotEmpty) 'cancellationReason': reason,
    };
    final response = await _client.post(
      ApiConfig.paymentsPayosCancel(id),
      body: body,
    );
    return response;
  }
}
