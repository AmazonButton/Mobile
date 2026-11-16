class CustomerButtonContract {
  final String id;
  final String code;
  final String status;
  final num depositAmount;
  final bool? canOrder;
  final List<CustomerContractButton> buttons;

  const CustomerButtonContract({
    required this.id,
    required this.code,
    required this.status,
    required this.depositAmount,
    required this.canOrder,
    required this.buttons,
  });

  factory CustomerButtonContract.fromJson(Map<String, dynamic> json) {
    final id = json['rentalId']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Thiếu mã hồ sơ nút');
    }
    final amount = num.tryParse(json['depositAmount']?.toString() ?? '');
    if (amount == null || amount < 0) {
      throw const FormatException('Tiền cọc không hợp lệ');
    }
    return CustomerButtonContract(
      id: id,
      code: json['rentalCode']?.toString() ?? id,
      status: json['status']?.toString() ?? 'UNKNOWN',
      depositAmount: amount,
      canOrder: json['canOrder'] is bool ? json['canOrder'] as bool : null,
      buttons: (json['buttons'] as List? ?? [])
          .whereType<Map>()
          .map(
            (button) => CustomerContractButton.fromJson(
              Map<String, dynamic>.from(button),
            ),
          )
          .toList(),
    );
  }

  String get statusLabel => switch (status) {
    'PENDING_PAYMENT' => 'Chờ hoàn tất tiền cọc',
    'PENDING_HANDOVER' => 'Chờ bàn giao nút',
    'ACTIVE' => 'Đang sử dụng',
    'EXPIRED' => 'Tạm ngừng sử dụng — liên hệ cửa hàng',
    'RETURNED' => 'Cửa hàng đã nhận lại nút',
    'CANCELLED' => 'Đã hủy',
    _ => 'Đang cập nhật',
  };

  bool get canRequestReturn => {'ACTIVE', 'EXPIRED'}.contains(status);
}

class CustomerContractButton {
  final String id;
  final String name;
  final String status;
  const CustomerContractButton({
    required this.id,
    required this.name,
    required this.status,
  });
  factory CustomerContractButton.fromJson(Map<String, dynamic> json) {
    final id = json['buttonId']?.toString();
    if (id == null || id.isEmpty) throw const FormatException('Thiếu mã nút');
    return CustomerContractButton(
      id: id,
      name:
          json['name']?.toString() ??
          json['buttonCode']?.toString() ??
          'Nút thông minh',
      status: json['status']?.toString() ?? 'UNKNOWN',
    );
  }
}
