import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/providers/address_provider.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/providers/notification_provider.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/providers/user_provider.dart';
import 'package:smart_order_button/screens/login_screen.dart';
import 'package:smart_order_button/screens/main_layout.dart';
import 'package:smart_order_button/screens/welcome_screen.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/widgets/app_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'smartorder.spotlight.v1.1': true,
    });
    await ApiClient().setTokens(accessToken: 'test-token');
    ApiClient().testClient = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/auth/me')) {
        return http.Response(jsonEncode({'data': {}}), 200);
      }
      if (path.endsWith('/store/wallet')) {
        return http.Response(
          jsonEncode({
            'data': {'balance': 1250000, 'frozenBalance': 50000},
          }),
          200,
        );
      }
      if (path.endsWith('/devices/fleet/stats')) {
        return http.Response(
          jsonEncode({
            'data': {
              'total': 78,
              'activeDevices': 35,
              'lowBatteryDevices': 2,
              'unassignedDevices': 40,
            },
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'data': [],
          'pagination': {'page': 1, 'totalPages': 1, 'totalItems': 0},
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
  });

  tearDown(() => ApiClient().testClient = http.Client());

  Widget buildShellWithRole(Map<String, dynamic> loginUser) {
    final userProv = UserProvider()..applyLoginUser(loginUser);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: userProv),
        ChangeNotifierProvider<DeviceProvider>(
          create: (_) => DeviceProvider(initialDevices: const []),
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(initialOrders: const []),
        ),
        ChangeNotifierProvider<AddressProvider>(
          create: (_) => AddressProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: const MaterialApp(home: MainLayout()),
    );
  }

  group('Strict 4-Role Workspace Separation', () {
    testWidgets('CUSTOMER gets 4-tab shopping shell without Store/Admin tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildShellWithRole({'id': '1', 'role': 'CUSTOMER', 'fullName': 'Lan'}),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Hôm nay nhà mình cần gì?'), findsOneWidget);
      expect(find.text('Mua sắm'), findsOneWidget);
      expect(find.text('Thuê nút bấm'), findsOneWidget);
      expect(find.text('Ví quán'), findsNothing);
      expect(find.text('Kho nút'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'STORE_OWNER gets 5-tab Merchant shell and never shows Customer home',
      (tester) async {
        await tester.pumpWidget(
          buildShellWithRole({
            'id': '2',
            'role': 'STORE_OWNER',
            'storeId': '2',
            'fullName': 'Lê Minh Khôi',
            'store': {
              'storeId': '2',
              'name': 'Minh Khôi Mart',
              'address': '88 Song Hành, Thủ Đức',
            },
          }),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tổng quan'), findsOneWidget);
        expect(find.text('Sản phẩm'), findsWidgets);
        expect(find.text('Nút IoT'), findsWidgets);
        expect(find.text('Ví quán'), findsOneWidget);
        expect(find.text('Số dư ví khả dụng'), findsOneWidget);
        // Must NEVER bleed customer copy
        expect(find.text('Hôm nay nhà mình cần gì?'), findsNothing);
        expect(find.text('Thuê nút bấm'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('SYSTEM_STAFF gets 5-tab Technical Operations shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildShellWithRole({
          'id': '889',
          'role': 'SYSTEM_STAFF',
          'fullName': 'Trần Kỹ Thuật',
        }),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vận hành thiết bị IoT'), findsOneWidget);
      expect(find.text('Kho nút'), findsWidgets);
      expect(find.text('Bảo hành'), findsWidgets);
      expect(find.text('Thu hồi'), findsWidgets);
      expect(find.text('Hôm nay nhà mình cần gì?'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SUPER_ADMIN gets 5-tab Platform Governance shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildShellWithRole({
          'id': '1',
          'role': 'SUPER_ADMIN',
          'fullName': 'Admin',
        }),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trung tâm điều hành'), findsOneWidget);
      expect(find.text('Cửa hàng'), findsWidgets);
      expect(find.text('Kho nút'), findsWidgets);
      expect(find.text('Đơn hàng'), findsWidgets);
      expect(find.text('Hôm nay nhà mình cần gì?'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'LoginScreen quick-login Chủ quán authenticates minhkhoi@smartorder.local (real STORE_OWNER)',
      (tester) async {
        String? postedEmail;
        ApiClient().testClient = MockClient((request) async {
          if (request.url.path.contains('/auth/login')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            postedEmail = body['email']?.toString();
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'token': 'store-jwt',
                  'refreshToken': 'store-refresh',
                  'user': {
                    'id': '2',
                    'email': 'minhkhoi@smartorder.local',
                    'fullName': 'Lê Minh Khôi',
                    'role': 'STORE_OWNER',
                    'storeId': '2',
                  },
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(jsonEncode({'data': []}), 200);
        });

        final userProv = UserProvider();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProvider>.value(value: userProv),
              ChangeNotifierProvider<DeviceProvider>(
                create: (_) => DeviceProvider(initialDevices: const []),
              ),
              ChangeNotifierProvider<OrderProvider>(
                create: (_) => OrderProvider(initialOrders: const []),
              ),
              ChangeNotifierProvider<AddressProvider>(
                create: (_) => AddressProvider(),
              ),
              ChangeNotifierProvider<NotificationProvider>(
                create: (_) => NotificationProvider(),
              ),
            ],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Chủ quán'));
        await tester.tap(find.text('Chủ quán'));
        await tester.pumpAndSettle();

        expect(postedEmail, 'minhkhoi@smartorder.local');
        expect(userProv.isStoreOwner, isTrue);
        expect(userProv.isCustomer, isFalse);
      },
    );
  });

  group('Slide Transitions & Interactive Decks', () {
    testWidgets(
      'AppAnimatedTabBody slides directionally and survives rapid tab switches',
      (tester) async {
        await tester.pumpWidget(
          buildShellWithRole({
            'id': '1',
            'role': 'CUSTOMER',
            'fullName': 'Lan',
          }),
        );
        await tester.pumpAndSettle();

        // Jump right: Home (0) -> Orders (2)
        await tester.tap(
          find.descendant(
            of: find.byType(AppFloatingNavBar),
            matching: find.text('Đơn hàng'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 90));
        // Rapidly jump again mid-flight: Orders (2) -> Profile (3) -> Home (0)
        await tester.tap(
          find.descendant(
            of: find.byType(AppFloatingNavBar),
            matching: find.text('Tài khoản'),
          ),
        );
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(
          find.descendant(
            of: find.byType(AppFloatingNavBar),
            matching: find.text('Trang chủ'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hôm nay nhà mình cần gì?'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'WelcomeScreen onboarding slide deck updates mascot message via dots',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Xin chào! Mình sẽ đồng hành cùng bạn.'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('slideDot_1')));
        await tester.pumpAndSettle();
        expect(find.text('Ghép Bluetooth và nạp Wi-Fi cực nhanh!'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('slideDot_2')));
        await tester.pumpAndSettle();
        expect(find.text('An tâm tuyệt đối, bấm là giao ngay!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Customer Home HeroSlideDeck switches slides cleanly on pagination dot tap',
      (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildShellWithRole({
            'id': '1',
            'role': 'CUSTOMER',
            'fullName': 'Lan',
          }),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HeroSlideDeck), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('slideDot_1')));
        await tester.pumpAndSettle();
        expect(find.text('Xem gói thuê'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('slideDot_2')));
        await tester.pumpAndSettle();
        expect(find.text('Chọn đại lý'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
