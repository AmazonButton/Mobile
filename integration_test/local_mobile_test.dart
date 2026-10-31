// Android + real local backend smoke coverage. This does NOT cover OTP or FCM.
// Requires an isolated, pre-seeded backend; fails closed without explicit inputs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/providers/order_provider.dart';
import 'package:smart_order_button/screens/devices_screen.dart';
import 'package:smart_order_button/screens/device_detail_screen.dart';
import 'package:smart_order_button/screens/orders_screen.dart';
import 'package:smart_order_button/screens/orders/widgets/order_detail_bottom_sheet.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/services/api_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const token = String.fromEnvironment('AUDIT_ACCESS_TOKEN');
  const deviceName = String.fromEnvironment('AUDIT_DEVICE_NAME');
  const orderCode = String.fromEnvironment('AUDIT_ORDER_CODE');

  setUpAll(() async {
    final url = Uri.parse(ApiConfig.baseUrl);
    expect(['127.0.0.1', 'localhost', '10.0.2.2'], contains(url.host),
        reason: 'Only an isolated local backend is allowed. Use adb reverse.');
    expect(token, isNotEmpty, reason: 'Supply a local fixture resident token.');
    expect(deviceName, isNotEmpty);
    expect(orderCode, isNotEmpty);
    await ApiClient().init();
    await ApiClient().setTokens(accessToken: token);
  });
  tearDownAll(() async => ApiClient().clearTokens());

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    // Bounded waits: OrdersScreen has a periodic timer, so no pumpAndSettle.
    for (var attempt = 0; attempt < 60; attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return;
    }
    expect(finder, findsWidgets, reason: 'UI not ready after 15 seconds.');
  }

  testWidgets('FR4/5/13: local device is rendered and opens its settings',
      (tester) async {
    final provider = DeviceProvider(initialDevices: []);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: DevicesScreen()),
    ));
    await waitFor(tester, find.text(deviceName));
    expect(provider.errorMessage, isNull);
    await tester.tap(find.text(deviceName).first);
    await waitFor(tester, find.byType(DeviceDetailScreen));
    await waitFor(tester, find.text('Thiết lập đặt hàng'));
    await tester.ensureVisible(find.text('Thiết lập đặt hàng'));
    await tester.tap(find.text('Thiết lập đặt hàng'));
    await waitFor(tester, find.text('Đơn hàng của nút bấm'));
    expect(find.text('Cửa hàng'), findsOneWidget);
    expect(find.text('Sản phẩm'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });

  testWidgets('FR12: local order opens matching order details', (tester) async {
    final provider = OrderProvider(initialOrders: []);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: OrdersScreen()),
    ));
    await waitFor(tester, find.textContaining(orderCode));
    expect(provider.errorMessage, isNull);
    final target = find.textContaining(orderCode).first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await waitFor(tester, find.byType(OrderDetailBottomSheet));
    final sheet = tester.widget<OrderDetailBottomSheet>(
        find.byType(OrderDetailBottomSheet));
    expect(sheet.order.orderCode, orderCode);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
}
