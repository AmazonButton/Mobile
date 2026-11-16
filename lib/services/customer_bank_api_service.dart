import '../models/customer_bank_account.dart';
import 'api_client.dart';

class CustomerBankApiService {
  final ApiClient _client = ApiClient();
  static const _accounts = '/customers/me/bank-accounts';
  String _account(String id) => '$_accounts/${Uri.encodeComponent(id)}';
  List<Map<String, dynamic>> _rows(dynamic response) {
    final rows = response['data'];
    if (rows is! List) {
      throw const FormatException('Không thể đọc danh sách tài khoản');
    }
    return rows
        .map<Map<String, dynamic>>(
          (row) => Map<String, dynamic>.from(row as Map),
        )
        .toList();
  }

  Map<String, dynamic> _data(dynamic response) {
    if (response['data'] is! Map) {
      throw const FormatException('Phản hồi ngân hàng không hợp lệ');
    }
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<List<CustomerBankAccount>> getAccounts() async => _rows(
    await _client.get(_accounts),
  ).map(CustomerBankAccount.fromJson).toList();
  Future<List<Map<String, dynamic>>> getBanks() async =>
      _rows(await _client.get('/banks'));
  Future<CustomerBankAccount> addAccount({
    required String bankBin,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required bool isDefault,
  }) async {
    return CustomerBankAccount.fromJson(
      _data(
        await _client.post(
          _accounts,
          body: {
            'bankBin': bankBin,
            'bankName': bankName,
            'accountNumber': accountNumber.trim(),
            'accountName': accountName.trim().toUpperCase(),
            'isDefault': isDefault,
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> initiateVerification(String id) async =>
      _data(await _client.post('${_account(id)}/initiate-verification'));
  Future<BankVerificationState> getStatus(String id) async =>
      BankVerificationState.fromJson(
        _data(await _client.get('${_account(id)}/verification-status')),
      );
  Future<Map<String, dynamic>> getHistory({int page = 1}) async {
    final response = await _client.get(
      '$_accounts/verification-history',
      queryParams: {'page': page, 'pageSize': 20},
    );
    _rows(response);
    return Map<String, dynamic>.from(response);
  }
}
