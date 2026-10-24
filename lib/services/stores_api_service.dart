import 'api_client.dart';
import 'api_config.dart';

class StoresApiService {
  static final StoresApiService _instance = StoresApiService._internal();
  factory StoresApiService() => _instance;
  StoresApiService._internal();

  final ApiClient _client = ApiClient();

  /// Lấy danh sách đối tác cửa hàng
  Future<List<dynamic>> getStores() async {
    final stores = <dynamic>[];
    var page = 1;
    while (true) {
      final response = await _client.get(
        ApiConfig.stores,
        queryParams: {'page': page, 'limit': 100},
      );
      final data = response['data'] ?? response;
      if (data is List) return data;
      if (data is! Map || data['items'] is! List) {
        throw FormatException('Không thể đọc danh sách cửa hàng');
      }
      final items = data['items'] as List;
      stores.addAll(items);
      final totalPages =
          int.tryParse(data['totalPages']?.toString() ?? '') ?? page;
      if (items.isEmpty || page >= totalPages) return stores;
      page++;
    }
  }

  /// Chi tiết thông tin cửa hàng
  Future<Map<String, dynamic>> getStoreById(String id) async {
    final response = await _client.get(ApiConfig.storeDetail(id));
    return response['data'] ?? response;
  }

  /// Danh sách các gói thuê nút bấm thông minh
  Future<List<dynamic>> getRentalPackages() async {
    final response = await _client.get(ApiConfig.rentalPackages);
    final data = response['data'] ?? response;
    if (data is List) return data;
    return [];
  }

  /// Đặt thuê gói nút bấm IoT
  Future<Map<String, dynamic>> orderRentalPackage({
    required String packageId,
    int months = 1,
    String? deliveryAddress,
  }) async {
    final body = <String, dynamic>{'packageId': packageId, 'months': months};
    if (deliveryAddress != null && deliveryAddress.isNotEmpty) {
      body['deliveryAddress'] = deliveryAddress;
    }

    final response = await _client.post(ApiConfig.rentalOrder, body: body);
    return response['data'] ?? response;
  }

  /// Danh sách gói thiết bị đang thuê của người dùng
  Future<List<dynamic>> getMyRentals() async {
    final response = await _client.get(ApiConfig.myRentals);
    final data = response['data'] ?? response;
    if (data is List) return data;
    return [];
  }

  /// Xem số dư ví doanh thu cửa hàng
  Future<Map<String, dynamic>> getStoreWallet() async {
    final response = await _client.get(ApiConfig.storeWallet);
    return response['data'] ?? response;
  }

  /// Lịch sử giao dịch ví cửa hàng
  Future<List<dynamic>> getStoreTransactions() async {
    final response = await _client.get(ApiConfig.storeWalletTransactions);
    final data = response['data'] ?? response;
    if (data is List) return data;
    return [];
  }

  /// Yêu cầu rút tiền về tài khoản ngân hàng
  Future<Map<String, dynamic>> requestWithdrawal(double amount) async {
    final response = await _client.post(
      ApiConfig.storeWalletWithdrawals,
      body: {'amount': amount},
    );
    return response['data'] ?? response;
  }

  /// Thiết lập tài khoản ngân hàng nhận tiền quyết toán
  Future<Map<String, dynamic>> updateBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    final response = await _client.put(
      ApiConfig.storeWalletBankAccount,
      body: {
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountHolder': accountHolder,
      },
    );
    return response['data'] ?? response;
  }
}
