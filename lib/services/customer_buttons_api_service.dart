import '../models/customer_button_contract.dart';
import 'api_client.dart';
import 'api_config.dart';

/// Customer custody operations only. Store rental fees are not collected here.
class CustomerButtonsApiService {
  final ApiClient _client = ApiClient();

  Future<List<CustomerButtonContract>> getMyButtons() async {
    final response = await _client.get(ApiConfig.myRentals);
    final rows = response['data'];
    if (rows is! List) throw const FormatException('Không thể đọc hồ sơ nút');
    return rows
        .map(
          (row) => CustomerButtonContract.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> requestReturn({
    required String contractId,
    required String buttonId,
  }) async {
    final response = await _client.post(
      '/rentals/${Uri.encodeComponent(contractId)}/return-requests',
      body: {'buttonId': buttonId},
    );
    final data = response['data'];
    if (data is! Map ||
        data['returnId'] == null ||
        data['status'] != 'PENDING_RECEIPT') {
      throw const FormatException('Chưa nhận được xác nhận yêu cầu trả nút');
    }
    return Map<String, dynamic>.from(data);
  }
}
