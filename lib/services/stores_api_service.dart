import 'paged_list_service.dart';
import 'api_client.dart';
import 'api_config.dart';

class StoresApiService {
  static final StoresApiService _instance = StoresApiService._internal();
  factory StoresApiService() => _instance;
  StoresApiService._internal();

  final ApiClient _client = ApiClient();

  /// Lấy danh sách đối tác cửa hàng
  Future<List<dynamic>> getStores() => getAllApiPages(ApiConfig.stores);

  /// Lấy toàn bộ cửa hàng (bao gồm chờ duyệt / tạm dừng) dành cho Admin, fallback sang /stores
  Future<List<dynamic>> getAdminStores() async {
    try {
      return await getAllApiPages(ApiConfig.adminStores);
    } catch (_) {
      return getStores();
    }
  }

  /// Thông tin cửa hàng hiện tại của Chủ cửa hàng (GET /stores/me)
  Future<Map<String, dynamic>> getMyStore() async {
    final response = await _client.get(ApiConfig.storeMe);
    return Map<String, dynamic>.from(response['data'] ?? response);
  }

  /// Cập nhật thông tin cửa hàng hiện tại (PATCH /stores/me)
  Future<Map<String, dynamic>> updateMyStore({
    String? name,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();
    if (address != null && address.trim().isNotEmpty) {
      body['address'] = address.trim();
    }
    final response = await _client.patch(ApiConfig.storeMe, body: body);
    return Map<String, dynamic>.from(response['data'] ?? response);
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
    final body = <String, dynamic>{
      'packageId': int.tryParse(packageId) ?? packageId,
      'monthsRented': months,
      'months': months,
    };
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

  /// Yêu cầu rút tiền về tài khoản ngân hàng (yêu cầu X-Idempotency-Key & số tiền nguyên >= 50.000đ)
  Future<Map<String, dynamic>> requestWithdrawal(
    int amount, {
    String? idempotencyKey,
  }) async {
    final key =
        idempotencyKey ?? 'wd_${DateTime.now().microsecondsSinceEpoch}_$amount';
    final response = await _client.post(
      ApiConfig.storeWalletWithdrawals,
      headers: {'X-Idempotency-Key': key},
      body: {'amount': amount},
    );
    return Map<String, dynamic>.from(response['data'] ?? response);
  }

  /// Thiết lập tài khoản ngân hàng nhận tiền quyết toán (khớp UpdateBankAccountDto backend)
  Future<Map<String, dynamic>> updateBankAccount({
    required String bankBin,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountHolder,
  }) async {
    final response = await _client.put(
      ApiConfig.storeWalletBankAccount,
      body: {
        'bankBin': bankBin.trim(),
        'bankName': bankName.trim(),
        'bankAccountNumber': bankAccountNumber.trim(),
        'bankAccountHolder': bankAccountHolder.trim(),
      },
    );
    return Map<String, dynamic>.from(response['data'] ?? response);
  }
}
