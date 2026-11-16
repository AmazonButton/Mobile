import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/screens/address/address_form_sheet.dart';
import 'package:smart_order_button/services/address_service.dart';
import 'package:smart_order_button/models/address_model.dart';
import 'package:smart_order_button/models/address_prediction.dart';

void main() {
  const fullAddress =
      'Tòa S2.05, Vinhomes Grand Park, Phường Long Thạnh Mỹ, TP. Thủ Đức, TP. Hồ Chí Minh';
  const compound = {
    'commune': 'Long Thạnh Mỹ',
    'district': 'Thủ Đức',
    'province': 'Hồ Chí Minh',
  };

  test(
    'Separates building and street from structured administrative fields',
    () {
      final address = AddressService.addressFromPlace({
        'formatted_address': fullAddress,
        'compound': compound,
      });
      expect(address.addressDetail, 'Tòa S2.05, Vinhomes Grand Park');
      expect(address.ward, 'Long Thạnh Mỹ');
      expect(address.district, 'Thủ Đức');
      expect(address.province, 'Hồ Chí Minh');
    },
  );

  test('Supports addresses without a district', () {
    final address = AddressService.addressFromPlace({
      'formatted_address': 'Chung cư A, Phường B, Hà Nội',
      'compound': {'commune': 'Phường B', 'province': 'Hà Nội'},
    });
    expect(address.addressDetail, 'Chung cư A');
    expect(address.district, '');
  });

  testWidgets(
    'Selecting a suggestion fills each field; stale details are ignored',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pendingDetail = Completer<AddressModel>();
      var detailRequests = 0;
      final address = AddressService.addressFromPlace({
        'formatted_address': fullAddress,
        'compound': compound,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressFormSheet(
              autocomplete: (_) async => [
                AddressPrediction(
                  placeId: 'place-1',
                  primaryText: 'Tòa S2.05',
                  secondaryText: 'Vinhomes Grand Park',
                  fullAddress: fullAddress,
                ),
              ],
              resolveAddress: (_) async {
                detailRequests++;
                return detailRequests == 2 ? pendingDetail.future : address;
              },
            ),
          ),
        ),
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), 'Vinhomes');
      await tester.pump(const Duration(milliseconds: 401));
      await tester.pump();
      await tester.tap(find.text('Tòa S2.05'));
      await tester.pump();
      await tester.pump();
      String text(int index) =>
          tester.widget<TextFormField>(fields.at(index)).controller!.text;
      expect(text(2), 'Tòa S2.05, Vinhomes Grand Park');
      expect(text(3), 'Long Thạnh Mỹ');
      expect(text(4), 'Thủ Đức');
      expect(text(5), 'Hồ Chí Minh');

      await tester.enterText(fields.at(2), 'Landmark');
      await tester.pump(const Duration(milliseconds: 401));
      await tester.pump();
      await tester.tap(find.text('Tòa S2.05'));
      await tester.pump();
      expect(detailRequests, 2);
      await tester.enterText(fields.at(2), 'Địa chỉ nhập mới');
      pendingDetail.complete(address);
      await tester.pump();
      expect(text(2), 'Địa chỉ nhập mới');
      await tester.pumpWidget(const SizedBox());
    },
  );
}
