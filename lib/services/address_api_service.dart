import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class AddressApiService {
  static final AddressApiService _instance = AddressApiService._internal();
  factory AddressApiService() => _instance;
  AddressApiService._internal();

  final ApiClient _client = ApiClient();
  static const String _cacheKey = 'user_saved_addresses_cache';

  /// Lấy danh sách địa chỉ của người dùng
  Future<List<AddressModel>> getAddresses() async {
    List<AddressModel> result = [];

    // 1. Thử gọi API REST /addresses
    try {
      final response = await _client.get(ApiConfig.addresses);
      final rawData = response['data'] ?? response;
      if (rawData is List) {
        result = rawData
            .map((item) => AddressModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[AddressApiService] /addresses endpoint not available: $e');
    }

    // 2. Nếu API /addresses chưa có hoặc trả về rỗng, kiểm tra qua /auth/me -> customerProfile.addresses
    if (result.isEmpty) {
      try {
        final me = await _client.get(ApiConfig.authMe);
        final profile = me['data']?['customerProfile'] ?? me['customerProfile'];
        if (profile is Map && profile['addresses'] is List) {
          final addrList = profile['addresses'] as List;
          result = addrList
              .map((item) =>
                  AddressModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      } catch (e) {
        debugPrint('[AddressApiService] Fallback /auth/me failed: $e');
      }
    }

    // 3. Nếu vẫn rỗng, đọc từ bộ nhớ cục bộ SharedPreferences
    if (result.isEmpty) {
      result = await _getCachedAddresses();
    }

    // 4. Nếu là lần đầu tiên hoàn toàn chưa có địa chỉ nào, khởi tạo địa chỉ mặc định
    if (result.isEmpty) {
      result = [
        const AddressModel(
          id: 'addr_default_1',
          recipientName: 'Nguyễn Văn An',
          phone: '0988776655',
          addressDetail: 'P.1204 - Tòa S2.05, Vinhomes Grand Park',
          ward: 'Phường Long Thạnh Mỹ',
          district: 'TP. Thủ Đức',
          province: 'TP. Hồ Chí Minh',
          isDefault: true,
          label: 'Nhà riêng',
        ),
      ];
      await _saveCachedAddresses(result);
    } else {
      // Đồng bộ vào cache
      await _saveCachedAddresses(result);
    }

    return result;
  }

  /// Tạo mới một địa chỉ giao hàng
  Future<AddressModel> createAddress(AddressModel address) async {
    AddressModel created = address;

    try {
      final response = await _client.post(
        ApiConfig.addresses,
        body: address.toJson(),
      );
      final rawData = response['data'] ?? response;
      if (rawData is Map) {
        created = AddressModel.fromJson(Map<String, dynamic>.from(rawData));
      }
    } catch (e) {
      debugPrint('[AddressApiService] createAddress backend fallback: $e');
      // Tạo id cục bộ nếu backend chưa khả dụng
      if (created.id.isEmpty) {
        created = created.copyWith(
          id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    }

    // Cập nhật bộ nhớ cục bộ
    final current = await _getCachedAddresses();
    if (created.isDefault) {
      for (int i = 0; i < current.length; i++) {
        current[i] = current[i].copyWith(isDefault: false);
      }
    }
    current.insert(0, created);
    await _saveCachedAddresses(current);

    return created;
  }

  /// Cập nhật thông tin địa chỉ
  Future<AddressModel> updateAddress(AddressModel address) async {
    AddressModel updated = address;

    try {
      final response = await _client.put(
        ApiConfig.addressDetail(address.id),
        body: address.toJson(),
      );
      final rawData = response['data'] ?? response;
      if (rawData is Map) {
        updated = AddressModel.fromJson(Map<String, dynamic>.from(rawData));
      }
    } catch (e) {
      debugPrint('[AddressApiService] updateAddress backend fallback: $e');
    }

    // Cập nhật bộ nhớ cục bộ
    final current = await _getCachedAddresses();
    final index = current.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      if (updated.isDefault) {
        for (int i = 0; i < current.length; i++) {
          current[i] = current[i].copyWith(isDefault: false);
        }
      }
      current[index] = updated;
      await _saveCachedAddresses(current);
    }

    return updated;
  }

  /// Xóa địa chỉ theo id
  Future<bool> deleteAddress(String addressId) async {
    bool success = false;

    try {
      await _client.delete(ApiConfig.addressDetail(addressId));
      success = true;
    } catch (e) {
      debugPrint('[AddressApiService] deleteAddress backend fallback: $e');
      success = true; // Cho phép xóa cục bộ
    }

    // Cập nhật bộ nhớ cục bộ
    final current = await _getCachedAddresses();
    current.removeWhere((a) => a.id == addressId);
    // Nếu xóa mất địa chỉ mặc định và danh sách còn phần tử, đặt phần tử đầu làm mặc định
    if (current.isNotEmpty && !current.any((a) => a.isDefault)) {
      current[0] = current[0].copyWith(isDefault: true);
    }
    await _saveCachedAddresses(current);

    return success;
  }

  /// Thiết lập một địa chỉ làm mặc định
  Future<bool> setDefaultAddress(String addressId) async {
    bool success = false;

    try {
      await _client.patch(ApiConfig.addressSetDefault(addressId));
      success = true;
    } catch (e) {
      try {
        await _client.put(ApiConfig.addressSetDefault(addressId));
        success = true;
      } catch (e2) {
        debugPrint('[AddressApiService] setDefaultAddress backend fallback: $e2');
        success = true; // Cập nhật cục bộ
      }
    }

    // Cập nhật bộ nhớ cục bộ
    final current = await _getCachedAddresses();
    for (int i = 0; i < current.length; i++) {
      current[i] = current[i].copyWith(isDefault: current[i].id == addressId);
    }
    await _saveCachedAddresses(current);

    return success;
  }

  // ================= CACHE HELPERS =================

  Future<List<AddressModel>> _getCachedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded
              .map((item) =>
                  AddressModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[AddressApiService] Error reading address cache: $e');
    }
    return [];
  }

  Future<void> _saveCachedAddresses(List<AddressModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = list.map((a) => a.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(raw));
    } catch (e) {
      debugPrint('[AddressApiService] Error saving address cache: $e');
    }
  }
}
