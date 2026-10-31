import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/screens/device_detail_screen.dart';
import 'package:smart_order_button/screens/devices_screen.dart';
import 'package:smart_order_button/screens/home_screen.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/widgets/devices/device_card.dart';
import 'package:smart_order_button/widgets/devices/smart_button_card.dart';
import 'package:smart_order_button/widgets/modals/product_selection_sheet.dart';

void main() {
  final device = {
    'deviceId': '12',
    'buttonName': 'Nút bếp',
    'roomLocation': 'Bếp',
    'wifiSsid': 'Kitchen_Wifi',
    'batteryLevel': 85,
    'store': {'name': 'Cửa hàng bếp'},
    'products': <dynamic>[],
  };
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test-token');
    ApiClient().testClient = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'success': true,
          'data': request.url.path.endsWith('/devices')
              ? [device]
              : <dynamic>[],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
  });
  tearDown(() => ApiClient().testClient = http.Client());

  for (final entry in <String, Widget>{
    'home': const HomeScreen(),
    'device list': const DevicesScreen(),
  }.entries) {
    testWidgets('${entry.key} opens the new device overview', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = DeviceProvider(
        initialDevices: [DeviceModel.fromJson(device)],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(home: entry.value),
        ),
      );
      await tester.pumpAndSettle();
      final gear = entry.key == 'home'
          ? find.byType(SmartButtonCard).first
          : find.descendant(
              of: find.byType(DeviceCard).first,
              matching: find.byIcon(LucideIcons.settings),
            );
      await tester.ensureVisible(gear);
      await tester.tap(gear);
      await tester.pumpAndSettle();
      expect(find.byType(DeviceDetailScreen), findsOneWidget);
      expect(find.text('Sản phẩm đã gán'), findsOneWidget);
      expect(find.text('Kitchen_Wifi'), findsOneWidget);
      expect(find.byType(ProductSelectionSheet), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });
  }
}
