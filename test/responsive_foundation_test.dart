import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/widgets/sample_a.dart';
import 'package:smart_order_button/screens/device_detail_screen.dart';

void main() {
  const sizes = [
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
    Size(600, 960),
    Size(800, 1280),
    Size(844, 390),
  ];
  for (final size in sizes) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'device detail $size scale $scale starts at top and scrolls',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: const DeviceDetailScreen(
                  deviceName:
                      'Nút nước uống khu vực bếp gia đình với tên rất dài',
                  productName:
                      'Sản phẩm gia đình với tên dài cần đọc đầy đủ thông tin',
                  productPrice: '123.456.789đ',
                  wifiSsid: '',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester
                .getTopLeft(
                  find.text('100%').evaluate().isEmpty
                      ? find.text('85%')
                      : find.text('100%'),
                )
                .dy,
            lessThan(150),
          );
          await tester.scrollUntilVisible(
            find.text('Đổi cửa hàng'),
            160,
            scrollable: find.byType(Scrollable).first,
          );
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.text('Wi-Fi thiết bị').last,
            120,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.text('Wi-Fi thiết bị').last);
          await tester.pumpAndSettle();
          expect(find.text('Thay đổi Wi-Fi'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'shared actions wrap, invoke once and disable while busy; keyboard retains form',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      Widget page(double inset) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 568),
            textScaler: TextScaler.linear(2),
            viewInsets: EdgeInsets.only(bottom: inset),
          ),
          child: Scaffold(
            body: ASheetScroll(
              child: Column(
                children: [
                  ASectionHeader(
                    title: 'Tiêu đề dài của một mục',
                    action: TextButton(
                      onPressed: () {},
                      child: const Text('Hành động phụ'),
                    ),
                  ),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Mã thiết bị'),
                  ),
                  AButton(
                    label: 'Xác nhận thao tác với nội dung dài',
                    onPressed: () => calls++,
                  ),
                  AButton(
                    label: 'Đang xử lý',
                    busy: true,
                    onPressed: () => calls++,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(page(0));
      await tester.enterText(find.byType(TextField), 'KEEP-123');
      await tester.pumpWidget(page(240));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.text, 'KEEP-123');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.text('Xác nhận thao tác với nội dung dài'),
      );
      await tester.tap(find.text('Xác nhận thao tác với nội dung dài'));
      await tester.pump();
      expect(calls, 1);
      await tester.ensureVisible(find.text('Đang xử lý'));
      await tester.tap(find.text('Đang xử lý'));
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
