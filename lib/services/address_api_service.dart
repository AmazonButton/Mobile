import '../models/address_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class AddressApiService {
  final ApiClient _client = ApiClient();
  AddressModel _address(dynamic response) => AddressModel.fromJson(
    Map<String, dynamic>.from(response['data'] ?? response),
  );
  Future<List<AddressModel>> getAddresses() async {
    final response = await _client.get(ApiConfig.addresses);
    final data = response['data'];
    if (data is! List)
      throw const FormatException('Không thể đọc danh sách địa chỉ');
    return data
        .map((item) => AddressModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AddressModel> createAddress(AddressModel address) async => _address(
    await _client.post(
      ApiConfig.addresses,
      body: address.toJson()
        ..remove('id')
        ..remove('label'),
    ),
  );
  Future<AddressModel> updateAddress(AddressModel address) async => _address(
    await _client.put(
      ApiConfig.addressDetail(address.id),
      body: address.toJson()
        ..remove('id')
        ..remove('label'),
    ),
  );
  Future<bool> deleteAddress(String id) async {
    await _client.delete(ApiConfig.addressDetail(id));
    return true;
  }

  Future<bool> setDefaultAddress(String id) async {
    await _client.patch(ApiConfig.addressSetDefault(id));
    return true;
  }
}
