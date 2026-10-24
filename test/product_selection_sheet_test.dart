import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/button_product_model.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/products_api_service.dart';
import 'package:smart_order_button/widgets/modals/product_selection_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Map<String, dynamic>> products;
  late List<http.Request> requests;
  int configuredQuantity = 1;
  bool loadFails = false;
  bool saveFails = false;
  Completer<http.Response>? pendingSave;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test-token');
    requests = [];
    products = [
      {
        'productId': '88',
        'productName': 'Candy',
        'basePrice': '12000.00',
        'storeId': '7',
        'status': 'ACTIVE',
        'inventory': {
          'quantityOnHand': 10,
          'reservedQuantity': 0,
          'minStockAlert': 5,
        },
        'category': {'categoryName': 'Bánh kẹo'},
      },
      {
        'productId': '89',
        'productName': 'Nước Lavie 20L',
        'basePrice': 65000,
        'storeId': '7',
        'status': 'ACTIVE',
        'inventory': {
          'quantityOnHand': 10,
          'reservedQuantity': 0,
          'minStockAlert': 5,
        },
        'category': {'categoryName': 'Nước uống'},
      },
      {
        'productId': '90',
        'productName': 'Other store',
        'storeId': '8',
        'status': 'ACTIVE',
        'inventory': {
          'quantityOnHand': 10,
          'reservedQuantity': 0,
          'minStockAlert': 5,
        },
      },
      {
        'productId': '91',
        'productName': 'Inactive candy',
        'storeId': '7',
        'status': 'INACTIVE',
      },
    ];
    configuredQuantity = 1;
    loadFails = false;
    saveFails = false;
    pendingSave = null;
    ApiClient().testClient = MockClient((request) async {
      requests.add(request);
      if (request.method == 'PUT') {
        if (pendingSave != null) return pendingSave!.future;
        if (saveFails) {
          return http.Response(
            jsonEncode({'message': 'Không thể gán sản phẩm'}),
            400,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        final body = jsonDecode(request.body);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'deviceId': '12',
              'products': [
                {
                  'productId': body['productId'],
                  'productName': 'Candy',
                  'quantity': body['quantity'],
                },
              ],
            },
          }),
          200,
        );
      }
      if (loadFails) {
        return http.Response(jsonEncode({'message': 'Unavailable'}), 503);
      }
      return http.Response(
        jsonEncode({
          'success': true,
          'data': request.url.path.endsWith('/products')
              ? products
              : {
                  'buttonId': '12',
                  'storeId': '7',
                  'products': [
                    {'productId': '89', 'quantity': configuredQuantity},
                  ],
                },
        }),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
  });
  tearDown(() => ApiClient().testClient = http.Client());

  Future<void> open(
    WidgetTester tester, {
    FutureOr<void> Function(ButtonProductModel, int)? onSave,
  }) async {
    tester.view.physicalSize = const Size(500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProductSelectionSheet.show(
                context: context,
                deviceId: '12',
                buttonName: 'Nút Nước Lavie Bếp Ăn E2E',
                currentProductName: 'Lavie',
                onSave: onSave ?? (_, _) {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Loads Candy from API for the button store, with real categories and prices',
    (tester) async {
      ButtonProductModel? saved;
      final apiProducts = await ProductsApiService().getProducts(storeId: '7');
      expect(apiProducts.length, 4, reason: 'Decode the API catalog');
      await open(
        tester,
        onSave: (p, quantity) {
          saved = p;
        },
      );
      expect(requests.last.url.queryParameters['storeId'], '7');
      expect(find.text('Candy'), findsOneWidget);
      expect(find.text('12.000đ'), findsOneWidget);
      expect(find.text('Bánh kẹo'), findsOneWidget);
      expect(find.text('Other store'), findsNothing);
      expect(find.text('Inactive candy'), findsNothing);
      expect(find.text('Nước giặt OMO 3.6kg'), findsNothing);
      await tester.enterText(find.byType(TextField), 'candy');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Candy'));
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(saved!.id, '88');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Filters using actual category instead of water/gas guesses', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Bánh kẹo'));
    await tester.pumpAndSettle();
    expect(find.text('Candy'), findsOneWidget);
    expect(find.text('65.000đ'), findsOneWidget); // Selected-item summary only.
    expect(find.text('Nước Lavie 20L'), findsOneWidget);
  });

  testWidgets('Empty catalog does not fall back to samples or allow saving', (
    tester,
  ) async {
    products = [];
    bool saved = false;
    await open(
      tester,
      onSave: (_, _) {
        saved = true;
      },
    );
    expect(find.text('Cửa hàng chưa có sản phẩm đang bán'), findsOneWidget);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(saved, false);
    expect(find.byType(ProductSelectionSheet), findsOneWidget);
  });

  testWidgets('Catalog errors show retry and reload from the API', (
    tester,
  ) async {
    loadFails = true;
    await open(tester);
    expect(find.text('Thử lại'), findsOneWidget);
    loadFails = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Candy'), findsOneWidget);
  });

  testWidgets(
    'Saving waits for API, keeps old state on failure, then retries',
    (tester) async {
      final provider = DeviceProvider(
        initialDevices: [
          const DeviceModel(
            id: '12',
            room: 'Bếp',
            product: 'Lavie',
            battery: 85,
            status: DeviceStatus.online,
          ),
        ],
      );
      await open(
        tester,
        onSave: (p, quantity) =>
            provider.updateDeviceProduct('12', p, quantity: quantity),
      );
      await tester.tap(find.text('Candy'));
      pendingSave = Completer<http.Response>();
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pump();
      expect(find.text('Đang lưu...'), findsOneWidget);
      expect(provider.devices.single.product, 'Lavie');
      pendingSave!.complete(
        http.Response(
          jsonEncode({'message': 'Không thể gán sản phẩm'}),
          400,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không thể gán sản phẩm'), findsOneWidget);
      expect(find.byType(ProductSelectionSheet), findsOneWidget);
      expect(provider.devices.single.product, 'Lavie');
      pendingSave = null;
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(provider.devices.single.product, 'Candy');
      expect(
        jsonDecode(
          requests.lastWhere((r) => r.method == 'PUT').body,
        )['productId'],
        '88',
      );
      expect(
        jsonDecode(
          requests.lastWhere((r) => r.method == 'PUT').body,
        )['quantity'],
        1,
      );
      expect(find.byType(ProductSelectionSheet), findsNothing);
    },
  );

  test(
    'Maps category strings and decimal prices without fake price defaults',
    () {
      final product = ButtonProductModel.fromJson({
        'productId': '88',
        'productName': 'Candy',
        'basePrice': '12500.00',
        'category': 'Bánh kẹo',
      });
      expect(product.price, 12500);
      expect(product.category, 'Bánh kẹo');
    },
  );
  testWidgets('Selected quantity is returned on save', (tester) async {
    int? savedQuantity;
    await open(
      tester,
      onSave: (_, q) {
        savedQuantity = q;
      },
    );
    await tester.tap(find.byTooltip('Tăng số lượng'));
    await tester.pump();
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(savedQuantity, 2);
  });
  testWidgets('Out of stock and missing inventory cannot be newly selected', (
    tester,
  ) async {
    products[0]['inventory'] = {'quantityOnHand': 0, 'reservedQuantity': 0};
    products[1].remove('inventory');
    var saved = false;
    await open(
      tester,
      onSave: (_, _) {
        saved = true;
      },
    );
    expect(find.text('Hết hàng'), findsOneWidget);
    await tester.tap(find.text('Candy'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
    expect(saved, isFalse);
  });

  testWidgets(
    'Saved quantity above current stock is retained and requires adjustment',
    (tester) async {
      configuredQuantity = 3;
      products[1]['inventory'] = {'quantityOnHand': 2, 'reservedQuantity': 0};
      int? saved;
      await open(
        tester,
        onSave: (_, q) {
          saved = q;
        },
      );
      expect(find.text('Còn 2, cần 3'), findsOneWidget);
      await tester.tap(find.text('Lưu thay đổi'));
      expect(saved, isNull);
      await tester.tap(find.byTooltip('Giảm số lượng'));
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Tăng số lượng',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(saved, 2);
    },
  );
  testWidgets('Changing product resets quantity and minimum is one', (
    tester,
  ) async {
    configuredQuantity = 3;
    int? saved;
    await open(
      tester,
      onSave: (_, q) {
        saved = q;
      },
    );
    await tester.tap(find.text('Candy'));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Giảm số lượng',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(saved, 1);
  });
  testWidgets('Failed refresh blocks saving stale stock', (tester) async {
    var saved = false;
    await open(
      tester,
      onSave: (_, _) {
        saved = true;
      },
    );
    loadFails = true;
    await tester.tap(find.text('Kiểm tra lại tồn kho'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu thay đổi'));
    expect(saved, isFalse);
  });
}
