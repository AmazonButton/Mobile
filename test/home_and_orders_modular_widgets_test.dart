import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/models/order_model.dart';
import 'package:smart_order_button/screens/home/widgets/widgets.dart';
import 'package:smart_order_button/screens/home_screen.dart';
import 'package:smart_order_button/screens/orders/widgets/widgets.dart';
import 'package:smart_order_button/screens/orders_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Story 4.3 - HomeScreen Modular Sub-Widgets Tests', () {
    testWidgets(
      'HomeHeaderCard renders user information and triggers callbacks',
      (tester) async {
        bool accountTapped = false;
        bool notifTapped = false;
        bool locationTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeHeaderCard(
                userInitials: 'JD',
                userShortName: 'John',
                userAddress: 'Vinhomes Central Park - Landmark 5, Tầng 18',
                onAccountTap: () => accountTapped = true,
                onNotificationTap: () => notifTapped = true,
                onLocationTap: () => locationTapped = true,
              ),
            ),
          ),
        );

        // Verify initials & name
        expect(find.text('JD'), findsOneWidget);
        expect(find.text('John'), findsOneWidget);
        expect(find.textContaining('Vinhomes Central Park'), findsOneWidget);

        // Tap on account avatar
        await tester.tap(find.text('JD'));
        await tester.pump();
        expect(accountTapped, isTrue);

        // Tap on notification bell
        await tester.tap(find.byIcon(LucideIcons.bell));
        await tester.pump();
        expect(notifTapped, isTrue);

        // Tap on location pill
        await tester.tap(find.textContaining('Vinhomes Central Park'));
        await tester.pump();
        expect(locationTapped, isTrue);
      },
    );

    testWidgets(
      'HomeActiveOrderBanner renders active order and triggers actions',
      (tester) async {
        bool cancelTapped = false;
        bool bannerTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeActiveOrderBanner(
                statusText: 'ĐANG GIAO',
                productName: '1× Nước Lavie 20L',
                progress: 0.5,
                onCancel: () => cancelTapped = true,
                onTap: () => bannerTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('ĐANG GIAO'), findsOneWidget);
        expect(find.text('1× Nước Lavie 20L'), findsOneWidget);
        expect(find.byType(FractionallySizedBox), findsOneWidget);

        // Tap cancel button
        final cancelBtn = find.text('Hủy đơn');
        expect(cancelBtn, findsOneWidget);
        await tester.tap(cancelBtn);
        await tester.pump();
        expect(cancelTapped, isTrue);

        // Tap banner card
        await tester.tap(find.text('1× Nước Lavie 20L'));
        await tester.pump();
        expect(bannerTapped, isTrue);
      },
    );

    testWidgets(
      'HomeSmartButtonsGrid displays empty state when devices list is empty',
      (tester) async {
        bool addDeviceTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeSmartButtonsGrid(
                devices: const [],
                isLoading: false,
                onManage: () {},
                onAddDevice: () => addDeviceTapped = true,
                onDeviceTap: (_) {},
                onDeviceOrder: (_) {},
                onDeviceSettings: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Nút bấm của tôi'), findsOneWidget);
        expect(find.text('Chưa có nút bấm nào'), findsOneWidget);

        final pairBtn = find.text('Thêm nút nhấn mới');
        expect(pairBtn, findsOneWidget);
        await tester.tap(pairBtn);
        await tester.pump();
        expect(addDeviceTapped, isTrue);
      },
    );

    testWidgets(
      'HomeSmartButtonsGrid displays devices and trigger order callback',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await ApiClient().setTokens(accessToken: 'test');
        ApiClient().testClient = MockClient(
          (request) async => http.Response(
            jsonEncode({
              'data': request.url.path.contains('/products/')
                  ? {
                      'status': 'ACTIVE',
                      'inventory': {
                        'quantityOnHand': 10,
                        'reservedQuantity': 0,
                      },
                    }
                  : {
                      'products': [
                        {'productId': '88', 'quantity': 1},
                      ],
                    },
            }),
            200,
          ),
        );
        addTearDown(() => ApiClient().testClient = http.Client());
        DeviceModel? orderedDevice;

        final testDevices = [
          const DeviceModel(
            id: 'dev-1',
            name: 'Nút Bếp',
            room: 'Phòng Bếp',
            product: 'Gas Petro 12kg',
            price: '450.000đ',
            battery: 88,
            status: DeviceStatus.online,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeSmartButtonsGrid(
                  devices: testDevices,
                  isLoading: false,
                  buttonStateMap: const {'dev-1': 'idle'},
                  onManage: () {},
                  onAddDevice: () {},
                  onDeviceTap: (_) {},
                  onDeviceOrder: (d) => orderedDevice = d,
                  onDeviceSettings: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('Nút Bếp'), findsOneWidget);
        expect(find.text('Gas Petro 12kg'), findsOneWidget);

        await tester.pumpAndSettle();
        // Tap order button
        final orderAction = find.text('Đặt ngay');
        expect(orderAction, findsOneWidget);
        await tester.tap(orderAction);
        await tester.pump();
        expect(orderedDevice?.id, equals('dev-1'));
      },
    );
  });

  group('Story 4.3 - OrdersScreen Modular Sub-Widgets Tests', () {
    testWidgets('OrderTabSelector renders and allows tab switching', (
      tester,
    ) async {
      final tabController = TabController(length: 2, vsync: const TestVSync());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderTabSelector(
              controller: tabController,
              activeCount: 3,
              historyCount: 12,
            ),
          ),
        ),
      );

      expect(find.text('Đang xử lý'), findsOneWidget);
      expect(find.text('Lịch sử'), findsOneWidget);

      await tester.tap(find.text('Lịch sử'));
      await tester.pumpAndSettle();
      expect(tabController.index, equals(1));
    });

    testWidgets(
      'OrderCardItem renders emergency pending order with countdown',
      (tester) async {
        bool cancelTapped = false;

        final pendingOrder = OrderModel(
          id: 'ord-pending-1',
          customerName: 'Nguyen Van A',
          apartment: 'Landmark 5',
          product: 'Gas Petro 12kg',
          title: '1× Gas Petro 12kg',
          deviceId: 'dev-1',
          buttonName: 'Nút Bếp',
          price: '450.000đ',
          time: 'Vừa xong',
          status: OrderStatus.warning,
          statusText: 'Đang chờ xử lý',
          rawStatus: 'PENDING',
          rawAmount: 450000,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OrderCardItem(
                order: pendingOrder,
                cancelCountdown: 42,
                onEmergencyCancel: () => cancelTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Chờ xác nhận'), findsOneWidget);
        expect(find.text('1× Gas Petro 12kg'), findsOneWidget);
        expect(find.text('Hủy đơn · 00:42'), findsOneWidget);

        await tester.tap(find.text('Hủy đơn · 00:42'));
        await tester.pump();
        expect(cancelTapped, isTrue);
      },
    );

    testWidgets('OrderCardItem renders live tracking order with timeline', (
      tester,
    ) async {
      bool trackTapped = false;
      bool cancelTapped = false;

      final shippingOrder = OrderModel(
        id: 'ord-shipping-1',
        customerName: 'Nguyen Van A',
        apartment: 'Landmark 5',
        product: 'Nước Lavie 20L',
        title: '1× Nước Lavie 20L',
        deviceId: 'dev-1',
        buttonName: 'Nút Phòng Khách',
        price: '65.000đ',
        time: '10 phút trước',
        status: OrderStatus.info,
        statusText: 'Đang giao hàng',
        rawStatus: 'SHIPPING',
        rawAmount: 65000,
        orderCode: '#SO-9921',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderCardItem(
              order: shippingOrder,
              onTrack: () => trackTapped = true,
              onCancel: () => cancelTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Đang giao'), findsOneWidget);
      expect(find.text('#SO-9921'), findsOneWidget);
      expect(find.text('Theo dõi đơn'), findsOneWidget);
      expect(find.textContaining('Hủy đơn'), findsNothing);

      await tester.tap(find.text('Theo dõi đơn'));
      await tester.pump();
      expect(trackTapped, isTrue);

      expect(cancelTapped, isFalse);
    });

    testWidgets(
      'OrderCardItem renders past order with reorder and detail buttons',
      (tester) async {
        bool detailTapped = false;
        bool reorderTapped = false;

        final pastOrder = OrderModel(
          id: 'ord-past-1',
          customerName: 'Nguyen Van A',
          apartment: 'Landmark 5',
          product: 'Đổi bình Gas Petrolimex',
          title: '2× Đổi bình Gas Petrolimex',
          deviceId: 'dev-1',
          buttonName: 'Nút Bếp',
          price: '900.000đ',
          time: '14:20 - 15/10/2026',
          status: OrderStatus.success,
          statusText: 'Đã hoàn tất',
          rawStatus: 'DELIVERED',
          rawAmount: 900000,
          orderCode: '#SO-7711',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OrderCardItem(
                order: pastOrder,
                onDetailTap: () => detailTapped = true,
                onReorder: () => reorderTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('2× Đổi bình Gas Petrolimex'), findsOneWidget);
        expect(find.text('Đã giao'), findsOneWidget);
        expect(find.text('Chi tiết'), findsOneWidget);
        expect(find.text('Đặt lại'), findsOneWidget);

        await tester.tap(find.text('Chi tiết'));
        await tester.pump();
        expect(detailTapped, isTrue);

        await tester.tap(find.text('Đặt lại'));
        await tester.pump();
        expect(reorderTapped, isTrue);
      },
    );

    testWidgets(
      'OrderDetailBottomSheet renders bottom sheet details and actions',
      (tester) async {
        bool reorderCalled = false;

        final testOrder = OrderModel(
          id: 'ord-sheet-1',
          customerName: 'Nguyen Van A',
          apartment: 'Landmark 5',
          product: 'Nước Lavie 20L',
          title: '1× Nước Lavie 20L',
          deviceId: 'dev-1',
          buttonName: 'Nút Bếp',
          price: '65.000đ',
          time: '12:00 - 18/10/2026',
          status: OrderStatus.success,
          statusText: 'Đã hoàn tất',
          rawStatus: 'DELIVERED',
          rawAmount: 65000,
          orderCode: '#SO-5544',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => OrderDetailBottomSheet.show(
                  ctx,
                  order: testOrder,
                  onReorder: () => reorderCalled = true,
                ),
                child: const Text('Mở chi tiết'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Mở chi tiết'));
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
        expect(find.text('#SO-5544'), findsOneWidget);
        expect(find.text('Tổng thanh toán'), findsOneWidget);
        expect(find.text('Đặt lại đơn này'), findsOneWidget);

        await tester.ensureVisible(find.text('Đặt lại đơn này'));
        await tester.tap(find.text('Đặt lại đơn này'));
        await tester.pumpAndSettle();
        expect(reorderCalled, isTrue);
      },
    );
  });

  group('Story 4.3 - Orchestrators Smoke Tests', () {
    testWidgets('HomeScreen renders without throwing', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(HomeHeaderCard), findsOneWidget);
    });

    testWidgets('OrdersScreen renders with tab selector and list views', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: OrdersScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OrdersScreen), findsOneWidget);
      expect(find.byType(OrderTabSelector), findsOneWidget);
      expect(find.text('Đơn hàng'), findsOneWidget);
    });
  });
}
