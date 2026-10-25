import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/order_model.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/payments_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<http.Request> requests;
  late OrderProvider provider;
  late dynamic orderResponse;
  int orderStatus = 200;
  int createdEvents = 0;
  http.Response response(dynamic data, int status) => http.Response(
    jsonEncode(data),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test-token');
    requests = [];
    createdEvents = 0;
    orderStatus = 200;
    orderResponse = {
      'success': true,
      'data': {
        'order': {
          'orderId': '321',
          'id': '321',
          'orderCode': 'ORD-9802',
          'orderNumber': 'ORD-9802',
          'orderStatus': 'PENDING',
          'paymentStatus': 'UNPAID',
          'totalAmount': 12000,
          'createdAt': DateTime.now().toIso8601String(),
          'items': [
            {'productName': 'Candy Sweet', 'quantity': 1},
          ],
        },
        'isDuplicate': false,
      },
    };
    provider = OrderProvider(initialOrders: []);
    OrderProvider.onOrderCreated = (_) {
      createdEvents++;
    };
    ApiClient().testClient = MockClient((request) async {
      requests.add(request);
      if (request.url.path.contains('/devices/')) {
        return response({
          'data': {
            'products': [
              {'productId': '88', 'quantity': 1},
            ],
          },
        }, 200);
      }
      if (request.url.path.contains('/products/')) {
        return response({
          'data': {
            'status': 'ACTIVE',
            'inventory': {'quantityOnHand': 10, 'reservedQuantity': 0},
          },
        }, 200);
      }
      if (request.url.path.endsWith('/quick-reorder')) {
        return response(orderResponse, orderStatus);
      }
      if (request.url.path.endsWith('/create-link')) {
        return response({
          'success': true,
          'data': {
            'orderCode': 123456,
            'amount': 12000,
            'paymentTransactionId': '555',
            'checkoutUrl': 'https://pay.payos.vn/web/test',
            'qrCode': 'test-qr',
          },
        }, 200);
      }
      throw StateError('Unexpected request');
    });
  });
  tearDown(() {
    provider.dispose();
    OrderProvider.onOrderCreated = null;
    ApiClient().testClient = http.Client();
  });
  Future<OrderModel?> create() => provider.createOneTouchOrder(
    deviceId: 'real-device',
    buttonName: 'Nút Candy',
    productName: 'Candy Sweet',
    productPrice: '12.000đ',
  );

  test(
    'One-touch order uses data.order ID through the PayOS request',
    () async {
      final order = (await create())!;
      expect(order.id, '321');
      expect(order.orderCode, 'ORD-9802');
      expect(provider.orders.single.id, '321');
      expect(createdEvents, 1);
      expect(order.isWithinSafetyWindow, true);
      final payment = await PaymentsApiService().createPayosPaymentLink(
        orderId: order.id,
      );
      expect(jsonDecode(requests.last.body)['orderId'], '321');
      expect(payment.amount, 12000);
      expect(payment.qrCode, 'test-qr');
    },
  );

  test('Real id takes precedence over display orderNumber', () {
    final order = OrderModel.fromJson({'id': '321', 'orderNumber': 'ORD-9802'});
    expect(order.id, '321');
    expect(order.orderCode, 'ORD-9802');
  });

  test(
    'API errors never create a local order or a success notification',
    () async {
      for (final status in [400, 401, 503]) {
        orderStatus = status;
        orderResponse = {'message': 'Không thể đặt hàng'};
        await expectLater(create(), throwsA(isA<ApiException>()));
        expect(provider.orders, isEmpty);
        expect(createdEvents, 0);
      }
    },
  );

  test('Malformed success response never fabricates a payable order', () async {
    for (final data in [
      {},
      {'order': {}},
      {
        'order': {'id': 'SOB-123'},
      },
    ]) {
      orderResponse = {'success': true, 'data': data};
      await expectLater(create(), throwsA(isA<ApiException>()));
      expect(provider.orders, isEmpty);
      expect(createdEvents, 0);
    }
  });

  test(
    'Local IDs are blocked before contacting PayOS and numeric IDs remain strings',
    () async {
      for (final id in ['SOB-1792769802', '#ORD-9802', '0', '']) {
        await expectLater(
          PaymentsApiService().createPayosPaymentLink(orderId: id),
          throwsA(isA<ApiException>()),
        );
      }
      expect(requests, isEmpty);
      await PaymentsApiService().createPayosPaymentLink(
        orderId: '9223372036854775807',
      );
      expect(jsonDecode(requests.last.body)['orderId'], '9223372036854775807');
    },
  );
}
