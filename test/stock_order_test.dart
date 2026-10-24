import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/product_stock.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/orders_api_service.dart';
import 'package:smart_order_button/services/stock_service.dart';
import 'package:smart_order_button/providers/order_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dynamic inventory;
  late int quantity;
  late int posts;
  late bool networkFails;
  late bool rejects;
  Completer<http.Response>? pending;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test');
    StockService.instance.stocks.clear();
    StockService.instance.configurations.clear();
    inventory = {
      'quantityOnHand': 5,
      'reservedQuantity': 2,
      'minStockAlert': 3,
    };
    quantity = 3;
    posts = 0;
    networkFails = false;
    rejects = false;
    pending = null;
    ApiClient().testClient = MockClient((request) async {
      if (request.method == 'POST') {
        posts++;
        if (pending != null) return pending!.future;
        return http.Response(
          jsonEncode(
            rejects
                ? {'message': 'Không đủ tồn kho'}
                : {
                    'success': true,
                    'data': {
                      'order': {'orderId': '1'},
                    },
                  },
          ),
          rejects ? 400 : 200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (networkFails) throw Exception('Offline');
      final data = request.url.path.contains('/products/')
          ? {'productId': '7', 'status': 'ACTIVE', 'inventory': inventory}
          : {
              'deviceId': 'd',
              'products': [
                {'productId': '7', 'quantity': quantity, 'productName': 'Gạo'},
              ],
            };
      return http.Response(
        jsonEncode({'success': true, 'data': data}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
  });
  tearDown(() {
    ApiClient().testClient = http.Client();
    OrderProvider.onOrderCreated = null;
  });
  test('Stock boundary, reserved stock, threshold and missing data', () {
    expect(ProductStock.fromJson(inventory)!.label(), 'Sắp hết · Còn 3');
    expect(ProductStock.fromJson(inventory)!.label(4), 'Còn 3, cần 4');
    expect(
      ProductStock.fromJson({
        'quantityOnHand': 1,
        'reservedQuantity': 2,
      })!.label(),
      'Hết hàng',
    );
    expect(
      ProductStock.fromJson({
        'quantityOnHand': 6,
        'reservedQuantity': 0,
      })!.label(),
      'Còn 6 sản phẩm',
    );
    expect(ProductStock.fromJson(null), isNull);
    expect(ProductStock.fromJson({'quantityOnHand': 1}), isNull);
  });
  test('Exact available quantity submits once', () async {
    await OrdersApiService().quickReorder(deviceId: 'd');
    expect(posts, 1);
  });
  for (final scenario in [
    'empty',
    'excess',
    'missing',
    'network',
    'zero',
    'negative',
  ]) {
    test('$scenario blocks both reorder and home before POST', () async {
      if (scenario == 'empty') inventory['quantityOnHand'] = 2;
      if (scenario == 'excess') quantity = 4;
      if (scenario == 'missing') inventory = null;
      if (scenario == 'network') networkFails = true;
      if (scenario == 'zero') quantity = 0;
      if (scenario == 'negative') quantity = -1;
      final provider = OrderProvider();
      await expectLater(
        provider.quickReorder('d'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        provider.createOneTouchOrder(
          deviceId: 'd',
          buttonName: 'Nút',
          productName: 'Gạo',
          productPrice: '10000',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(posts, 0);
      provider.dispose();
    });
  }
  test(
    'Server rejection is propagated without retry or success callback',
    () async {
      rejects = true;
      final provider = OrderProvider();
      var created = false;
      OrderProvider.onOrderCreated = (_) => created = true;
      await expectLater(
        provider.createOneTouchOrder(
          deviceId: 'd',
          buttonName: 'Nút',
          productName: 'Gạo',
          productPrice: '10000',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(posts, 1);
      expect(created, isFalse);
      provider.dispose();
    },
  );
  test('Concurrent taps submit only one request', () async {
    pending = Completer<http.Response>();
    final first = OrdersApiService().quickReorder(deviceId: 'd');
    await Future<void>.delayed(Duration.zero);
    await expectLater(
      OrdersApiService().quickReorder(deviceId: 'd'),
      throwsA(isA<ApiException>()),
    );
    pending!.complete(
      http.Response(jsonEncode({'success': true, 'data': {}}), 200),
    );
    await first;
    expect(posts, 1);
  });
}
