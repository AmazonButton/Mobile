Future<String?> scanWebBleDevice() async => null;

Future<String> sendWebBleWifi(
  String expectedDeviceId,
  String ssid,
  String password,
) async => 'NO_BLE_SESSION';

void disconnectWebBle() {}
