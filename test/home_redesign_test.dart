import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/screens/home/widgets/widgets.dart';
import 'package:smart_order_button/widgets/devices/smart_button_card.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test');
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
  for (final scale in [1.0, 2.0]) {
    testWidgets('home cards fit a narrow screen at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var ordered = false;
      var settings = false;
      var managed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 1100),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const HomeButtonHint(
                        title: 'Đặt món quen từ nút của bạn',
                      ),
                      HomeSmartButtonsGrid(
                        devices: List.generate(
                          3,
                          (i) => DeviceModel(
                            id: 'preview-$i',
                            name: 'Nút 0$i',
                            room: '',
                            product: 'Nước uống tinh khiết 20L',
                            price: '25.000đ',
                            storeName: 'Cửa hàng An Nhiên',
                            battery: 85,
                            status: DeviceStatus.online,
                          ),
                        ),
                        onManage: () => managed = true,
                        onAddDevice: () {},
                        onDeviceOrder: (_) => ordered = true,
                        onDeviceSettings: (_) => settings = true,
                      ),
                      const HomeButtonHint(
                        title: 'Chọn sản phẩm, gán vào nút',
                        subtitle: 'Sẵn sàng cho lần đặt hàng tiếp theo.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SmartButtonCard), findsNWidgets(2));
      final first = tester.getTopLeft(find.byType(SmartButtonCard).first);
      final second = tester.getTopLeft(find.byType(SmartButtonCard).last);
      if (scale == 1) {
        expect(first.dy, second.dy);
        expect(second.dx, greaterThan(first.dx));
      } else {
        expect(second.dy, greaterThan(first.dy));
      }
      await tester.ensureVisible(find.text('Đặt hàng').first);
      await tester.tap(find.text('Đặt hàng').first);
      expect(ordered, isTrue);
      await tester.ensureVisible(find.byTooltip('Cài đặt thiết bị').first);
      await tester.tap(find.byTooltip('Cài đặt thiết bị').first);
      expect(settings, isTrue);
      await tester.ensureVisible(find.text('Xem tất cả nút'));
      await tester.tap(find.text('Xem tất cả nút'));
      expect(managed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
