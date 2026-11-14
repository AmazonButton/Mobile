import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/models/button_product_model.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/screens/store_product_assignment.dart';
import 'package:smart_order_button/widgets/devices/device_card.dart';

void main() {
  testWidgets('confirmation sends once, shows errors, and allows retry', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: AssignmentReviewScreen(
          product: ButtonProductModel.fromJson({
            'productId': '1',
            'name': 'Nước uống 20L',
            'price': 25000,
          }),
          device: const DeviceModel(
            id: '1',
            name: 'Nút dự phòng',
            room: '',
            battery: 85,
            status: DeviceStatus.online,
          ),
          storeName: 'Cửa hàng',
          quantity: 2,
          onConfirm: () {
            calls++;
            return pending.future;
          },
        ),
      ),
    );
    expect(calls, 0);
    await tester.tap(find.text('Xác nhận gán'));
    await tester.pump();
    expect(calls, 1);
    await tester.tapAt(tester.getCenter(find.text('Quay lại')));
    expect(calls, 1);
    expect(find.text('Quay lại'), findsOneWidget);
    pending.completeError(StateError('server error'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chưa thể gán sản phẩm. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Xác nhận gán'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('device cards fit 320px with text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 800),
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const DeviceCard(
                    id: '1',
                    name: 'Nút nước uống trong phòng khách',
                    room: '',
                    product: 'Nước uống 20L',
                    storeName: 'Cửa hàng An Nhiên',
                    price: '25.000đ',
                    batteryLevel: 85,
                  ),
                  DeviceCard(
                    id: '2',
                    name: 'Nút dự phòng',
                    room: '',
                    product: 'Chưa gán sản phẩm',
                    price: '',
                    batteryLevel: 65,
                    onSelectProduct: () => selected = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Chọn sản phẩm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn sản phẩm'));
      expect(selected, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
