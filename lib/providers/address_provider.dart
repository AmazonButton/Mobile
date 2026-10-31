import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../services/address_api_service.dart';
import '../services/user_profile_service.dart';

class AddressProvider extends ChangeNotifier {
  final AddressApiService _apiService;
  final UserProfileService _userProfileService;

  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _isLoading = false;
  String? _errorMessage;

  AddressProvider({
    AddressApiService? apiService,
    UserProfileService? userProfileService,
  }) : _apiService = apiService ?? AddressApiService(),
       _userProfileService = userProfileService ?? UserProfileService();

  List<AddressModel> get addresses => List.unmodifiable(_addresses);
  AddressModel? get selectedAddress => _selectedAddress ?? defaultAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Lấy địa chỉ mặc định của người dùng
  AddressModel? get defaultAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  /// Chuỗi địa chỉ hiển thị hiện tại
  String get currentAddressDisplay => selectedAddress?.fullAddress ?? '';

  /// Tải danh sách địa chỉ từ API hoặc cache cục bộ
  Future<void> loadAddresses({bool force = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _apiService.getAddresses();
      _addresses = list;

      // Đồng bộ địa chỉ đang chọn
      if (_selectedAddress == null ||
          !_addresses.any((a) => a.id == _selectedAddress!.id)) {
        _selectedAddress = defaultAddress;
      }

      _selectedAddress =
          _addresses.where((a) => a.id == _selectedAddress?.id).firstOrNull ??
          defaultAddress;
      _userProfileService.updateAddress(_selectedAddress?.fullAddress ?? '');
      _errorMessage = null;
    } catch (e) {
      _addresses = [];
      _selectedAddress = null;
      _userProfileService.updateAddress('');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm địa chỉ mới (Create)
  Future<AddressModel?> addAddress(AddressModel newAddress) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _apiService.createAddress(newAddress);

      if (created.isDefault || _addresses.isEmpty) {
        _addresses = _addresses
            .map((a) => a.copyWith(isDefault: false))
            .toList();
        _selectedAddress = created;
        _userProfileService.updateAddress(created.fullAddress);
      }

      _addresses.insert(0, created);
      _errorMessage = null;
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật địa chỉ (Update)
  Future<bool> updateAddress(AddressModel updatedAddress) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateAddress(updatedAddress);
      final index = _addresses.indexWhere((a) => a.id == updated.id);

      if (index != -1) {
        if (updated.isDefault) {
          _addresses = _addresses
              .map((a) => a.copyWith(isDefault: false))
              .toList();
          _selectedAddress = updated;
          _userProfileService.updateAddress(updated.fullAddress);
        } else if (_selectedAddress?.id == updated.id) {
          _selectedAddress = updated;
          _userProfileService.updateAddress(updated.fullAddress);
        }
        _addresses[index] = updated;
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa địa chỉ (Delete)
  Future<bool> deleteAddress(String addressId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.deleteAddress(addressId);
      if (success) {
        final wasSelected = _selectedAddress?.id == addressId;
        _addresses.removeWhere((a) => a.id == addressId);

        await loadAddresses();
        if (wasSelected || _addresses.isEmpty) {
          _selectedAddress = defaultAddress;
          _userProfileService.updateAddress(
            _selectedAddress?.fullAddress ?? '',
          );
        }
      }
      _errorMessage = null;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đặt một địa chỉ làm mặc định
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      final success = await _apiService.setDefaultAddress(addressId);
      if (success) {
        _addresses = _addresses.map((a) {
          return a.copyWith(isDefault: a.id == addressId);
        }).toList();

        final target = _addresses.firstWhere((a) => a.id == addressId);
        _selectedAddress = target;
        _userProfileService.updateAddress(target.fullAddress);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }

  /// Chọn địa chỉ giao hàng cho phiên hiện tại (HomeScreen / Đặt đơn)
  void selectDeliveryAddress(AddressModel address) {
    _selectedAddress = address;
    _userProfileService.updateAddress(address.fullAddress);
    notifyListeners();
  }

  /// Đặt lại dữ liệu khi người dùng đăng xuất
  void reset() {
    _addresses = [];
    _selectedAddress = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
