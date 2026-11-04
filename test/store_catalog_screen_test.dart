import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/models/button_product_model.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/screens/store_catalog_screen.dart';
import 'package:smart_order_button/services/api_client.dart';

class CatalogDevices extends DeviceProvider {
  String? assigned;
  @override
  List<DeviceModel> get devices => [
    DeviceModel.fromJson({'deviceId': 'mine', 'name': 'My button', 'storeId': '7'}),
    DeviceModel.fromJson({'deviceId': 'other', 'name': 'Other store button', 'storeId': '8'}),
  ];
  @override
  Future<void> loadDevices() async {}
  @override
  Future<void> updateDeviceProduct(String id, ButtonProductModel product, {int quantity = 1}) async { assigned = '$id:${product.id}:$quantity'; }
}

void main() {
  testWidgets('Catalog requests selected store and excludes foreign or inactive products', (tester) async {
    final devices = CatalogDevices();
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test');
    ApiClient().testClient = MockClient((request) async {
      expect(request.url.queryParameters['storeId'], '7');
      return http.Response(jsonEncode({'data': [
        {'productId': '1', 'storeId': '7', 'status': 'ACTIVE', 'name': 'Water', 'price': 30000},
        {'productId': '2', 'storeId': '7', 'status': 'ACTIVE', 'name': 'Rice', 'price': 50000},
        {'productId': '3', 'storeId': '8', 'status': 'ACTIVE', 'name': 'Foreign'},
        {'productId': '4', 'storeId': '7', 'status': 'INACTIVE', 'name': 'Hidden'},
      ]}), 200);
    });
    addTearDown(() => ApiClient().testClient = http.Client());
    await tester.pumpWidget(ChangeNotifierProvider<DeviceProvider>.value(value: devices, child: const MaterialApp(home: StoreCatalogScreen(store: {'storeId': '7', 'name': 'Shop'}))));
    await tester.pumpAndSettle();
    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Foreign'), findsNothing);
    expect(find.text('Hidden'), findsNothing);
    expect(find.text('2 sản phẩm'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Rice');
    await tester.pump();
    expect(find.text('Water'), findsNothing);
    expect(find.text('Rice', findRichText: false, skipOffstage: true), findsNWidgets(2));
    expect(find.text('1 sản phẩm'), findsOneWidget);
    expect(find.text('Chọn địa chỉ giao hàng'), findsNothing);
    await tester.tap(find.byTooltip('Thêm vào nút bấm'));
    await tester.pumpAndSettle();
    expect(find.text('My button'), findsOneWidget);
    expect(find.text('Other store button'), findsNothing);
    await tester.tap(find.text('My button'));
    await tester.pumpAndSettle();
    expect(devices.assigned, 'mine:2:1');
  });
}
