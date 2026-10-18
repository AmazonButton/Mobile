/// Model đại diện cho gợi ý địa chỉ trả về từ Autocomplete API
class AddressPrediction {
  final String placeId;
  final String primaryText;   // Tên tòa nhà, căn hộ hoặc địa điểm chính (VD: "Tòa S2.05 - The Rainbow")
  final String secondaryText; // Địa chỉ chi tiết (VD: "Vinhomes Grand Park, P. Long Thạnh Mỹ, TP. Thủ Đức")
  final String fullAddress;   // Địa chỉ đầy đủ dùng cho giao hàng
  final String? tag;          // Nhãn phân loại (Chung cư, Cao cấp, TTTM, Ga Metro...)
  final String? room;         // Số phòng / Căn hộ (VD: "P.1204")
  final double? lat;
  final double? lng;

  AddressPrediction({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullAddress,
    this.tag,
    this.room,
    this.lat,
    this.lng,
  });

  factory AddressPrediction.fromJson(Map<String, dynamic> json) {
    return AddressPrediction(
      placeId: json['placeId']?.toString() ?? '',
      primaryText: json['primaryText']?.toString() ?? '',
      secondaryText: json['secondaryText']?.toString() ?? '',
      fullAddress: json['fullAddress']?.toString() ?? '',
      tag: json['tag']?.toString(),
      room: json['room']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'primaryText': primaryText,
      'secondaryText': secondaryText,
      'fullAddress': fullAddress,
      'tag': tag,
      'room': room,
      'lat': lat,
      'lng': lng,
    };
  }
}
