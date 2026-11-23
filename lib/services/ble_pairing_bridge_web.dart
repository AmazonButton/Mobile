import 'dart:js_interop';

@JS('scanSmartOrderBle')
external JSPromise<JSString?> _scanSmartOrderBle();

@JS('sendSmartOrderBleWifi')
external JSPromise<JSString?> _sendSmartOrderBleWifi(
  JSString expectedDeviceId,
  JSString ssid,
  JSString password,
);

@JS('disconnectSmartOrderBle')
external void _disconnectSmartOrderBle();

Future<String?> scanWebBleDevice() async {
  final result = await _scanSmartOrderBle().toDart;
  final value = result?.toDart.trim() ?? '';
  return value.isEmpty ? null : value;
}

Future<String> sendWebBleWifi(
  String expectedDeviceId,
  String ssid,
  String password,
) async {
  final result = await _sendSmartOrderBleWifi(
    expectedDeviceId.toJS,
    ssid.toJS,
    password.toJS,
  ).toDart;
  return result?.toDart ?? 'NO_BLE_SESSION';
}

void disconnectWebBle() {
  try {
    _disconnectSmartOrderBle();
  } catch (_) {}
}
