import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/screens/customer_buttons_screen.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/stock_service.dart';
import 'package:smart_order_button/services/customer_buttons_api_service.dart';
import 'package:smart_order_button/services/devices_api_service.dart';

http.Response _response(String body, int status) => http.Response(
  body,
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  late ApiClient api;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = ApiClient();
    await api.setTokens(accessToken: 'test-only');
  });
  tearDown(() => api.testClient = http.Client());

  test('F10: server restriction survives parsing and copyWith', () {
    final device = DeviceModel.fromJson({
      'deviceId': '42',
      'canOrder': false,
      'inventoryState': 'RETURN_IN_TRANSIT',
      'rentalId': '7',
    });
    expect(device.orderRestriction, 'Nút đang chờ cửa hàng nhận lại');
    expect(device.copyWith(name: 'New name').canOrder, isFalse);
    expect(device.copyWith(name: 'New name').rentalId, '7');
    expect(DeviceModel.fromJson({'canOrder': true}).orderRestriction, isNull);
  });

  test(
    'F10: legacy device response is enriched from the customer contract',
    () async {
      api.testClient = MockClient((request) async {
        if (request.url.path.endsWith('/rentals/my-rentals')) {
          return _response(
            jsonEncode({
              'data': [
                {
                  'rentalId': '7',
                  'status': 'PENDING_HANDOVER',
                  'depositAmount': 100000,
                  'canOrder': false,
                  'buttons': [
                    {'buttonId': '42', 'name': 'Button'},
                  ],
                },
              ],
            }),
            200,
          );
        }
        return _response(
          jsonEncode({
            'data': {'buttonId': '42', 'deviceId': 'ESP-42', 'products': []},
          }),
          200,
        );
      });
      final device = await DevicesApiService().getDeviceModelById('ESP-42');
      expect(device.canOrder, isFalse);
      expect(device.orderRestriction, 'Nút chưa được bàn giao');
    },
  );

  test(
    'F10: cannot place an order for a returned button even with enough stock',
    () async {
      api.testClient = MockClient(
        (request) async => _response(
          jsonEncode({
            'data': {
              'deviceId': 'returned-test',
              'canOrder': false,
              'inventoryState': 'RETURN_IN_TRANSIT',
              'products': [
                {'productId': '10', 'quantity': 1},
              ],
            },
          }),
          200,
        ),
      );
      await expectLater(
        StockService.instance.verify('returned-test'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('chờ cửa hàng nhận lại'),
          ),
        ),
      );
    },
  );

  testWidgets(
    'F06: customer sees deposit, no rental fee or renewal, return request does not report refund',
    (tester) async {
      var returnRequests = 0;
      api.testClient = MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.path, endsWith('/rentals/my-rentals'));
          return _response(
            jsonEncode({
              'data': [
                {
                  'rentalId': '7',
                  'rentalCode': 'RNT-7',
                  'status': 'ACTIVE',
                  'depositAmount': 100000,
                  'totalRentAmount': 150000,
                  'buttons': [
                    {'buttonId': '42', 'name': 'Nút Bếp', 'status': 'ACTIVE'},
                  ],
                },
              ],
            }),
            200,
          );
        }
        expect(request.url.path, endsWith('/rentals/7/return-requests'));
        expect(jsonDecode(request.body), {'buttonId': '42'});
        returnRequests++;
        return _response(
          jsonEncode({
            'data': {'returnId': '8', 'status': 'PENDING_RECEIPT'},
          }),
          200,
        );
      });
      expect(await CustomerButtonsApiService().getMyButtons(), hasLength(1));
      await tester.pumpWidget(const MaterialApp(home: CustomerButtonsScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('100.000'), findsOneWidget);
      expect(find.textContaining('150.000'), findsNothing);
      expect(find.text('Gia hạn'), findsNothing);
      await tester.tap(find.byTooltip('Làm mới'));
      await tester.pumpAndSettle();
      expect(find.textContaining('100.000'), findsOneWidget);
      await tester.tap(find.text('Trả nút'));
      await tester.pumpAndSettle();
      expect(returnRequests, 0);
      expect(find.textContaining('Tiền cọc chỉ được hoàn sau'), findsOneWidget);
      await tester.tap(find.text('Gửi yêu cầu'));
      await tester.pumpAndSettle();
      expect(returnRequests, 1);
      expect(
        find.text('Đã gửi yêu cầu — chờ cửa hàng nhận lại'),
        findsOneWidget,
      );
      expect(find.text('Đã hoàn cọc'), findsNothing);
    },
  );

  testWidgets('F06: failed return request does not advance the button status', (
    tester,
  ) async {
    api.testClient = MockClient(
      (request) async => request.method == 'GET'
          ? _response(
              jsonEncode({
                'data': [
                  {
                    'rentalId': '7',
                    'status': 'ACTIVE',
                    'depositAmount': 100000,
                    'buttons': [
                      {'buttonId': '42', 'name': 'Nút Bếp'},
                    ],
                  },
                ],
              }),
              200,
            )
          : _response(jsonEncode({'message': 'Không thể nhận yêu cầu'}), 400),
    );
    await tester.pumpWidget(const MaterialApp(home: CustomerButtonsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trả nút'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pumpAndSettle();
    expect(find.text('Không thể nhận yêu cầu'), findsOneWidget);
    expect(find.text('Đã gửi yêu cầu — chờ cửa hàng nhận lại'), findsNothing);
  });
}
