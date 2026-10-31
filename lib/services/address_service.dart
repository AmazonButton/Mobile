import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address_prediction.dart';

class AddressService {
  static Future<List<AddressPrediction>> autocomplete(String query) async {
    const key = String.fromEnvironment('GOONG_API_KEY');
    if (key.isEmpty) throw StateError('Chưa cấu hình Goong');
    if (query.trim().length < 2) return [];
    final response = await http
        .get(
          Uri.https('rsapi.goong.io', '/Place/AutoComplete', {
            'input': query.trim(),
            'api_key': key,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw StateError('Không thể tải gợi ý');
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      throw StateError('Không thể tải gợi ý');
    }
    return ((data['predictions'] as List?) ?? [])
        .map(
          (p) => AddressPrediction(
            placeId: p['place_id'],
            primaryText:
                p['structured_formatting']?['main_text'] ?? p['description'],
            secondaryText: p['structured_formatting']?['secondary_text'] ?? '',
            fullAddress: p['description'],
          ),
        )
        .toList();
  }

  static Future<List<String>> getRecentAddresses() async => [];
  static Future<void> saveRecentAddress(String address) async {}
  static Future<void> removeRecentAddress(String address) async {}
}
