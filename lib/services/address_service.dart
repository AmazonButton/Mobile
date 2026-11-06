import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address_prediction.dart';
import '../models/address_model.dart';

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
            compound: p['compound'] == null
                ? null
                : Map<String, dynamic>.from(p['compound']),
            placeId: p['place_id'],
            primaryText:
                p['structured_formatting']?['main_text'] ?? p['description'],
            secondaryText: p['structured_formatting']?['secondary_text'] ?? '',
            fullAddress: p['description'],
          ),
        )
        .toList();
  }

  /// Fetch structured administrative fields rather than guessing comma positions.
  static Future<AddressModel> resolvePrediction(
    AddressPrediction prediction,
  ) async {
    if (prediction.compound != null) {
      return addressFromPlace({
        'formatted_address': prediction.fullAddress,
        'compound': prediction.compound,
      });
    }
    const key = String.fromEnvironment('GOONG_API_KEY');
    if (key.isEmpty || prediction.placeId.isEmpty) {
      throw StateError('Không thể tải chi tiết địa chỉ');
    }
    final response = await http
        .get(
          Uri.https('rsapi.goong.io', '/Place/Detail', {
            'place_id': prediction.placeId,
            'api_key': key,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('Không thể tải chi tiết địa chỉ');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data['status'] != 'OK' || data['result'] is! Map) {
      throw StateError('Không thể tải chi tiết địa chỉ');
    }
    return addressFromPlace({
      ...Map<String, dynamic>.from(data['result']),
      'formatted_address': prediction.fullAddress,
    });
  }

  static AddressModel addressFromPlace(Map<String, dynamic> place) {
    final compound = place['compound'] as Map? ?? const {};
    String field(String key) => compound[key]?.toString().trim() ?? '';
    final ward = field('commune');
    final district = field('district');
    final province = field('province');
    final parts = (place['formatted_address']?.toString() ?? '')
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    String normalize(String value) => value
        .toLowerCase()
        .replaceFirst(
          RegExp(
            r'^(thành phố|tỉnh|quận|huyện|thị xã|phường|xã|thị trấn|tp[.]?|p[.]?|q[.]?)\s+',
          ),
          '',
        )
        .trim();
    // Only remove matching administrative suffixes; preserve building/street text.
    for (final value in [province, district, ward]) {
      if (value.isNotEmpty &&
          parts.length > 1 &&
          normalize(parts.last) == normalize(value)) {
        parts.removeLast();
      }
    }
    return AddressModel(
      id: '',
      recipientName: '',
      phone: '',
      addressDetail: parts.join(', '),
      ward: ward,
      district: district,
      province: province,
    );
  }

  static Future<List<String>> getRecentAddresses() async => [];
  static Future<void> saveRecentAddress(String address) async {}
  static Future<void> removeRecentAddress(String address) async {}
}
