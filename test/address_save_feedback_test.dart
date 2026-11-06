import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_order_button/models/address_model.dart';
import 'package:smart_order_button/providers/address_provider.dart';
import 'package:smart_order_button/screens/address/address_form_sheet.dart';
import 'package:smart_order_button/services/address_api_service.dart';
import 'package:smart_order_button/services/api_client.dart';

class FailingAddressApi extends AddressApiService {
  int attempts = 0;
  @override
  Future<AddressModel> createAddress(AddressModel address) async {
    attempts++;
    throw ApiException(message: 'Customer profile not found', statusCode: 404);
  }
}

void main() {
  testWidgets('Validation scrolls to missing recipient above the save button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AddressFormSheet())),
    );
    final save = find.text('Lưu địa chỉ mới');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên người nhận'), findsOneWidget);
    final top = tester.getTopLeft(find.text('Vui lòng nhập tên người nhận')).dy;
    expect(top, greaterThan(0));
    expect(top, lessThan(650));
  });

  testWidgets('Save failure appears inside the sheet and permits retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FailingAddressApi();
    final provider = AddressProvider(apiService: api);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: AddressFormSheet())),
      ),
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Người nhận thử nghiệm');
    await tester.enterText(fields.at(1), '0988776655');
    await tester.enterText(fields.at(2), 'Tòa A, căn 104');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu địa chỉ mới'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('address-save-error')), findsOneWidget);
    expect(find.textContaining('Customer profile not found'), findsOneWidget);
    expect(find.byType(AddressFormSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Lưu địa chỉ mới'));
    await tester.pumpAndSettle();
    expect(api.attempts, 2);
  });
}

