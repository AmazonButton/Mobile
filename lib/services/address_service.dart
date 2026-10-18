import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_prediction.dart';
import 'api_config.dart';

class AddressService {
  static const String _recentPrefsKey = 'user_recent_delivery_addresses';

  // Dữ liệu mẫu thông minh phục vụ gợi ý khi Backend chưa triển khai endpoint
  static final List<Map<String, dynamic>> _fallbackDatabase = [
    {
      'placeId': 'vhm_s101',
      'primaryText': 'Tòa S1.01 - The Rainbow',
      'secondaryText': 'Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức',
      'fullAddress': 'Tòa S1.01, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Chung cư',
      'keywords': ['s101', 's1.01', 'rainbow', 'vinhomes'],
    },
    {
      'placeId': 'vhm_s102',
      'primaryText': 'Tòa S1.02 - The Rainbow',
      'secondaryText': 'Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức',
      'fullAddress': 'Tòa S1.02, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Chung cư',
      'keywords': ['s102', 's1.02', 'rainbow', 'vinhomes'],
    },
    {
      'placeId': 'vhm_s105',
      'primaryText': 'Tòa S1.05 - The Rainbow',
      'secondaryText': 'Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức',
      'fullAddress': 'Tòa S1.05, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Chung cư',
      'keywords': ['s105', 's1.05', 'rainbow', 'vinhomes'],
    },
    {
      'placeId': 'vhm_s201',
      'primaryText': 'Tòa S2.01 - The Rainbow',
      'secondaryText': 'Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức',
      'fullAddress': 'Tòa S2.01, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Chung cư',
      'keywords': ['s201', 's2.01', 'rainbow', 'vinhomes'],
    },
    {
      'placeId': 'vhm_s205',
      'primaryText': 'Tòa S2.05 - The Rainbow',
      'secondaryText': 'Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức',
      'fullAddress': 'Tòa S2.05, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Chung cư',
      'keywords': ['s205', 's2.05', 'rainbow', 'vinhomes', 'grand park'],
    },
    {
      'placeId': 'vhm_s301',
      'primaryText': 'Tòa S3.01 - The Rainbow',
      'secondaryText': 'Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức',
      'fullAddress': 'Tòa S3.01, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Chung cư',
      'keywords': ['s301', 's3.01', 'rainbow', 'vinhomes'],
    },
    {
      'placeId': 'vhm_s501',
      'primaryText': 'Tòa S5.01 - The Rainbow',
      'secondaryText': 'Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức',
      'fullAddress': 'Tòa S5.01, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Chung cư',
      'keywords': ['s501', 's5.01', 'rainbow', 'vinhomes'],
    },
    {
      'placeId': 'masteri_m1',
      'primaryText': 'Tòa Masteri M1 (Riviera)',
      'secondaryText': 'Masteri Centre Point, Vinhomes Grand Park, TP. Thủ Đức',
      'fullAddress': 'Tòa Masteri M1, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Cao cấp',
      'keywords': ['masteri', 'm1', 'centre point'],
    },
    {
      'placeId': 'masteri_m2',
      'primaryText': 'Tòa Masteri M2 (Riviera)',
      'secondaryText': 'Masteri Centre Point, Vinhomes Grand Park, TP. Thủ Đức',
      'fullAddress': 'Tòa Masteri M2, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Cao cấp',
      'keywords': ['masteri', 'm2', 'centre point'],
    },
    {
      'placeId': 'vhm_s701',
      'primaryText': 'Tòa S7.01 - The Origami',
      'secondaryText': 'Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức',
      'fullAddress': 'Tòa S7.01, Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
      'tag': 'Chung cư',
      'keywords': ['s701', 's7.01', 'origami', 'vinhomes'],
    },
    {
      'placeId': 'poi_vincom',
      'primaryText': 'Vincom Mega Mall Grand Park',
      'secondaryText': 'Công viên Ánh Sáng, Vinhomes Grand Park, TP. Thủ Đức',
      'fullAddress': 'Vincom Mega Mall Grand Park, TP. Thủ Đức, TP.HCM',
      'tag': 'TTTM',
      'keywords': ['vincom', 'mall', 'grand park', 'mua sam'],
    },
    {
      'placeId': 'poi_metro',
      'primaryText': 'Ga Đại Học Quốc Gia - Metro Bến Thành - Suối Tiên',
      'secondaryText': 'Song Hành Xa Lộ Hà Nội, P. Linh Xuân, TP. Thủ Đức',
      'fullAddress': 'Ga Đại Học Quốc Gia, Xa Lộ Hà Nội, P. Linh Xuân, TP. Thủ Đức, TP.HCM',
      'tag': 'Ga Metro',
      'keywords': ['metro', 'suoi tien', 'dhqg', 'xa lo ha noi'],
    },
    {
      'placeId': 'poi_nvh',
      'primaryText': 'Nhà Văn Hóa Sinh Viên TP.HCM',
      'secondaryText': 'Lưu Hữu Phước, Khu Đô Thị ĐHQG, TP. Dĩ An / Thủ Đức',
      'fullAddress': 'Nhà Văn Hóa Sinh Viên, Lưu Hữu Phước, ĐHQG, TP.HCM',
      'tag': 'Công cộng',
      'keywords': ['nha van hoa', 'sinh vien', 'dhqg'],
    },
    {
      'placeId': 'poi_landmark81',
      'primaryText': 'Tòa Landmark 81 - Vinhomes Central Park',
      'secondaryText': '720A Điện Biên Phủ, Phường 22, Quận Bình Thạnh, TP.HCM',
      'fullAddress': 'Landmark 81, 720A Điện Biên Phủ, P. 22, Q. Bình Thạnh, TP.HCM',
      'tag': 'Tòa nhà',
      'keywords': ['landmark', 'landmark 81', 'binh thanh', 'central park'],
    },
  ];

  /// Gọi API Autocomplete địa chỉ thời gian thực
  static Future<List<AddressPrediction>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.addressesAutocomplete}?q=${Uri.encodeComponent(cleanQuery)}',
    );

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(milliseconds: 2000));

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        if (body['success'] == true && body['data'] is List) {
          final list = body['data'] as List;
          return list
              .map((item) =>
                  AddressPrediction.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[AddressService] Backend API not reached, using local dataset fallback: $e');
    }

    // Fallback tức thì nếu Backend chưa mở endpoint hoặc lỗi mạng
    return _searchLocal(cleanQuery);
  }

  static List<AddressPrediction> _searchLocal(String query) {
    final normalized = _normalizeText(query);
    if (normalized.isEmpty) {
      return _fallbackDatabase
          .take(6)
          .map((item) => AddressPrediction(
                placeId: item['placeId'],
                primaryText: item['primaryText'],
                secondaryText: item['secondaryText'],
                fullAddress: item['fullAddress'],
                tag: item['tag'],
              ))
          .toList();
    }

    // Tách số phòng nếu người dùng gõ kèm số phòng (VD: "P.1204 - S2.05", "1204 S205")
    String? room;
    String target = normalized;
    final roomMatch =
        RegExp(r'(?:p\.|p|phong|#)\s*([0-9]{3,4})').firstMatch(normalized);
    if (roomMatch != null) {
      room = 'P.${roomMatch.group(1)}';
      target = target.replaceAll(roomMatch.group(0)!, '').trim();
    } else {
      final leadNum = RegExp(r'^([0-9]{3,4})\b').firstMatch(normalized);
      if (leadNum != null) {
        room = 'P.${leadNum.group(1)}';
        target = target.substring(leadNum.group(0)!.length).trim();
      }
    }

    final tokens = target.split(' ').where((t) => t.isNotEmpty).toList();

    final matched = _fallbackDatabase.where((item) {
      final normName = _normalizeText(item['primaryText']);
      final normSec = _normalizeText(item['secondaryText']);
      final keywords = (item['keywords'] as List<String>)
          .map((k) => _normalizeText(k))
          .join(' ');
      final combined = '$normName $normSec $keywords';

      if (tokens.isEmpty) return true;
      return tokens.every((token) => combined.contains(token));
    }).toList();

    return matched.map((item) {
      final primary = room != null
          ? '$room - ${item['primaryText']}'
          : item['primaryText'] as String;
      final full = room != null
          ? '$room - ${item['fullAddress']}'
          : item['fullAddress'] as String;

      return AddressPrediction(
        placeId: item['placeId'],
        primaryText: primary,
        secondaryText: item['secondaryText'],
        fullAddress: full,
        tag: room != null ? 'Căn hộ' : item['tag'],
        room: room,
      );
    }).toList();
  }

  static String _normalizeText(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'đ'), 'd')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Lấy danh sách địa chỉ tìm kiếm gần đây từ SharedPreferences
  static Future<List<String>> getRecentAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentPrefsKey);
    if (list != null && list.isNotEmpty) {
      return list;
    }
    return [
      'P.1204 - Tòa S2.05, Vinhomes Grand Park',
      'P.0812 - Tòa S1.01, Vinhomes Grand Park',
      'P.0405 - Tòa Masteri M2, Vinhomes Grand Park',
    ];
  }

  /// Lưu một địa chỉ vào lịch sử gần đây
  static Future<void> saveRecentAddress(String address) async {
    final clean = address.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_recentPrefsKey) ?? [
      'P.1204 - Tòa S2.05, Vinhomes Grand Park',
      'P.0812 - Tòa S1.01, Vinhomes Grand Park',
      'P.0405 - Tòa Masteri M2, Vinhomes Grand Park',
    ];
    list.remove(clean);
    list.insert(0, clean);
    if (list.length > 8) {
      list = list.sublist(0, 8);
    }
    await prefs.setStringList(_recentPrefsKey, list);
  }

  /// Xóa một địa chỉ khỏi lịch sử gần đây
  static Future<void> removeRecentAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_recentPrefsKey) ?? [];
    list.remove(address);
    await prefs.setStringList(_recentPrefsKey, list);
  }
}
