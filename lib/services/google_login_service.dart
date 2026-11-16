import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_api_service.dart';
import 'api_client.dart';

class GoogleLoginService {
  GoogleLoginService({
    Future<String?> Function()? acquireIdToken,
    AuthApiService? auth,
  }) : _acquire = acquireIdToken ?? _nativeToken,
       _auth = auth ?? AuthApiService();

  final Future<String?> Function() _acquire;
  final AuthApiService _auth;
  static Future<void>? _initialization;
  bool _busy = false;

  static Future<String?> _nativeToken() async {
    if (kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      throw ApiException(
        message: 'Vui lòng dùng ứng dụng Android hoặc iOS để đăng nhập Google.',
        statusCode: 0,
      );
    }
    const serverId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    const clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    final signIn = GoogleSignIn.instance;
    try {
      _initialization ??= signIn.initialize(
        serverClientId: serverId.isEmpty ? null : serverId,
        clientId: clientId.isEmpty ? null : clientId,
      );
      await _initialization;
      if (!signIn.supportsAuthenticate()) {
        throw ApiException(
          message: 'Thiết bị chưa hỗ trợ đăng nhập Google.',
          statusCode: 0,
        );
      }
      final account = await signIn.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw ApiException(
        message:
            'Không thể đăng nhập Google. Vui lòng thử lại hoặc dùng email/số điện thoại.',
        statusCode: 0,
      );
    } on PlatformException {
      throw ApiException(
        message: 'Đăng nhập Google chưa sẵn sàng trên thiết bị này.',
        statusCode: 0,
      );
    }
  }

  Future<Map<String, dynamic>?> signIn() async {
    if (_busy) return null;
    _busy = true;
    try {
      final token = await _acquire();
      if (token == null) return null;
      if (token.trim().isEmpty) {
        throw ApiException(
          message: 'Không nhận được xác thực từ Google.',
          statusCode: 0,
        );
      }
      return await _auth.googleLogin(token);
    } finally {
      _busy = false;
    }
  }
}
