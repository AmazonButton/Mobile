import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/models/order_model.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/screens/devices_screen.dart';
import 'package:smart_order_button/screens/device_detail_screen.dart';
import 'package:smart_order_button/screens/orders_screen.dart';
import 'package:smart_order_button/screens/orders/widgets/order_card_item.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/stock_service.dart';
import 'package:smart_order_button/widgets/sample_a.dart';

class FixtureDevices extends DeviceProvider {
  FixtureDevices(List<DeviceModel> devices) : super(initialDevices: devices);
  @override
  Future<void> loadDevices() async {}
}

class FixtureOrders extends OrderProvider {
  FixtureOrders(List<OrderModel> orders) : super(initialOrders: orders);
  @override
  Future<void> loadOrders() async {}
}

const devices = [
  DeviceModel(
    id: '12',
    name: 'Nút Phòng khách',
    room: 'Phòng khách',
    product: 'Nước Lavie 20L',
    price: '65.000đ',
    battery: 85,
    status: DeviceStatus.online,
    wifiSsid: 'Home_Wifi',
  ),
  DeviceModel(
    id: '13',
    name: 'Nút Nhà bếp',
    room: 'Nhà bếp',
    product: 'Nước Lavie 20L',
    price: '65.000đ',
    battery: 18,
    status: DeviceStatus.offline,
  ),
];
OrderModel order(String status, String code, {String method = 'COD'}) =>
    OrderModel(
      id: code,
      orderCode: code,
      customerName: 'Nguyễn Minh Anh',
      apartment: 'Căn hộ 1204, Vinhomes Grand Park',
      product: 'Nước Lavie 20L',
      title: '1 × Nước Lavie 20L',
      buttonName: 'Nút Phòng khách',
      storeName: 'Cửa hàng An Nhiên',
      deviceId: '12',
      time: '14:20 · 27/10/2026',
      price: '65.000đ',
      rawAmount: 65000,
      rawStatus: status,
      status: OrderStatus.info,
      statusText: status,
      paymentMethod: method,
    );
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('SampleA Vietnam');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      loader.addFont(
        rootBundle.load('assets/sample_a/fonts/BeVietnamPro-$weight.ttf'),
      );
    }
    await loader.load();
    final icons = FontLoader('packages/lucide_icons_flutter/Lucide');
    icons.addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
    await icons.load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test');
    StockService.instance.configurations.clear();
    StockService.instance.stocks.clear();
    ApiClient().testClient = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'data': request.url.path.contains('/products/')
              ? {
                  'status': 'ACTIVE',
                  'inventory': {'quantityOnHand': 10, 'reservedQuantity': 0},
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
  });
  tearDown(() => ApiClient().testClient = http.Client());
  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    int tab = 1,
    double scale = 1,
    double width = 390,
    bool empty = false,
  }) async {
    tester.view.physicalSize = Size(width, width == 320 ? 640 : 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DeviceProvider>(
            create: (_) => FixtureDevices(empty ? [] : devices),
          ),
          ChangeNotifierProvider<OrderProvider>(
            create: (_) => FixtureOrders(
              empty
                  ? []
                  : [
                      order('SHIPPING', '#SO-1024'),
                      order('PENDING', '#SO-1025', method: 'PAYOS'),
                      order('DELIVERED', '#SO-1010'),
                      order('CANCELLED', '#SO-1008'),
                    ],
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            fontFamily: 'SampleA Vietnam',
            scaffoldBackgroundColor: Colors.white,
          ),
          builder: (context, child) => RepaintBoundary(
            key: const ValueKey('capture'),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
          home: RepaintBoundary(
            child: Scaffold(
              body: screen,
              bottomNavigationBar: SampleANavigation(
                selectedIndex: tab,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byKey(const ValueKey('capture')));
      await precacheImage(
        const AssetImage('assets/sample_a/water.png'),
        context,
      );
      await precacheImage(
        const AssetImage('assets/sample_a/buddy.png'),
        context,
      );
    });
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('audit/sample-a').create(recursive: true);
      await File(
        'audit/sample-a/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('Sample A devices filters use live states and capture', (
    tester,
  ) async {
    await mount(tester, const DevicesScreen());
    await capture(tester, 'devices');
    await tester.tap(find.text('Cần chú ý'));
    await tester.pumpAndSettle();
    expect(find.text('Nút Nhà bếp'), findsOneWidget);
    expect(find.text('Nút Phòng khách'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Sample A detail capture', (tester) async {
    await mount(tester, const DeviceDetailScreen(deviceId: '12'));
    await capture(tester, 'device-detail');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Orders tracking, history and detail are reachable', (
    tester,
  ) async {
    await mount(tester, const OrdersScreen(showBackButton: false), tab: 2);
    await capture(tester, 'orders-active');
    await tester.tap(find.text('Theo dõi đơn').first);
    await tester.pumpAndSettle();
    // Capture the modal route as well as the underlying application.
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('Đang giao'), findsWidgets);
    await capture(tester, 'order-detail');
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();
    await capture(tester, 'orders-history');
    expect(find.text('Đã giao'), findsOneWidget);
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Empty orders uses concise copy', (tester) async {
    await mount(
      tester,
      const OrdersScreen(showBackButton: false),
      tab: 2,
      empty: true,
    );
    await capture(tester, 'orders-empty');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Device list and orders fit 320px and 160 percent text', (
    tester,
  ) async {
    await mount(tester, const DevicesScreen(), width: 320, scale: 1.6);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -480));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await mount(
      tester,
      const OrdersScreen(showBackButton: false),
      tab: 2,
      width: 320,
      scale: 1.6,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Shipping PayOS status stays shipping and tracking works', (
    tester,
  ) async {
    var tracked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderCardItem(
            order: order('SHIPPING', '#SO-4', method: 'PAYOS'),
            onTrack: () => tracked = true,
          ),
        ),
      ),
    );
    expect(find.text('Đang giao'), findsOneWidget);
    expect(find.text('Chờ thanh toán'), findsNothing);
    await tester.tap(find.text('Theo dõi đơn'));
    expect(tracked, isTrue);
  });
}
