import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/stores_api_service.dart';
import 'package:smart_order_button/widgets/modals/store_selection_sheet.dart';
import 'package:smart_order_button/widgets/modals/product_selection_sheet.dart';
import 'package:smart_order_button/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> device;
  late DeviceProvider provider;
  late List<http.Request> requests;
  bool failLoad = false;
  bool failSave = false;
  bool expiredSession = false;
  bool expireOnSave = false;
  Completer<void>? pendingSave;

  http.Response response(dynamic data, {int status = 200}) => http.Response(
    jsonEncode(
      status == 200 ? {'success': true, 'data': data} : {'message': data},
    ),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test-token');
    device = {
      'buttonId': '12',
      'deviceId': '12',
      'buttonName': 'Nút bếp',
      'storeId': '7',
      'store': {'name': 'Cửa hàng cũ'},
      'products': [
        {'productId': '1', 'productName': 'Candy cũ', 'price': 12000},
      ],
      'batteryLevel': 85,
    };
    requests = [];
    failLoad = false;
    failSave = false;
    expiredSession = false;
    expireOnSave = false;
    pendingSave = null;
    provider = DeviceProvider(initialDevices: [DeviceModel.fromJson(device)]);
    ApiClient().testClient = MockClient((request) async {
      requests.add(request);
      if (request.method == 'PUT') {
        if (expireOnSave) return response('Unauthorized', status: 401);
        if (pendingSave != null) await pendingSave!.future;
        if (failSave) {
          return response('Cửa hàng đã ngừng hoạt động', status: 400);
        }
        final body = jsonDecode(request.body);
        expect(body, {'storeId': '8'});
        device = {
          ...device,
          'storeId': '8',
          'store': {'name': 'Cửa hàng mới'},
          'products': [],
        };
        return response(device);
      }
      if (request.url.path.endsWith('/stores')) {
        if (failLoad) return response('Unavailable', status: 503);
        final page = request.url.queryParameters['page'];
        return response({
          'items': page == '2'
              ? [
                  {
                    'storeId': '8',
                    'name': 'Cửa hàng mới',
                    'status': 'ACTIVE',
                    'address': 'Quận 1',
                  },
                ]
              : [
                  {'storeId': '7', 'name': 'Cửa hàng cũ', 'status': 'ACTIVE'},
                  {'storeId': '9', 'name': 'Đã đóng cửa', 'status': 'INACTIVE'},
                ],
          'totalPages': 2,
        });
      }
      if (request.url.path.endsWith('/products')) {
        return response([
          {
            'productId': '88',
            'productName': 'Candy mới',
            'storeId': '8',
            'status': 'ACTIVE',
            'category': 'Bánh kẹo',
            'basePrice': 15000,
          },
        ]);
      }
      if (expiredSession) return response('Unauthorized', status: 401);
      return response(device);
    });
  });
  tearDown(() {
    provider.dispose();
    ApiClient().testClient = http.Client();
  });

  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(500, 950),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => StoreSelectionSheet.show(
                    context: context,
                    deviceId: '12',
                    onSave: (id) => provider.updateDeviceStore('12', id),
                  ),
                  child: const Text('Open store'),
                ),
                TextButton(
                  onPressed: () => ProductSelectionSheet.show(
                    context: context,
                    deviceId: '12',
                    buttonName: 'Nút bếp',
                    currentProductName: provider.devices.single.product,
                    onSave: (_, _) {},
                  ),
                  child: const Text('Open products'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open store'));
    await tester.pumpAndSettle();
  }

  test(
    'Store API reads the paginated items envelope and remaining pages',
    () async {
      final stores = await StoresApiService().getStores();
      expect(stores.map((s) => s['storeId']), ['7', '9', '8']);
      expect(requests.length, 2);
      expect(requests.last.url.queryParameters['page'], '2');
    },
  );

  testWidgets('Expired session explains login requirement and opens login', (
    tester,
  ) async {
    expiredSession = true;
    await open(tester);
    expect(find.textContaining('Phiên đăng nhập đã hết hạn'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Đăng nhập lại'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);
  });

  testWidgets('Session expiring during save keeps mapping and offers login', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Cửa hàng mới'));
    await tester.pump();
    expireOnSave = true;
    await tester.tap(find.text('Lưu cửa hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập lại'), findsOneWidget);
    expect(provider.devices.single.storeId, '7');
    expect(provider.devices.single.product, 'Candy cũ');
  });

  testWidgets('Sheet fits a small phone without horizontal overflow', (
    tester,
  ) async {
    await open(tester, size: const Size(320, 700));
    expect(tester.takeException(), isNull);
    final close = tester.getRect(find.byIcon(Icons.close));
    expect(close.right, lessThanOrEqualTo(320));
    expect(
      tester.getRect(find.byType(TextField)).right,
      lessThanOrEqualTo(320),
    );
  });

  testWidgets(
    'Shows current store, filters inactive stores, searches and disables unchanged save',
    (tester) async {
      await open(tester);
      expect(find.text('Cửa hàng hiện tại'), findsOneWidget);
      expect(find.text('Đã đóng cửa'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'Quận 1');
      await tester.pumpAndSettle();
      expect(find.text('Cửa hàng cũ'), findsNothing);
      expect(find.text('Cửa hàng mới'), findsOneWidget);
      expect(find.textContaining('bỏ sản phẩm đang gán'), findsOneWidget);
    },
  );

  testWidgets(
    'Successful change clears old mapping and loads the new store catalog',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Cửa hàng mới'));
      await tester.pump();
      pendingSave = Completer<void>();
      await tester.tap(find.text('Lưu cửa hàng'));
      await tester.pump();
      expect(find.text('Đang đổi cửa hàng...'), findsOneWidget);
      expect(provider.devices.single.storeId, '7');
      pendingSave!.complete();
      await tester.pumpAndSettle();
      expect(provider.devices.single.storeId, '8');
      expect(provider.devices.single.storeName, 'Cửa hàng mới');
      expect(provider.devices.single.product, 'Chưa gán sản phẩm');
      expect(provider.devices.single.price, '');
      expect(find.byType(StoreSelectionSheet), findsNothing);
      await tester.tap(find.text('Open products'));
      await tester.pumpAndSettle();
      expect(requests.last.url.queryParameters['storeId'], '8');
      expect(find.text('Candy mới'), findsOneWidget);
      expect(find.text('Candy cũ'), findsNothing);
    },
  );

  testWidgets('Failed save keeps original store/product and permits retry', (
    tester,
  ) async {
    failSave = true;
    await open(tester);
    await tester.tap(find.text('Cửa hàng mới'));
    await tester.pump();
    await tester.tap(find.text('Lưu cửa hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Cửa hàng đã ngừng hoạt động'), findsOneWidget);
    expect(provider.devices.single.storeId, '7');
    expect(provider.devices.single.product, 'Candy cũ');
    failSave = false;
    await tester.tap(find.text('Lưu cửa hàng'));
    await tester.pumpAndSettle();
    expect(provider.devices.single.storeId, '8');
  });

  testWidgets('Catalog load can retry and closing does not change the device', (
    tester,
  ) async {
    failLoad = true;
    await open(tester);
    expect(find.text('Thử lại'), findsOneWidget);
    failLoad = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cửa hàng mới'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(provider.devices.single.storeId, '7');
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);
  });
}
