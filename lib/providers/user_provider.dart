import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/media_api_service.dart';
import '../services/api_client.dart';
import '../services/user_profile_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthApiService _authService;
  final UserProfileService _localProfile;
  final MediaApiService _media;
  bool _savingAvatar = false;
  int _avatarRevision = 0;
  int _sessionRevision = 0;
  bool get savingAvatar => _savingAvatar;
  String? get avatarUrl => _localProfile.avatarUrl;

  bool _isLoading = false;
  String? _errorMessage;

  UserProvider({
    AuthApiService? authService,
    UserProfileService? localProfile,
    MediaApiService? mediaService,
  }) : _authService = authService ?? AuthApiService(),
       _localProfile = localProfile ?? UserProfileService(),
       _media = mediaService ?? MediaApiService();

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
    final session = _sessionRevision, avatarRevision = _avatarRevision;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final me = await _authService.getMe();
      if (session != _sessionRevision) return;
      if (avatarRevision == _avatarRevision) {
        _localProfile.updateAvatarUrl(me['avatarUrl']?.toString());
      }
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
        final addr =
            me['address'] ??
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

  Future<void> updateName(String value) => updateProfile(fullName: value);

  Future<void> updatePhone(String value) => updateProfile(phone: value);

  Future<void> updateEmail(String value) => updateProfile(email: value);

  Future<void> updateAddress(String value) => updateProfile(address: value);

  bool _isSaving = false;

  /// Publish changes only after the backend has accepted them.
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? address,
  }) async {
    if (_isSaving) {
      throw StateError('Đang lưu hồ sơ. Vui lòng chờ.');
    }
    _isSaving = true;
    _errorMessage = null;
    try {
      if (email != null || address != null) {
        throw StateError(
          'Email không thể sửa tại đây. Vui lòng quản lý địa chỉ trong sổ địa chỉ.',
        );
      }
      final response = await _authService.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      final data = response['data'];
      if (fullName != null) {
        _localProfile.updateName(
          data is Map && data['fullName'] is String
              ? data['fullName'] as String
              : fullName.trim(),
        );
      }
      if (phone != null) {
        _localProfile.updatePhone(
          data is Map && data['phone'] is String
              ? data['phone'] as String
              : phone.trim(),
        );
      }
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatar(File? file) async {
    if (_savingAvatar) throw StateError('Đang lưu ảnh đại diện. Vui lòng chờ.');
    if (file == null) {
      throw ApiException(
        message: 'Chưa thể gỡ ảnh đại diện. Bạn có thể thay bằng ảnh khác.',
        statusCode: 400,
      );
    }
    _savingAvatar = true;
    final session = _sessionRevision;
    _avatarRevision++;
    _errorMessage = null;
    notifyListeners();
    try {
      final size = await file.length();
      if (size <= 0 || size > 5 * 1024 * 1024) {
        throw ApiException(
          message: 'Ảnh phải có dung lượng từ 1 byte đến 5 MB.',
          statusCode: 400,
        );
      }
      final url = await _media.uploadImage(file);
      if (session != _sessionRevision) return;
      final response = await _authService.updateProfile(avatarUrl: url);
      if (session != _sessionRevision) return;
      final saved = response['data'] is Map
          ? response['data']['avatarUrl']
          : null;
      final savedUri = saved is String ? Uri.tryParse(saved) : null;
      if (saved is! String ||
          savedUri == null ||
          !{'http', 'https'}.contains(savedUri.scheme) ||
          savedUri.host.isEmpty) {
        throw const FormatException('Máy chủ chưa xác nhận ảnh đại diện');
      }
      _localProfile.updateAvatarUrl(saved);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _savingAvatar = false;
      notifyListeners();
    }
  }

  /// Xóa sạch thông tin tài khoản khi logout
  void reset() {
    _sessionRevision++;
    _avatarRevision++;
    _localProfile.reset();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
