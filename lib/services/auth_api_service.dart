import 'api_client.dart';
import 'api_config.dart';

class AuthApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  final ApiClient _client = ApiClient();

  /// Đăng nhập bằng email/username và mật khẩu
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool? rememberMe,
  }) async {
    final body = <String, dynamic>{'email': email.trim(), 'password': password};
    if (rememberMe != null) {
      body['rememberMe'] = rememberMe;
    }

    final response = await _client.post(ApiConfig.authLogin, body: body);

    final data = response['data'] ?? response;
    final accessToken =
        response['accessToken'] ?? data['token'] ?? data['accessToken'];
    final refreshToken = response['refreshToken'] ?? data['refreshToken'];

    if (accessToken != null) {
      await _client.setTokens(
        accessToken: accessToken.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    return response is Map<String, dynamic>
        ? response
        : {'success': true, 'data': response};
  }

  /// Đăng ký tài khoản cư dân / người dùng mới
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? phone,
    String? address,
    String? storeName,
    String? role,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName.trim(),
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone.trim();
    if (address != null && address.isNotEmpty) body['address'] = address.trim();
    if (storeName != null && storeName.isNotEmpty) {
      body['storeName'] = storeName.trim();
    }
    if (role != null && role.isNotEmpty) body['role'] = role;

    final response = await _client.post(ApiConfig.authRegister, body: body);

    final data = response['data'] ?? response;
    final accessToken =
        response['accessToken'] ?? data['token'] ?? data['accessToken'];
    final refreshToken = response['refreshToken'] ?? data['refreshToken'];

    if (accessToken != null) {
      await _client.setTokens(
        accessToken: accessToken.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    return response is Map<String, dynamic>
        ? response
        : {'success': true, 'data': response};
  }

  /// Đăng ký tài khoản cư dân bằng Firebase Phone Auth ID Token
  Future<Map<String, dynamic>> registerByPhone({
    required String firebaseIdToken,
    required String fullName,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'firebaseIdToken': firebaseIdToken.trim(),
      'fullName': fullName.trim(),
    };
    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim().toLowerCase();
    }

    final response = await _client.post(
      ApiConfig.authRegisterByPhone,
      body: body,
    );

    final data = response['data'] ?? response;
    final accessToken =
        response['accessToken'] ?? data['token'] ?? data['accessToken'];
    final refreshToken = response['refreshToken'] ?? data['refreshToken'];

    if (accessToken != null) {
      await _client.setTokens(
        accessToken: accessToken.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    return response is Map<String, dynamic>
        ? response
        : {'success': true, 'data': response};
  }

  /// Đăng nhập bằng Firebase Phone Auth ID Token
  Future<Map<String, dynamic>> loginByPhone({
    required String firebaseIdToken,
  }) async {
    final response = await _client.post(
      ApiConfig.authLoginByPhone,
      body: {'firebaseIdToken': firebaseIdToken.trim()},
    );

    final data = response['data'] ?? response;
    final accessToken =
        response['accessToken'] ?? data['token'] ?? data['accessToken'];
    final refreshToken = response['refreshToken'] ?? data['refreshToken'];

    if (accessToken != null) {
      await _client.setTokens(
        accessToken: accessToken.toString(),
        refreshToken: refreshToken?.toString(),
      );
    }

    return response is Map<String, dynamic>
        ? response
        : {'success': true, 'data': response};
  }

  /// Exchange a verified Google ID token for the backend session.
  Future<Map<String, dynamic>> googleLogin(String token) async {
    final response = await _client.post(
      ApiConfig.authGoogleLogin,
      body: {'token': token},
    );

    final data = response['data'] ?? response;
    final accessToken =
        response['accessToken'] ?? data['accessToken'] ?? data['token'];
    final refreshToken = response['refreshToken'] ?? data['refreshToken'];

    if (response['success'] == false ||
        accessToken is! String ||
        accessToken.trim().isEmpty ||
        refreshToken is! String ||
        refreshToken.trim().isEmpty) {
      throw ApiException(
        message: 'Máy chủ không trả phiên đăng nhập hợp lệ.',
        statusCode: 502,
      );
    }
    await _client.clearTokens();
    await _client.setTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return response;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _client.post(
      '/auth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    if (response['success'] != true) {
      throw ApiException(
        message: 'Chưa thể xác nhận đổi mật khẩu. Vui lòng thử lại.',
        statusCode: 502,
      );
    }
    // The backend revokes every session after changing the password.
    await _client.clearTokens();
  }

  /// Cấp mới Access Token khi hết hạn
  Future<bool> refreshToken() async {
    final refreshToken = _client.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _client.post(
        ApiConfig.authRefresh,
        body: {'refreshToken': refreshToken},
      );
      final newAccessToken =
          response['accessToken'] ?? response['data']?['token'];
      if (newAccessToken != null) {
        await _client.setTokens(accessToken: newAccessToken.toString());
        return true;
      }
    } catch (_) {
      await _client.clearTokens();
    }
    return false;
  }

  /// Đăng xuất tài khoản
  Future<void> logout() async {
    try {
      if (_client.isAuthenticated) {
        await _client.post(
          ApiConfig.authLogout,
          body: {
            if (_client.refreshToken != null)
              'refreshToken': _client.refreshToken,
          },
        );
      }
    } finally {
      await _client.clearTokens();
    }
  }

  /// Lấy thông tin tài khoản hiện tại
  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get(ApiConfig.authMe);
    return response['data'] ?? response;
  }

  /// Alias for getMe
  Future<Map<String, dynamic>> getProfile() => getMe();

  /// Cập nhật thông tin hồ sơ tài khoản lên backend
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? address,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName.trim();
    if (phone != null) body['phone'] = phone.trim();
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (email != null || address != null) {
      throw ApiException(
        message:
            'Email không thể sửa tại đây. Vui lòng quản lý địa chỉ trong sổ địa chỉ.',
        statusCode: 400,
        errorCode: 'UNSUPPORTED_PROFILE_FIELD',
      );
    }
    final response = await _client.patch(ApiConfig.authMe, body: body);
    return Map<String, dynamic>.from(response);
  }

  /// Kiểm tra email đã đăng ký chưa
  Future<bool> checkEmail(String email) async {
    try {
      final res = await _client.get(
        ApiConfig.authCheckEmail,
        queryParams: {'email': email.trim()},
      );
      return res['exists'] == true || res['available'] == false;
    } catch (_) {
      return false;
    }
  }

  /// Kiểm tra username đã đăng ký chưa
  Future<bool> checkUsername(String username) async {
    try {
      final res = await _client.get(
        ApiConfig.authCheckUsername,
        queryParams: {'username': username.trim()},
      );
      return res['exists'] == true || res['available'] == false;
    } catch (_) {
      return false;
    }
  }

  /// Quên mật khẩu
  Future<void> forgotPassword(String email) async {
    await _client.post(
      ApiConfig.authForgotPassword,
      body: {'email': email.trim()},
    );
  }

  /// Đặt lại mật khẩu mới
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _client.post(
      ApiConfig.authResetPassword,
      body: {
        'email': email.trim().toLowerCase(),
        'token': token.trim(),
        'newPassword': newPassword,
      },
    );
  }
}
