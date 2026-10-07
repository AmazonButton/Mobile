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
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
    };
    if (rememberMe != null) {
      body['rememberMe'] = rememberMe;
    }

    final response = await _client.post(
      ApiConfig.authLogin,
      body: body,
    );

    final data = response['data'] ?? response;
    final accessToken = response['accessToken'] ?? data['token'] ?? data['accessToken'];
    final refreshToken = response['refreshToken'] ?? data['refreshToken'];

    if (accessToken != null) {
      _client.setTokens(accessToken: accessToken.toString(), refreshToken: refreshToken?.toString());
    }

    return response is Map<String, dynamic> ? response : {'success': true, 'data': response};
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
    if (storeName != null && storeName.isNotEmpty) body['storeName'] = storeName.trim();
    if (role != null && role.isNotEmpty) body['role'] = role;

    final response = await _client.post(
      ApiConfig.authRegister,
      body: body,
    );

    final data = response['data'] ?? response;
    final accessToken = response['accessToken'] ?? data['token'] ?? data['accessToken'];
    final refreshToken = response['refreshToken'] ?? data['refreshToken'];

    if (accessToken != null) {
      _client.setTokens(accessToken: accessToken.toString(), refreshToken: refreshToken?.toString());
    }

    return response is Map<String, dynamic> ? response : {'success': true, 'data': response};
  }

  /// Đăng nhập bằng Google qua Supabase Access Token
  Future<Map<String, dynamic>> googleLogin(String token) async {
    final response = await _client.post(
      ApiConfig.authGoogleLogin,
      body: {'token': token},
    );

    final data = response['data'] ?? response;
    final accessToken = response['accessToken'] ?? data['token'];
    final refreshToken = response['refreshToken'] ?? data['refreshToken'];

    if (accessToken != null) {
      _client.setTokens(accessToken: accessToken.toString(), refreshToken: refreshToken?.toString());
    }

    return response;
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
      final newAccessToken = response['accessToken'] ?? response['data']?['token'];
      if (newAccessToken != null) {
        _client.setTokens(accessToken: newAccessToken.toString());
        return true;
      }
    } catch (_) {
      _client.clearTokens();
    }
    return false;
  }

  /// Đăng xuất tài khoản
  Future<void> logout() async {
    try {
      if (_client.isAuthenticated) {
        await _client.post(
          ApiConfig.authLogout,
          body: {if (_client.refreshToken != null) 'refreshToken': _client.refreshToken},
        );
      }
    } finally {
      _client.clearTokens();
    }
  }

  /// Lấy thông tin tài khoản hiện tại
  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get(ApiConfig.authMe);
    return response['data'] ?? response;
  }

  /// Kiểm tra email đã đăng ký chưa
  Future<bool> checkEmail(String email) async {
    try {
      final res = await _client.get(ApiConfig.authCheckEmail, queryParams: {'email': email.trim()});
      return res['exists'] == true || res['available'] == false;
    } catch (_) {
      return false;
    }
  }

  /// Kiểm tra username đã đăng ký chưa
  Future<bool> checkUsername(String username) async {
    try {
      final res = await _client.get(ApiConfig.authCheckUsername, queryParams: {'username': username.trim()});
      return res['exists'] == true || res['available'] == false;
    } catch (_) {
      return false;
    }
  }

  /// Quên mật khẩu
  Future<void> forgotPassword(String email) async {
    await _client.post(ApiConfig.authForgotPassword, body: {'email': email.trim()});
  }

  /// Đặt lại mật khẩu mới
  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _client.post(
      ApiConfig.authResetPassword,
      body: {'token': token.trim(), 'newPassword': newPassword},
    );
  }
}
