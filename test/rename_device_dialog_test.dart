import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/device_model.dart';
import 'package:smart_order_button/providers/device_provider.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/widgets/modals/rename_device_dialog.dart';

void main() {
  late DeviceProvider provider;
  late Map<String, dynamic> device;
  late List<http.Request> writes;
  bool fail = false;
  Completer<void>? gate;
  http.Response response(dynamic data, {int status = 200}) => http.Response(
    jsonEncode(
      status == 200
          ? {'success': true, 'data': data}
          : {'success': false, 'message': 'Không thể lưu tên'},
    ),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'rename-test');
    fail = false;
    gate = null;
    writes = [];
    device = {
      'deviceId': '12',
      'buttonName': 'Nút bếp',
      'batteryLevel': 80,
      'roomLocation': 'Bếp',
      'storeId': '7',
      'products': [],
    };
    provider = DeviceProvider(initialDevices: [DeviceModel.fromJson(device)]);
    ApiClient().testClient = MockClient((request) async {
      if (request.method == 'PUT') {
        writes.add(request);
        if (gate != null) await gate!.future;
        if (fail) return response(null, status: 503);
        device = {
          ...device,
          ...jsonDecode(request.body) as Map<String, dynamic>,
        };
      }
      return response(device);
    });
  });
  tearDown(() async {
    ApiClient().testClient = http.Client();
    await ApiClient().clearTokens();
    provider.dispose();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Consumer<DeviceProvider>(
                    builder: (_, state, _) => Text(state.devices.single.name),
                  ),
                  TextButton(
                    key: const ValueKey('renameDevice'),
                    onPressed: () => showDialog<bool>(
                      context: context,
                      builder: (_) => RenameDeviceDialog(
                        initialName: provider.devices.single.name,
                        onSave: (name) => provider.renameDevice('12', name),
                      ),
                    ),
                    child: const Text('Đổi tên'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('renameDevice')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Rename trims name, sends only buttonName, updates detail and persists on reopen',
    (tester) async {
      await open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('deviceNameInput')),
        '  Nút nước phòng khách  ',
      );
      await tester.tap(find.byKey(const ValueKey('saveDeviceName')));
      await tester.pumpAndSettle();
      expect(writes, hasLength(1));
      expect(writes.single.url.path, endsWith('/devices/12/customer-config'));
      expect(jsonDecode(writes.single.body), {
        'buttonName': 'Nút nước phòng khách',
      });
      expect(provider.devices.single.name, 'Nút nước phòng khách');
      expect(provider.devices.single.storeId, '7');
      expect(provider.devices.single.battery, 80);
      expect(find.text('Nút nước phòng khách'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('renameDevice')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('deviceNameInput')),
            )
            .controller!
            .text,
        'Nút nước phòng khách',
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Failure keeps old name and draft; retry can save', (
    tester,
  ) async {
    fail = true;
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('deviceNameInput')),
      'Nút mới',
    );
    await tester.tap(find.byKey(const ValueKey('saveDeviceName')));
    await tester.pumpAndSettle();
    expect(provider.devices.single.name, 'Nút bếp');
    expect(find.byType(RenameDeviceDialog), findsOneWidget);
    expect(find.text('Không thể lưu tên'), findsOneWidget);
    fail = false;
    await tester.tap(find.byKey(const ValueKey('saveDeviceName')));
    await tester.pumpAndSettle();
    expect(provider.devices.single.name, 'Nút mới');
    expect(writes, hasLength(2));
  });

  testWidgets('Blank name is rejected and cancel does not save', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('deviceNameInput')),
      '   ',
    );
    await tester.tap(find.byKey(const ValueKey('saveDeviceName')));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên nút'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(writes, isEmpty);
    expect(provider.devices.single.name, 'Nút bếp');
  });

  testWidgets('Save is disabled while pending and old name stays until ACK', (
    tester,
  ) async {
    gate = Completer<void>();
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('deviceNameInput')),
      'Nút mới',
    );
    await tester.tap(find.byKey(const ValueKey('saveDeviceName')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('saveDeviceName')))
          .onPressed,
      isNull,
    );
    expect(provider.devices.single.name, 'Nút bếp');
    gate!.complete();
    await tester.pumpAndSettle();
    expect(writes, hasLength(1));
    expect(provider.devices.single.name, 'Nút mới');
  });

  test(
    'Provider rejects invalid length and missing device without requests',
    () async {
      await expectLater(
        provider.renameDevice('12', 'x' * 101),
        throwsArgumentError,
      );
      await expectLater(
        provider.renameDevice('missing', 'Nút mới'),
        throwsStateError,
      );
      expect(writes, isEmpty);
    },
  );
}
