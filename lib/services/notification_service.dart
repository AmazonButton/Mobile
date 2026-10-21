import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show navigatorKey;
import '../models/notification_item.dart';
import '../screens/orders_screen.dart';
import 'api_client.dart';
import 'notifications_api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Optional listener hook for in-app notification provider
  static void Function(NotificationItem item)? onNotificationReceived;

  /// Optional callback hook triggered when an order payment is confirmed in real time
  static void Function(String orderId, String? orderCode)? onPaymentConfirmed;

  static const String _prefFcmTokenKey = 'cached_fcm_token';
  static const String channelId = 'smart_order_alerts';
  static const String channelName = 'Thông báo Đơn hàng Thông minh';
  static const String channelDescription =
      'Thông báo cập nhật đơn hàng tức thì từ nút bấm IoT SmartOrder';

  final NotificationsApiService _apiService = NotificationsApiService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _cachedToken;
  DateTime? _lastNavTime;

  String? get cachedToken => _cachedToken;

  /// Khởi tạo toàn bộ thiết lập FCM, Notification Channel và Local Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Yêu cầu cấp quyền hiển thị thông báo (bắt buộc cho Android 13+)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '[NotificationService] Notification permission status: ${settings.authorizationStatus}',
      );

      // 2. Khởi tạo plugin hiển thị thông báo cục bộ (Heads-up notification)
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _navigateToOrderFromPayload(response.payload);
          }
        },
      );

      // 3. Tạo Notification Channel ưu tiên cao cho Android
      final androidPlatform =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      // 4. Lắng nghe thông báo khi ứng dụng đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[NotificationService] Foreground message received: ${message.messageId}',
        );
        showLocalNotification(message);
      });

      // 5. Lắng nghe người dùng bấm vào thông báo khi app đang chạy nền (Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '[NotificationService] Notification tapped in background: ${message.data}',
        );
        handleNotificationNavigation(message.data);
      });

      // 6. Kiểm tra nếu app được mở từ trạng thái bị tắt hoàn toàn (Terminated)
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '[NotificationService] App launched from terminated state via notification: ${initialMessage.data}',
        );
        // Trì hoãn nhẹ để widget tree và navigatorKey hoàn tất build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationNavigation(initialMessage.data);
        });
      }

      // 7. Lắng nghe sự kiện xoay vòng / cấp mới FCM Token từ Firebase
      FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
        debugPrint('[NotificationService] FCM token refreshed: $newToken');
        _cachedToken = newToken;
        _saveCachedToken(newToken);
        if (ApiClient().isAuthenticated) {
          syncTokenWithBackend();
        }
      });

      // Lấy token ban đầu
      _cachedToken = await getDeviceToken();
      if (_cachedToken != null) {
        await _saveCachedToken(_cachedToken!);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Initialization error / Mock fallback: $e');
    }
  }

  /// Lấy FCM Token của thiết bị hiện tại
  Future<String?> getDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _cachedToken = token;
      }
      return token;
    } catch (e) {
      debugPrint('[NotificationService] Error getting FCM device token: $e');
      return _cachedToken;
    }
  }

  /// Đồng bộ FCM Token lên Backend khi người dùng đã đăng nhập
  Future<bool> syncTokenWithBackend({String? overrideToken}) async {
    try {
      final token = overrideToken ?? _cachedToken ?? await getDeviceToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint('[NotificationService] No FCM token available to sync.');
        return false;
      }

      final success = await _apiService.registerFcmToken(
        token,
        deviceType: 'ANDROID',
      );

      if (success) {
        await _saveCachedToken(token);
        debugPrint('[NotificationService] FCM token synced with Backend successfully.');
      }
      return success;
    } catch (e) {
      debugPrint('[NotificationService] Exception syncing FCM token with Backend: $e');
      return false;
    }
  }

  /// Hủy đăng ký FCM Token trên Backend khi người dùng đăng xuất
  Future<bool> unregisterTokenOnLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = _cachedToken ?? prefs.getString(_prefFcmTokenKey);

      if (token == null || token.trim().isEmpty) {
        return true;
      }

      final success = await _apiService.unregisterFcmToken(token);
      await prefs.remove(_prefFcmTokenKey);
      _cachedToken = null;
      debugPrint('[NotificationService] FCM token unregistered on logout.');
      return success;
    } catch (e) {
      debugPrint('[NotificationService] Exception unregistering FCM token on logout: $e');
      return false;
    }
  }

  /// Hiển thị thông báo cục bộ dạng Heads-Up Banner khi app đang mở
  Future<void> showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      final orderId = data['orderId']?.toString();
      final orderCode = data['orderCode']?.toString();
      final type = data['type']?.toString();
      final status = data['status']?.toString();

      final title = notification?.title ??
          (type == 'ORDER_PAYMENT_CONFIRMED' || status == 'PAID'
              ? 'Thanh toán thành công'
              : (type == 'ORDER_CREATED' ? 'Đơn hàng mới' : 'Cập nhật đơn hàng'));
      final body = notification?.body ??
          (orderCode != null
              ? (type == 'ORDER_PAYMENT_CONFIRMED' || status == 'PAID'
                  ? 'Đơn hàng #$orderCode đã được thanh toán thành công qua PayOS.'
                  : 'Đơn hàng #$orderCode của bạn đã được cập nhật')
              : 'Bạn có thông báo mới từ hệ thống');

      // Kích hoạt callback xác nhận thanh toán real-time
      if (type == 'ORDER_PAYMENT_CONFIRMED' || status == 'PAID') {
        if (orderId != null && orderId.isNotEmpty) {
          onPaymentConfirmed?.call(orderId, orderCode);
        }
      }

      // Lưu vào danh sách thông báo in-app
      _recordInAppNotification(
        title: title,
        body: body,
        orderId: orderId,
        orderCode: orderCode,
        type: type,
      );

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: data['orderId']?.toString(),
      );
    } catch (e) {
      debugPrint('[NotificationService] Error showing local notification: $e');
    }
  }

  /// Ghi nhận thông báo in-app vào provider và SharedPreferences
  Future<void> _recordInAppNotification({
    required String title,
    required String body,
    String? orderId,
    String? orderCode,
    String? type,
  }) async {
    try {
      final item = NotificationItem(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        createdAt: DateTime.now(),
        isRead: false,
        type: type ?? 'ORDER_CREATED',
        orderId: orderId,
        orderCode: orderCode,
      );

      // Kích hoạt callback nếu đã có NotificationProvider lắng nghe
      onNotificationReceived?.call(item);

      // Đồng thời lưu trực tiếp vào local storage
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_user_notifications');
      List<NotificationItem> list = raw != null && raw.isNotEmpty
          ? NotificationItem.decodeList(raw)
          : [];

      final isDup = list.any((n) =>
          (item.orderCode != null && n.orderCode == item.orderCode && n.type == item.type) ||
          n.id == item.id);
      if (!isDup) {
        list.insert(0, item);
        if (list.length > 50) list = list.sublist(0, 50);
        await prefs.setString(
          'cached_user_notifications',
          NotificationItem.encodeList(list),
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Error recording in-app notification: $e');
    }
  }

  /// Điều hướng người dùng đến màn hình danh sách đơn hàng khi bấm vào thông báo
  void handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      final now = DateTime.now();
      if (_lastNavTime != null &&
          now.difference(_lastNavTime!) < const Duration(milliseconds: 700)) {
        debugPrint('[NotificationService] Duplicate navigation ignored by debounce.');
        return;
      }
      _lastNavTime = now;

      final type = data['type']?.toString();
      final orderId = data['orderId']?.toString();

      debugPrint(
        '[NotificationService] Routing notification: type=$type, orderId=$orderId',
      );

      final isOrderEvent = type == 'ORDER_CREATED' ||
          type == 'ORDER_STATUS_CHANGED' ||
          (orderId != null && orderId.trim().isNotEmpty && orderId != 'null');

      if (isOrderEvent) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const OrdersScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Error navigating from notification: $e');
    }
  }

  @visibleForTesting
  void resetDebounceForTesting() {
    _lastNavTime = null;
  }

  void _navigateToOrderFromPayload(String? orderId) {
    if (orderId != null && orderId.trim().isNotEmpty && orderId != 'null') {
      handleNotificationNavigation({'orderId': orderId});
    }
  }

  Future<void> _saveCachedToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFcmTokenKey, token);
    } catch (_) {}
  }
}
