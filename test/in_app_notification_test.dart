import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_order_button/models/notification_item.dart';
import 'package:smart_order_button/models/order_model.dart';
import 'package:smart_order_button/providers/notification_provider.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/screens/home/widgets/home_header_card.dart';
import 'package:smart_order_button/widgets/modals/notification_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('In-App Notification Item Model Tests', () {
    test('NotificationItem serializes to and from JSON accurately', () {
      final now = DateTime(2026, 10, 21, 10, 30);
      final item = NotificationItem(
        id: 'notif_1',
        title: 'Đơn hàng đặt thành công',
        body: 'Đơn hàng #ORD-1234 đã được tiếp nhận',
        createdAt: now,
        isRead: false,
        type: 'ORDER_CREATED',
        orderId: 'ord_1',
        orderCode: '#ORD-1234',
      );

      final json = item.toJson();
      expect(json['id'], 'notif_1');
      expect(json['title'], 'Đơn hàng đặt thành công');
      expect(json['orderCode'], '#ORD-1234');
      expect(json['isRead'], isFalse);

      final decoded = NotificationItem.fromJson(json);
      expect(decoded.id, item.id);
      expect(decoded.title, item.title);
      expect(decoded.body, item.body);
      expect(decoded.orderCode, item.orderCode);
      expect(decoded.createdAt, item.createdAt);
      expect(decoded.isRead, isFalse);
    });

    test('timeAgo returns Vietnamese human-readable relative time strings', () {
      final now = DateTime.now();
      final justNow = NotificationItem(
        id: '1',
        title: 'Test',
        body: 'Test',
        createdAt: now.subtract(const Duration(seconds: 10)),
      );
      expect(justNow.timeAgo, 'Vừa xong');

      final fiveMinsAgo = NotificationItem(
        id: '2',
        title: 'Test',
        body: 'Test',
        createdAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(fiveMinsAgo.timeAgo, '5 phút trước');

      final twoHoursAgo = NotificationItem(
        id: '3',
        title: 'Test',
        body: 'Test',
        createdAt: now.subtract(const Duration(hours: 2)),
      );
      expect(twoHoursAgo.timeAgo, '2 giờ trước');
    });
  });

  group('NotificationProvider State & Lifecycle Tests', () {
    test('addNotification adds item, updates unread count and deduplicates', () async {
      final provider = NotificationProvider();

      expect(provider.unreadCount, 0);
      expect(provider.hasUnread, isFalse);

      final item1 = NotificationItem(
        id: 'notif_order_1',
        title: 'Đơn hàng đặt thành công',
        body: 'Đơn hàng #ORD-001 đang chuẩn bị',
        createdAt: DateTime.now(),
        orderCode: '#ORD-001',
        type: 'ORDER_CREATED',
      );

      await provider.addNotification(item1);
      expect(provider.notifications.length, 1);
      expect(provider.unreadCount, 1);
      expect(provider.hasUnread, isTrue);

      // Attempt adding duplicate
      await provider.addNotification(item1);
      expect(provider.notifications.length, 1);

      // Mark as read
      await provider.markAsRead('notif_order_1');
      expect(provider.unreadCount, 0);
      expect(provider.hasUnread, isFalse);
      expect(provider.notifications.first.isRead, isTrue);
    });

    test('markAllAsRead, deleteNotification and clearAll work properly', () async {
      final provider = NotificationProvider();

      await provider.addNotification(NotificationItem(
        id: '1',
        title: 'T1',
        body: 'B1',
        createdAt: DateTime.now(),
      ));
      await provider.addNotification(NotificationItem(
        id: '2',
        title: 'T2',
        body: 'B2',
        createdAt: DateTime.now(),
      ));

      expect(provider.unreadCount, 2);

      await provider.markAllAsRead();
      expect(provider.unreadCount, 0);

      await provider.deleteNotification('1');
      expect(provider.notifications.length, 1);
      expect(provider.notifications.first.id, '2');

      await provider.clearAll();
      expect(provider.notifications.isEmpty, isTrue);
    });

    test('syncOrders creates notifications for orders without existing notifications', () async {
      final provider = NotificationProvider();
      final orders = [
        OrderModel(
          id: 'ord_10',
          orderCode: '#ORD-1010',
          customerName: 'Nguyễn Văn An',
          apartment: 'P101',
          product: 'Nước Lavie 20L',
          title: '1x Nước Lavie 20L',
          price: '65.000đ',
          rawAmount: 65000,
          status: OrderStatus.warning,
          rawStatus: 'PENDING',
          statusText: 'Đang xử lý',
          time: 'Vừa xong',
          createdAt: DateTime.now(),
        ),
      ];

      await provider.syncOrders(orders);
      expect(provider.notifications.length, 1);
      expect(provider.notifications.first.orderCode, '#ORD-1010');
      expect(provider.unreadCount, 1);
    });

    test('Automatically receives order creation via OrderProvider hook', () async {
      final notifProvider = NotificationProvider();
      final orderProvider = OrderProvider(initialOrders: []);

      await orderProvider.createOneTouchOrder(
        deviceId: 'btn-1',
        buttonName: 'Nút Nước',
        productName: 'Nước Lavie 20L',
        productPrice: '65.000đ',
      );

      expect(notifProvider.notifications.length, 1);
      expect(notifProvider.notifications.first.title, 'Đơn hàng đặt thành công');
      expect(notifProvider.hasUnread, isTrue);
    });
  });

  group('HomeHeaderCard & NotificationSheet Widget Tests', () {
    testWidgets('HomeHeaderCard renders notification bell with red badge only when unreadCount > 0',
        (tester) async {
      bool bellTapped = false;

      // 1. With 0 unread notifications
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeaderCard(
              userInitials: 'AN',
              userShortName: 'An',
              userAddress: 'Masteri Thảo Điền',
              unreadNotificationCount: 0,
              onAccountTap: () {},
              onNotificationTap: () => bellTapped = true,
              onLocationTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.bell), findsOneWidget);
      // Red badge dot should not be rendered
      final redBoxZero = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == const Color(0xFFEF4444));
      expect(redBoxZero, findsNothing);

      // Tap bell
      await tester.tap(find.byIcon(LucideIcons.bell));
      expect(bellTapped, isTrue);

      // 2. With 2 unread notifications
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeaderCard(
              userInitials: 'AN',
              userShortName: 'An',
              userAddress: 'Masteri Thảo Điền',
              unreadNotificationCount: 2,
              onAccountTap: () {},
              onNotificationTap: () {},
              onLocationTap: () {},
            ),
          ),
        ),
      );

      final redBoxActive = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == const Color(0xFFEF4444));
      expect(redBoxActive, findsOneWidget);
    });

    testWidgets('NotificationSheet renders empty state when no notifications exist', (tester) async {
      final notifProvider = NotificationProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: notifProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Chưa có thông báo nào'), findsOneWidget);
      expect(find.byIcon(LucideIcons.bellOff), findsOneWidget);
    });

    testWidgets('NotificationSheet displays notifications, marks as read, and clears all',
        (tester) async {
      final notifProvider = NotificationProvider();
      await notifProvider.addNotification(
        NotificationItem(
          id: 'test_1',
          title: 'Đơn hàng đặt thành công',
          body: 'Đơn hàng #ORD-9999 của bạn đã được tiếp nhận.',
          createdAt: DateTime.now(),
          orderCode: '#ORD-9999',
          isRead: false,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: notifProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationSheet(),
            ),
          ),
        ),
      );

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('1 mới'), findsOneWidget);
      expect(find.text('Đơn hàng đặt thành công'), findsOneWidget);
      expect(find.text('#ORD-9999'), findsOneWidget);

      // Tap "Đọc tất cả"
      await tester.tap(find.text('Đọc tất cả'));
      await tester.pump();
      expect(notifProvider.unreadCount, 0);

      // Tap "Xóa tất cả"
      await tester.tap(find.text('Xóa tất cả'));
      await tester.pump();
      expect(notifProvider.notifications.isEmpty, isTrue);
      expect(find.text('Chưa có thông báo nào'), findsOneWidget);
    });
  });
}
