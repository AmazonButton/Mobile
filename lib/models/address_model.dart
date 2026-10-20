class AddressModel {
  final String id;
  final String recipientName;
  final String phone;
  final String addressDetail;
  final String? ward;
  final String? district;
  final String? province;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final String label; // 'Nhà riêng', 'Cơ quan', 'Khác'

  const AddressModel({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.addressDetail,
    this.ward,
    this.district,
    this.province,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    this.label = 'Nhà riêng',
  });

  /// Chuỗi hiển thị địa chỉ đầy đủ kết hợp các cấp hành chính
  String get fullAddress {
    final parts = <String>[];
    if (addressDetail.trim().isNotEmpty) {
      parts.add(addressDetail.trim());
    }
    if (ward != null &&
        ward!.trim().isNotEmpty &&
        !addressDetail.toLowerCase().contains(ward!.toLowerCase())) {
      parts.add(ward!.trim());
    }
    if (district != null &&
        district!.trim().isNotEmpty &&
        !addressDetail.toLowerCase().contains(district!.toLowerCase())) {
      parts.add(district!.trim());
    }
    if (province != null &&
        province!.trim().isNotEmpty &&
        !addressDetail.toLowerCase().contains(province!.toLowerCase())) {
      parts.add(province!.trim());
    }
    return parts.join(', ');
  }

  /// Tên ngắn gọn (Ví dụ: Số phòng hoặc Số nhà)
  String get shortDisplay {
    if (addressDetail.contains('-')) {
      return addressDetail.split('-').first.trim();
    }
    return addressDetail;
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['addressId'] ?? json['_id'];
    final id = rawId?.toString() ?? '';

    final name = json['recipientName'] ??
        json['recipient_name'] ??
        json['name'] ??
        json['fullName'] ??
        '';

    final phone = json['phone'] ?? json['phoneNumber'] ?? '';

    final detail = json['addressDetail'] ??
        json['address_detail'] ??
        json['address'] ??
        json['detail'] ??
        '';

    final ward = json['ward']?.toString();
    final district = json['district']?.toString();
    final province = json['province']?.toString() ?? json['city']?.toString();

    final isDefault = json['isDefault'] == true ||
        json['is_default'] == true ||
        json['isDefault'] == 1 ||
        json['is_default'] == 1;

    double? lat;
    if (json['latitude'] != null) {
      lat = double.tryParse(json['latitude'].toString());
    }

    double? lng;
    if (json['longitude'] != null) {
      lng = double.tryParse(json['longitude'].toString());
    }

    final label = json['label']?.toString() ?? 'Nhà riêng';

    return AddressModel(
      id: id,
      recipientName: name.toString().trim(),
      phone: phone.toString().trim(),
      addressDetail: detail.toString().trim(),
      ward: ward?.trim(),
      district: district?.trim(),
      province: province?.trim(),
      isDefault: isDefault,
      latitude: lat,
      longitude: lng,
      label: label,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'recipientName': recipientName,
      'phone': phone,
      'addressDetail': addressDetail,
      if (ward != null && ward!.isNotEmpty) 'ward': ward,
      if (district != null && district!.isNotEmpty) 'district': district,
      if (province != null && province!.isNotEmpty) 'province': province,
      'isDefault': isDefault,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'label': label,
    };
  }

  AddressModel copyWith({
    String? id,
    String? recipientName,
    String? phone,
    String? addressDetail,
    String? ward,
    String? district,
    String? province,
    bool? isDefault,
    double? latitude,
    double? longitude,
    String? label,
  }) {
    return AddressModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      addressDetail: addressDetail ?? this.addressDetail,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      province: province ?? this.province,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          recipientName == other.recipientName &&
          phone == other.phone &&
          addressDetail == other.addressDetail &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^
      recipientName.hashCode ^
      phone.hashCode ^
      addressDetail.hashCode ^
      isDefault.hashCode;
}
