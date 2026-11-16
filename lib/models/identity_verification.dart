class IdentityVerification {
  final String id, status;
  final String? verificationUrl;
  final DateTime? expiresAt, createdAt;
  const IdentityVerification({
    required this.id,
    required this.status,
    this.verificationUrl,
    this.expiresAt,
    this.createdAt,
  });

  factory IdentityVerification.fromJson(Map<String, dynamic> json) {
    final id = json['sessionId']?.toString() ?? '';
    if (!RegExp(r'^[1-9]\d*$').hasMatch(id)) {
      throw const FormatException('Phiên xác minh không hợp lệ');
    }
    return IdentityVerification(
      id: id,
      status: (json['status']?.toString() ?? 'UNKNOWN').toUpperCase(),
      verificationUrl: json['verificationUrl']?.toString(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
  bool get approved => status == 'APPROVED';
  bool get terminal => {
    'APPROVED',
    'DECLINED',
    'EXPIRED',
    'CANCELLED',
    'ABANDONED',
  }.contains(status);
  bool get expired =>
      status == 'EXPIRED' ||
      (expiresAt != null && !expiresAt!.isAfter(DateTime.now()));
  bool get canContinue => !terminal && !expired && status != 'IN_REVIEW';
  Uri? get launchUri {
    final uri = Uri.tryParse(verificationUrl ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.port != 443) {
      return null;
    }
    return uri.host == 'didit.me' || uri.host.endsWith('.didit.me')
        ? uri
        : null;
  }

  String get label => switch (status) {
    'APPROVED' => 'Đã xác minh',
    'DECLINED' => 'Không được duyệt',
    'EXPIRED' => 'Phiên đã hết hạn',
    'IN_REVIEW' => 'Đang xét duyệt',
    'PENDING' => expired ? 'Phiên đã hết hạn' : 'Chờ xác minh',
    'IN_PROGRESS' => 'Đang xác minh',
    'CANCELLED' || 'ABANDONED' => 'Phiên đã kết thúc',
    _ => 'Chưa có kết quả xác minh',
  };
}
