import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import '../models/order_model.dart';
import '../services/notification_service.dart';
import 'order_provider.dart';

/// Provider for managing in-app notifications, badge count, and persistence.
class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'cached_user_notifications';

  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  NotificationProvider() {
    _initHooks();
    loadNotifications();
  }

  void _initHooks() {
    NotificationService.onNotificationReceived = (item) {
      addNotification(item);
    };

    OrderProvider.onOrderCreated = (order) {
      addNotification(NotificationItem(
        id: 'order_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Đơn hàng đặt thành công',
        body: 'Đơn hàng ${order.orderCode} (${order.product}) của bạn đã được hệ thống tiếp nhận.',
        createdAt: order.createdAt ?? DateTime.now(),
        type: 'ORDER_CREATED',
        orderId: order.id,
        orderCode: order.orderCode,
      ));
    };

    OrderProvider.onOrderCancelled = (order, reason) {
      addNotification(NotificationItem(
        id: 'cancel_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Đã hủy đơn hàng',
        body: 'Đơn hàng ${order.orderCode} (${order.product}) đã được hủy${reason != null ? ': $reason' : '.'}',
        createdAt: DateTime.now(),
        type: 'ORDER_STATUS_CHANGED',
        orderId: order.id,
        orderCode: order.orderCode,
      ));
    };

    OrderProvider.onOrderPaid = (orderId, order) {
      addNotification(NotificationItem(
        id: 'paid_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Thanh toán thành công (PayOS)',
        body: 'Đơn hàng ${order.orderCode} (${order.product}) đã được thanh toán thành công qua PayOS.',
        createdAt: DateTime.now(),
        type: 'ORDER_PAYMENT_CONFIRMED',
        orderId: order.id,
        orderCode: order.orderCode,
      ));
    };

    OrderProvider.onOrdersLoaded = (orders) {
      syncOrders(orders);
    };
  }

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  /// Loads persisted notifications from local SharedPreferences.
  Future<void> loadNotifications() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _notifications = NotificationItem.decodeList(raw);
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves current notification list to local SharedPreferences.
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = NotificationItem.encodeList(_notifications);
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('[NotificationProvider] Error saving notifications: $e');
    }
  }

  /// Adds a new notification with deduplication (by id or orderCode+type within 15s).
  Future<void> addNotification(NotificationItem item) async {
    final now = DateTime.now();

    // Check for duplicate by ID
    final duplicateIndex = _notifications.indexWhere((n) => n.id == item.id);
    if (duplicateIndex != -1) return;

    // Check for duplicate by orderCode + type within 15s
    if (item.orderCode != null && item.orderCode!.isNotEmpty) {
      final isRecentDuplicate = _notifications.any((n) =>
          n.orderCode == item.orderCode &&
          n.type == item.type &&
          now.difference(n.createdAt).inSeconds.abs() < 15);
      if (isRecentDuplicate) return;
    }

    _notifications.insert(0, item);

    // Keep max 50 items to avoid bloating local storage
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }

    notifyListeners();
    await _saveToStorage();
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    bool hasChanges = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Deletes a specific notification.
  Future<void> deleteNotification(String id) async {
    final beforeCount = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.length != beforeCount) {
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Clears all notifications.
  Future<void> clearAll() async {
    if (_notifications.isNotEmpty) {
      _notifications.clear();
      notifyListeners();
      await _saveToStorage();
    }
  }

  /// Synchronizes notifications with user's orders, generating notifications for existing orders if missing.
  Future<void> syncOrders(List<OrderModel> orders) async {
    if (orders.isEmpty) return;

    bool added = false;
    for (final order in orders) {
      final code = order.orderCode;
      final exists = _notifications.any((n) => n.orderCode == code || n.orderId == order.id);
      if (!exists) {
        final title = order.isCancelled
            ? 'Đơn hàng đã hủy'
            : order.isCompleted
                ? 'Đơn hàng hoàn tất'
                : 'Đơn hàng đặt thành công';
        final body = 'Đơn hàng $code (${order.product}) có trạng thái: ${order.statusText}.';

        _notifications.add(NotificationItem(
          id: 'sync_${order.id}',
          title: title,
          body: body,
          createdAt: order.createdAt ?? DateTime.now(),
          isRead: false,
          type: order.isCancelled ? 'ORDER_STATUS_CHANGED' : 'ORDER_CREATED',
          orderId: order.id,
          orderCode: code,
        ));
        added = true;
      }
    }

    if (added) {
      // Sort newest first
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_notifications.length > 50) {
        _notifications = _notifications.sublist(0, 50);
      }
      notifyListeners();
      await _saveToStorage();
    }
  }
}
