import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class GoongService {
  static const _key = String.fromEnvironment('GOONG_API_KEY');
  static final _cache = <String, (double, double)>{};

  Future<(double, double)?> geocode(String address) async {
    if (_key.isEmpty || address.trim().isEmpty) return null;
    if (_cache.containsKey(address)) return _cache[address];
    try {
      final response = await http
          .get(
            Uri.https('rsapi.goong.io', '/Geocode', {
              'address': address,
              'api_key': _key,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data['status'] != 'OK' || (data['results'] as List).isEmpty)
        return null;
      final location = data['results'][0]['geometry']['location'];
      final point = (
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      );
      _cache[address] = point;
      return point;
    } catch (_) {
      return null;
    }
  }

  static double distanceKm((double, double) a, (double, double) b) {
    double rad(double n) => n * math.pi / 180;
    final h =
        math.pow(math.sin(rad(b.$1 - a.$1) / 2), 2) +
        math.cos(rad(a.$1)) *
            math.cos(rad(b.$1)) *
            math.pow(math.sin(rad(b.$2 - a.$2) / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(h.clamp(0, 1)));
  }
}
