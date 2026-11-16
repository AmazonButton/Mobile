class CustomerBankAccount {
  final String id, bankName, maskedNumber, accountName, verificationStatus;
  final bool isDefault;
  const CustomerBankAccount({
    required this.id,
    required this.bankName,
    required this.maskedNumber,
    required this.accountName,
    required this.verificationStatus,
    required this.isDefault,
  });
  factory CustomerBankAccount.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Thiếu mã tài khoản');
    }
    return CustomerBankAccount(
      id: id,
      bankName: json['bankName']?.toString() ?? '',
      maskedNumber: json['accountNumberMasked']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      verificationStatus: json['verificationStatus']?.toString() ?? 'PENDING',
      isDefault: json['isDefault'] == true,
    );
  }
  bool get isVerified => verificationStatus == 'VERIFIED';
}

class BankVerificationState {
  final String accountStatus, paymentStatus, refundStatus;
  final bool expired;
  final num refundedAmount, pendingRefundAmount;
  final String? rejectionReason;
  const BankVerificationState({
    required this.accountStatus,
    required this.paymentStatus,
    required this.refundStatus,
    required this.expired,
    required this.refundedAmount,
    required this.pendingRefundAmount,
    this.rejectionReason,
  });
  factory BankVerificationState.fromJson(Map<String, dynamic> json) {
    final session = json['session'] is Map ? json['session'] as Map : const {};
    final summary = session['refundSummary'] is Map
        ? session['refundSummary'] as Map
        : const {};
    return BankVerificationState(
      accountStatus: json['accountVerificationStatus']?.toString() ?? 'PENDING',
      paymentStatus: session['paymentStatus']?.toString() ?? 'PENDING',
      refundStatus: session['refundStatus']?.toString() ?? 'NONE',
      expired: session['isExpired'] == true,
      refundedAmount:
          num.tryParse(summary['totalRefundedAmount']?.toString() ?? '') ?? 0,
      pendingRefundAmount:
          num.tryParse(summary['totalPendingRefundAmount']?.toString() ?? '') ??
          0,
      rejectionReason: session['rejectionReason']?.toString(),
    );
  }
  bool get isVerified => accountStatus == 'VERIFIED';
  String get verificationLabel => isVerified
      ? 'Đã xác minh chính chủ'
      : expired
      ? 'Phiên xác minh đã hết hạn'
      : rejectionReason != null
      ? 'Chưa xác minh được tài khoản'
      : paymentStatus == 'PAID'
      ? 'Đã nhận tiền — đang đối chiếu tài khoản'
      : 'Đang chờ xác minh';
  static String refundLabel(String status) => switch (status) {
    'REFUNDED' => 'Đã hoàn khoản xác minh',
    'PARTIALLY_REFUNDED' => 'Đã hoàn một phần khoản xác minh',
    'PROCESSING_REFUND' => 'Đang hoàn khoản xác minh',
    'PENDING_RECONCILIATION' => 'Đang đối soát khoản hoàn',
    'PENDING_MANUAL_REFUND' => 'Chờ xử lý khoản hoàn',
    'REFUND_FAILED' => 'Hoàn khoản xác minh chưa thành công',
    'PENDING_REFUND' => 'Đang chờ hoàn khoản xác minh',
    _ => 'Chưa có khoản xác minh cần hoàn',
  };
}
