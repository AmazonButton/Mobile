import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/screens/device_detail_screen.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/widgets/modals/product_selection_sheet.dart';
import 'package:smart_order_button/widgets/modals/wifi_provisioning_sheet.dart';

void main() {
  late DeviceProvider provider;
  late Map<String, dynamic> device;
  http.Response response(dynamic data) => http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test-token');
    device = {
      'deviceId': '12',
      'buttonName': 'Nút Nước Lavie Bếp Ăn E2E',
      'roomLocation': 'Kho trung tâm',
      'storeId': '7',
      'store': {'name': 'LêBảoStore'},
      'wifiSsid': 'Kitchen_Wifi',
      'batteryLevel': 100,
      'products': [
        {'productId': '88', 'productName': 'Candy Sweet', 'price': 2000},
      ],
    };
    provider = DeviceProvider(initialDevices: [DeviceModel.fromJson(device)]);
    ApiClient().testClient = MockClient((request) async {
      if (request.method == 'PUT') {
        device = {
          ...device,
          'storeId': '8',
          'store': {'name': 'Cửa hàng mới'},
          'products': [],
        };
        return response(device);
      }
      if (request.url.path.endsWith('/stores')) {
        return response([
          {'storeId': '7', 'name': 'LêBảoStore', 'status': 'ACTIVE'},
          {'storeId': '8', 'name': 'Cửa hàng mới', 'status': 'ACTIVE'},
        ]);
      }
      if (request.url.path.endsWith('/products')) return response([]);
      return response(device);
    });
  });
  tearDown(() {
    ApiClient().testClient = http.Client();
    provider.dispose();
  });

  Future<void> open(WidgetTester tester, {bool small = false}) async {
    tester.view.physicalSize = small
        ? const Size(320, 640)
        : const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(small ? 1.6 : 1)),
            child: child!,
          ),
          home: const DeviceDetailScreen(deviceId: '12'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Overview shows live device summary and only overview offers deletion',
    (tester) async {
      await open(tester);
      expect(find.text('LêBảoStore'), findsOneWidget);
      expect(find.text('Candy Sweet'), findsOneWidget);
      expect(find.text('Kho trung tâm'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Xác nhận kép'), findsNothing);
      expect(find.text('VÙNG NGUY HIỂM'), findsNothing);
      await tester.ensureVisible(find.text('Thiết lập đặt hàng'));
      await tester.tap(find.text('Thiết lập đặt hàng'));
      await tester.pumpAndSettle();
      expect(find.text('Đơn hàng của nút bấm'), findsOneWidget);
      expect(find.text('Xóa thiết bị'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.text('Sản phẩm đã gán'), findsOneWidget);
    },
  );

  testWidgets(
    'System back returns from connection and Wi-Fi updates overview',
    (tester) async {
      await open(tester);
      await tester.ensureVisible(find.text('Kết nối & thiết bị'));
      await tester.tap(find.text('Kết nối & thiết bị'));
      await tester.pumpAndSettle();
      expect(find.text('Kitchen_Wifi'), findsOneWidget);
      expect(find.text('Thông tin thiết bị'), findsNothing);
      expect(find.text('Xóa thiết bị'), findsNothing);
      await tester.tap(find.text('Thay đổi Wi-Fi'));
      await tester.pumpAndSettle();
      final sheet = tester.widget<WifiProvisioningSheet>(
        find.byType(WifiProvisioningSheet),
      );
      expect(sheet.initialSsid, 'Kitchen_Wifi');
      sheet.onConnected!('New_Wifi');
      Navigator.of(tester.element(find.byType(WifiProvisioningSheet))).pop();
      await tester.pumpAndSettle();
      expect(find.text('New_Wifi'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Sản phẩm đã gán'), findsOneWidget);
      expect(find.text('New_Wifi'), findsOneWidget);
    },
  );

  testWidgets('Store save clears stale product and refreshes both screens', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(find.text('Thiết lập đặt hàng'));
    await tester.tap(find.text('Thiết lập đặt hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cửa hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cửa hàng mới'));
    await tester.pump();
    await tester.tap(find.text('Lưu cửa hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Cửa hàng mới'), findsOneWidget);
    expect(find.text('Chưa gán sản phẩm'), findsOneWidget);
    expect(find.textContaining('Candy Sweet'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductSelectionSheet), findsOneWidget);
    Navigator.of(tester.element(find.byType(ProductSelectionSheet))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(find.text('Cửa hàng mới'), findsOneWidget);
    expect(find.text('Chưa gán sản phẩm'), findsOneWidget);
  });

  testWidgets('Deletion requires confirmation and does not pretend success', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('deleteDevice')));
    await tester.tap(find.byKey(const ValueKey('deleteDevice')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.byKey(const ValueKey('deleteDevice')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Chức năng xóa thiết bị hiện chưa khả dụng'),
      findsOneWidget,
    );
    expect(provider.devices, hasLength(1));
    expect(find.byType(DeviceDetailScreen), findsOneWidget);
  });

  testWidgets(
    'Long names and large text fit small screens and keep done reachable',
    (tester) async {
      await open(tester, small: true);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Thiết lập đặt hàng'));
      await tester.tap(find.text('Thiết lập đặt hàng'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xong'));
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Kết nối & thiết bị'));
      await tester.tap(find.text('Kết nối & thiết bị'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Xong'));
      expect(tester.takeException(), isNull);
    },
  );
}
