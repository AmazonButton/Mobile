class PayosPaymentData {
  final String paymentTransactionId;
  final int orderCode;
  final num amount;
  final String description;
  final String checkoutUrl;
  final String qrCode;
  final String? paymentLinkId;
  final String status;
  final String? accountName;
  final String? accountNumber;
  final String? bin;
  final String? bankName;

  const PayosPaymentData({
    required this.paymentTransactionId,
    required this.orderCode,
    required this.amount,
    required this.description,
    required this.checkoutUrl,
    required this.qrCode,
    this.paymentLinkId,
    this.status = 'PENDING',
    this.accountName,
    this.accountNumber,
    this.bin,
    this.bankName,
  });

  factory PayosPaymentData.fromJson(Map<String, dynamic> json) {
    final orderCodeRaw = json['orderCode'];
    final int orderCode = orderCodeRaw is int
        ? orderCodeRaw
        : int.tryParse(orderCodeRaw?.toString() ?? '0') ?? 0;

    final amountRaw = json['amount'];
    final num amount = amountRaw is num
        ? amountRaw
        : num.tryParse(amountRaw?.toString() ?? '0') ?? 0;

    return PayosPaymentData(
      paymentTransactionId: json['paymentTransactionId']?.toString() ?? '',
      orderCode: orderCode,
      amount: amount,
      description: json['description']?.toString() ?? 'DH$orderCode',
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
      paymentLinkId: json['paymentLinkId']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      accountName: json['accountName']?.toString() ?? json['accountHolder']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      bin: json['bin']?.toString() ?? json['bankBin']?.toString(),
      bankName: json['bankName']?.toString() ?? json['bank']?.toString(),
    );
  }

  /// URL hình ảnh mã QR VietQR tối ưu để render lên Flutter UI
  String get vietQrImageUrl {
    // 1. Nếu qrCode là URL hình ảnh trực tiếp
    if (qrCode.startsWith('http://') || qrCode.startsWith('https://')) {
      return qrCode;
    }

    // 2. Nếu có BIN và số tài khoản ngân hàng, sinh ảnh VietQR chuẩn Napas 247
    if (bin != null && bin!.isNotEmpty && accountNumber != null && accountNumber!.isNotEmpty) {
      final safeDesc = Uri.encodeComponent(description);
      final safeName = accountName != null && accountName!.isNotEmpty
          ? Uri.encodeComponent(accountName!)
          : '';
      return 'https://img.vietqr.io/image/$bin-$accountNumber-compact2.png?amount=${amount.toInt()}&addInfo=$safeDesc&accountName=$safeName';
    }

    // 3. Fallback: Render mã QR từ chuỗi EMVCo hoặc checkoutUrl
    final dataToEncode = qrCode.isNotEmpty ? qrCode : checkoutUrl;
    return 'https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=${Uri.encodeComponent(dataToEncode)}';
  }

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isPaid => status.toUpperCase() == 'PAID';
}
