import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/screens/signup/widgets/step_ble_pairing_view.dart';
import 'package:smart_order_button/screens/signup/widgets/step_wifi_setup_view.dart';

void main() {
  Future<void> tap(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pump();
  }

  testWidgets('FR14: BLE must not report paired without a hardware response',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: StepBlePairingView(onPairingComplete: () => completed = true),
    )));
    await tap(tester, 'Đèn đã nhấp nháy xanh');
    await tester.pump(const Duration(milliseconds: 1300));
    await tap(tester, 'Kết nối');
    await tester.pump(const Duration(milliseconds: 1100));
    expect(completed, isFalse,
        reason: 'No BLE device, adapter response or hardware mock was supplied.');
  });

  testWidgets('FR14: Wi-Fi must not report configured without a device ACK',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: StepWifiSetupView(onWifiConnected: () => completed = true),
    )));
    await tap(tester, 'Tiếp tục');
    await tap(tester, 'Kết nối WiFi');
    await tester.pump(const Duration(milliseconds: 3300));
    expect(completed, isFalse,
        reason: 'No ESP32 acknowledgment or provisioning transport was supplied.');
  });
}
