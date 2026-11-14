import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/services/api_client.dart';
import 'package:smart_order_button/screens/profile_screen.dart';
import 'package:smart_order_button/screens/address/address_list_screen.dart';
import 'package:smart_order_button/screens/customer_buttons_screen.dart';
import 'package:smart_order_button/screens/customer_bank_accounts_screen.dart';
import 'package:smart_order_button/screens/identity_verification_screen.dart';

void main() {
  var savedAddress = false;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient().setTokens(accessToken: 'test');
    ApiClient().testClient = MockClient((request) async {
      Object data = [];
      if (savedAddress && request.url.path.endsWith('/customer-addresses')) {
        data = [
          {
            'id': '1',
            'recipientName': 'Người nhận kiểm thử',
            'phone': '0900000000',
            'addressDetail': 'Địa chỉ kiểm thử với tên dài',
            'province': 'Thành phố kiểm thử',
            'isDefault': true,
          },
        ];
      }
      if (request.url.path.endsWith('/bank-accounts')) {
        data = [
          {
            'id': '1',
            'bankName': 'Ngân hàng kiểm thử',
            'accountName': 'TEST USER',
            'accountNumberMasked': '******1234',
            'verificationStatus': 'PENDING',
          },
        ];
      } else if (request.url.path.endsWith('/my-rentals')) {
        data = [
          {
            'rentalId': '1',
            'rentalCode': 'RNT-1',
            'status': 'ACTIVE',
            'depositAmount': 200000,
            'buttons': [
              {'buttonId': '1', 'name': 'Nút nước uống trong nhà'},
            ],
          },
        ];
      }
      return http.Response(
        jsonEncode({'data': data}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
  });
  tearDown(() => ApiClient().testClient = http.Client());
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(430, 932),
    const Size(600, 960),
    const Size(800, 1280),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final entry in <String, Widget>{
        'profile': const ProfileScreen(),
        'addresses': const AddressListScreen(),
        'addresses saved': const AddressListScreen(),
        'deposits': const CustomerButtonsScreen(),
        'banks': const CustomerBankAccountsScreen(),
        'identity': const IdentityVerificationScreen(),
      }.entries) {
        testWidgets('${entry.key} fits $size at text scale $scale', (
          tester,
        ) async {
          savedAddress = entry.key == 'addresses saved';
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
                child: entry.value,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final scroll = find.byType(Scrollable);
          if (scroll.evaluate().isNotEmpty) {
            await tester.drag(scroll.first, const Offset(0, -450));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}
