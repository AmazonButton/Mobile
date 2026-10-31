// Acceptance checks against Capstone sections 3.2.1 and 3.4.
// These deliberately assert the specification, not today's implementation.
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/models/order_model.dart';

void main() {
  OrderModel pending(int age) => OrderModel.fromJson({
    'id': '901',
    'status': 'PENDING',
    'createdAt': DateTime.now().subtract(Duration(seconds: age)).toIso8601String(),
  });

  test('FR11: a fresh order exposes the full 120 second window', () {
    expect(pending(0).remainingSafetySeconds, inInclusiveRange(119, 120));
  });
  test('FR11: reopening an order at 90 seconds still permits cancellation', () {
    expect(pending(90).isEmergencyCancellable, isTrue);
  });
  test('FR11: cancellation is unavailable after 120 seconds', () {
    expect(pending(121).isEmergencyCancellable, isFalse);
  });
  test('FR11: a completed order cannot be emergency cancelled', () {
    expect(OrderModel.fromJson({'id': '901', 'status': 'COMPLETED'})
        .isEmergencyCancellable, isFalse);
  });
  test('FR13: missing telemetry must not claim a full battery', () {
    expect(DeviceModel.fromJson({'id': '901'}).batteryText, isNot('100%'));
  });
  test('FR13: malformed telemetry must not claim a full battery', () {
    expect(DeviceModel.fromJson({'id': '901', 'batteryLevel': 'invalid'})
        .batteryText, isNot('100%'));
  });
  test('FR13: low battery is preserved and warned', () {
    final device = DeviceModel.fromJson({'id': '901', 'batteryLevel': 10});
    expect(device.batteryText, '10%');
    expect(device.status, DeviceStatus.warning);
  });
  test('FR12: an order with an empty product image list remains readable', () {
    expect(() => OrderModel.fromJson({
      'id': '901', 'status': 'PENDING',
      'items': [{'productName': 'Audit water', 'quantity': 2,
        'product': {'images': <dynamic>[]}}],
    }), returnsNormally);
  });
}
