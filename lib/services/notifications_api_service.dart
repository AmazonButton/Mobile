import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'api_config.dart';

class NotificationsApiService {
  final ApiClient _apiClient;

  NotificationsApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Đăng ký hoặc cập nhật FCM Device Token lên Backend
  Future<bool> registerFcmToken(
    String token, {
    String deviceType = 'ANDROID',
  }) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) return false;

    try {
      final response = await _apiClient.post(
        ApiConfig.notificationsFcmToken,
        body: {
          'token': trimmedToken,
          'deviceType': deviceType.toUpperCase(),
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationsApiService] Lỗi khi đăng ký FCM token: $e');
      return false;
    }
  }

  /// Hủy đăng ký hoặc vô hiệu hóa FCM Device Token khi đăng xuất
  Future<bool> unregisterFcmToken(String token) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) return false;

    try {
      final response = await _apiClient.delete(
        ApiConfig.notificationsFcmToken,
        body: {
          'token': trimmedToken,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        return response['success'] == true;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationsApiService] Lỗi khi hủy FCM token: $e');
      return false;
    }
  }
}
