import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/user_profile_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthApiService _authService;
  final UserProfileService _localProfile;

  bool _isLoading = false;
  String? _errorMessage;

  UserProvider({AuthApiService? authService, UserProfileService? localProfile})
      : _authService = authService ?? AuthApiService(),
        _localProfile = localProfile ?? UserProfileService();

  String get name => _localProfile.name;
  String get phone => _localProfile.phone;
  String get email => _localProfile.email;
  String get address => _localProfile.address;
  File? get avatarFile => _localProfile.avatarFile;
  String get shortName => _localProfile.shortName;
  String get initials => _localProfile.initials;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Tải thông tin người dùng từ backend
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final me = await _authService.getMe();
      if (me.isNotEmpty) {
        final fullName = me['fullName'] ?? me['name'];
        if (fullName != null && fullName.toString().trim().isNotEmpty) {
          _localProfile.updateName(fullName.toString().trim());
        }
        final phone = me['phone'] ?? me['phoneNumber'];
        if (phone != null && phone.toString().trim().isNotEmpty) {
          _localProfile.updatePhone(phone.toString().trim());
        }
        final email = me['email'];
        if (email != null && email.toString().trim().isNotEmpty) {
          _localProfile.updateEmail(email.toString().trim());
        }
        final customerProfile = me['customerProfile'];
        final addr = me['address'] ??
            me['deliveryAddress'] ??
            (customerProfile is Map
                ? (customerProfile['defaultAddress'] ??
                    customerProfile['deliveryAddress'])
                : null);
        if (addr != null && addr.toString().trim().isNotEmpty) {
          _localProfile.updateAddress(addr.toString().trim());
        }
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateName(String newName) {
    _localProfile.updateName(newName);
    notifyListeners();
    _authService.updateProfile(fullName: newName);
  }

  void updatePhone(String newPhone) {
    _localProfile.updatePhone(newPhone);
    notifyListeners();
    _authService.updateProfile(phone: newPhone);
  }

  void updateEmail(String newEmail) {
    _localProfile.updateEmail(newEmail);
    notifyListeners();
    _authService.updateProfile(email: newEmail);
  }

  void updateAddress(String newAddress) {
    _localProfile.updateAddress(newAddress);
    notifyListeners();
    _authService.updateProfile(address: newAddress);
  }

  /// Cập nhật đồng bộ nhiều trường hồ sơ
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? address,
  }) async {
    if (fullName != null && fullName.trim().isNotEmpty) {
      _localProfile.updateName(fullName.trim());
    }
    if (phone != null && phone.trim().isNotEmpty) {
      _localProfile.updatePhone(phone.trim());
    }
    if (email != null && email.trim().isNotEmpty) {
      _localProfile.updateEmail(email.trim());
    }
    if (address != null && address.trim().isNotEmpty) {
      _localProfile.updateAddress(address.trim());
    }
    notifyListeners();
    await _authService.updateProfile(
      fullName: fullName,
      phone: phone,
      email: email,
      address: address,
    );
  }

  void updateAvatar(File? file) {
    _localProfile.updateAvatar(file);
    notifyListeners();
  }

  /// Xóa sạch thông tin tài khoản khi logout
  void reset() {
    _localProfile.reset();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
