import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/main.dart' show navigatorKey;
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/screens/orders_screen.dart';
import 'package:smart_order_button/services/notification_service.dart';

Widget createTestApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => OrderProvider()),
    ],
    child: MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(
        body: Text('Home Screen Test Base'),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    NotificationService().resetDebounceForTesting();
  });

  group('Story 5.3 - Notification Deep Linking and Routing Tests', () {
    testWidgets('Routes to OrdersScreen when payload has type ORDER_CREATED',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('Home Screen Test Base'), findsOneWidget);
      expect(find.byType(OrdersScreen), findsNothing);

      NotificationService().handleNotificationNavigation({
        'type': 'ORDER_CREATED',
        'orderId': 'ord_123',
        'orderCode': 'ORD-9999',
      });

      await tester.pumpAndSettle();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets(
        'Routes to OrdersScreen when payload has type ORDER_STATUS_CHANGED',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('Home Screen Test Base'), findsOneWidget);

      NotificationService().handleNotificationNavigation({
        'type': 'ORDER_STATUS_CHANGED',
        'orderId': 'ord_456',
        'status': 'DELIVERED',
      });

      await tester.pumpAndSettle();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('Routes to OrdersScreen when payload has valid orderId',
        (tester) async {
      await tester.pumpWidget(createTestApp());

      NotificationService().handleNotificationNavigation({
        'orderId': '1002',
      });

      await tester.pumpAndSettle();
      expect(find.byType(OrdersScreen), findsOneWidget);
    });

    testWidgets('Does not navigate when payload is general announcement',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('Home Screen Test Base'), findsOneWidget);

      NotificationService().handleNotificationNavigation({
        'type': 'SYSTEM_ALERT',
        'message': 'Welcome to SmartOrder',
      });

      await tester.pumpAndSettle();
      expect(find.byType(OrdersScreen), findsNothing);
      expect(find.text('Home Screen Test Base'), findsOneWidget);
    });

    testWidgets('Handles empty or malformed payload gracefully without crashing',
        (tester) async {
      await tester.pumpWidget(createTestApp());

      expect(() {
        NotificationService().handleNotificationNavigation({});
      }, returnsNormally);

      expect(() {
        NotificationService().handleNotificationNavigation({
          'type': null,
          'orderId': null,
        });
      }, returnsNormally);

      expect(() {
        NotificationService().handleNotificationNavigation({
          'type': 12345,
          'orderId': false,
        });
      }, returnsNormally);

      await tester.pumpAndSettle();
      expect(find.text('Home Screen Test Base'), findsOneWidget);
    });

    testWidgets(
        'Debounces rapid successive clicks to prevent duplicate screen pushes',
        (tester) async {
      await tester.pumpWidget(createTestApp());

      // Rapid consecutive triggers (simulating user double-tapping a notification)
      NotificationService().handleNotificationNavigation({
        'type': 'ORDER_CREATED',
        'orderId': 'ord_rapid_1',
      });
      NotificationService().handleNotificationNavigation({
        'type': 'ORDER_CREATED',
        'orderId': 'ord_rapid_1',
      });

      await tester.pumpAndSettle();
      // Only 1 OrdersScreen is pushed onto the navigator stack
      expect(find.byType(OrdersScreen), findsOneWidget);
    });
  });
}
