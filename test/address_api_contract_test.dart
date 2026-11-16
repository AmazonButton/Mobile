import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_order_button/models/address_model.dart';
import 'package:smart_order_button/services/address_api_service.dart';
import 'package:smart_order_button/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Address CRUD matches deployed customer-addresses API', () async {
    SharedPreferences.setMockInitialValues({});
    final client = ApiClient();
    await client.setTokens(accessToken: 'test-session');
    final requests = <http.Request>[];
    final stored = <String, dynamic>{
      'addressId': '42',
      'recipientName': 'Test',
      'phone': '0988776655',
      'addressDetail': 'Can 104, Toa A',
      'ward': 'Long Hung',
      'district': 'Van Giang',
      'province': 'Hung Yen',
      'isDefault': false,
    };
    client.testClient = MockClient((request) async {
      requests.add(request);
      expect(request.headers['Authorization'], 'Bearer test-session');
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [stored],
          }),
          200,
        );
      }
      if (request.method == 'DELETE') {
        return http.Response(jsonEncode({'success': true}), 200);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('id'), isFalse);
      expect(body.containsKey('label'), isFalse);
      stored.addAll(body);
      return http.Response(jsonEncode({'success': true, 'data': stored}), 200);
    });
    addTearDown(() async {
      client.testClient = http.Client();
      await client.clearTokens();
    });
    final api = AddressApiService();
    final list = await api.getAddresses();
    expect(list.single.id, '42');
    final created = await api.createAddress(
      const AddressModel(
        id: '',
        recipientName: 'Test',
        phone: '0988776655',
        addressDetail: 'Can 104, Toa A',
      ),
    );
    expect(created.id, '42');
    final updated = await api.updateAddress(
      created.copyWith(ward: 'Long Hung'),
    );
    expect(updated.ward, 'Long Hung');
    expect(await api.setDefaultAddress(created.id), isTrue);
    expect(jsonDecode(requests.last.body), {'isDefault': true});
    expect(await api.deleteAddress(created.id), isTrue);
    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'GET /api/v1/customer-addresses',
      'POST /api/v1/customer-addresses',
      'PATCH /api/v1/customer-addresses/42',
      'PATCH /api/v1/customer-addresses/42',
      'DELETE /api/v1/customer-addresses/42',
    ]);
  });
}
