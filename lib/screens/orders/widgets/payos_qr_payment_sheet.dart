import '../../../widgets/sample_a.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/order_model.dart';
import '../../../models/payos_payment_data.dart';
import '../../../providers/order_provider.dart';
import '../../../services/notification_service.dart';
import '../../../services/payments_api_service.dart';
import '../../../services/api_client.dart';
import 'order_status_views.dart';

/// Modal Bottom Sheet hiển thị mã VietQR PayOS và thông tin thanh toán trực tiếp
class PayosQrPaymentSheet extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onPaymentSuccess;

  const PayosQrPaymentSheet({
    super.key,
    required this.order,
    this.onPaymentSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required OrderModel order,
    VoidCallback? onPaymentSuccess,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) =>
          PayosQrPaymentSheet(order: order, onPaymentSuccess: onPaymentSuccess),
    );
  }

  @override
  State<PayosQrPaymentSheet> createState() => _PayosQrPaymentSheetState();
}

class _PayosQrPaymentSheetState extends State<PayosQrPaymentSheet> {
  final PaymentsApiService _paymentsService = PaymentsApiService();
  final String _paymentKey = PaymentsApiService.newPaymentKey();

  bool _isLoading = true;
  String? _errorMessage;
  PayosPaymentData? _paymentData;
  bool _isSuccess = false;

  Timer? _pollingTimer;
  int _pollingAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initRealTimeListener();
    _loadPaymentLink();
  }

  void _initRealTimeListener() {
    NotificationService.onPaymentConfirmed = (orderId, orderCode) {
      if (orderId == widget.order.id ||
          orderId == widget.order.orderCode ||
          orderCode == widget.order.orderCode) {
        markSuccess();
      }
    };
  }

  void _startAutoPolling() {
    _pollingTimer?.cancel();
    _pollingAttempts = 0;
    // Tự động kiểm tra trạng thái mỗi 3.5 giây tối đa 100 lần (~5.8 phút)
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      timer,
    ) async {
      _pollingAttempts++;
      if (_isSuccess || !mounted || _pollingAttempts > 100) {
        timer.cancel();
        return;
      }
      if (_paymentData != null && !_isChecking) {
        try {
          final res = await _paymentsService.getPaymentRequestInfo(
            _paymentData!.orderCode.toString(),
          );
          final status = (res['status'] ?? res['data']?['status'] ?? '')
              .toString()
              .toUpperCase();
          if (status == 'PAID') {
            timer.cancel();
            markSuccess();
          }
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    if (NotificationService.onPaymentConfirmed != null) {
      NotificationService.onPaymentConfirmed = null;
    }
    super.dispose();
  }

  Future<void> _loadPaymentLink() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _paymentsService.createPayosPaymentLink(
        orderId: widget.order.id,
        idempotencyKey: _paymentKey,
        description: 'DH${widget.order.orderCode.replaceAll('#', '')}',
      );
      if (mounted) {
        setState(() {
          _paymentData = data;
          _isLoading = false;
        });
        _startAutoPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiException
              ? e.message
              : 'Không thể tạo mã thanh toán. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String label, String value) {
    if (value.isEmpty) return;
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã sao chép $label: $value',
                style: const TextStyle(
                  fontFamily: SampleA.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openExternalPayos() async {
    if (_paymentData == null || _paymentData!.checkoutUrl.isEmpty) return;
    HapticFeedback.lightImpact();
    final uri = Uri.parse(_paymentData!.checkoutUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể mở liên kết thanh toán PayOS trên trình duyệt',
            ),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void markSuccess() {
    if (!mounted || _isSuccess) return;
    _pollingTimer?.cancel();
    HapticFeedback.heavyImpact();

    // Cập nhật OrderProvider trong bộ nhớ để toàn bộ UI phản ánh trạng thái PAID ngay lập tức
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.markOrderAsPaid(widget.order.id);
    } catch (_) {}

    setState(() {
      _isSuccess = true;
    });
    widget.onPaymentSuccess?.call();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  bool _isChecking = false;

  Future<void> _checkPaymentStatus() async {
    if (_paymentData == null || _isChecking) return;
    setState(() => _isChecking = true);
    HapticFeedback.lightImpact();

    try {
      final res = await _paymentsService.getPaymentRequestInfo(
        _paymentData!.orderCode.toString(),
      );
      final status = (res['status'] ?? res['data']?['status'] ?? '')
          .toString()
          .toUpperCase();
      if (status == 'PAID') {
        markSuccess();
        return;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Hệ thống chưa nhận được thanh toán. Vui lòng thử lại sau vài giây!',
              ),
              backgroundColor: Color(0xFFD97706),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa thể kiểm tra trạng thái lúc này. Vui lòng thử lại!',
            ),
            backgroundColor: Color(0xFF64748B),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ASheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Handle Indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: SampleA.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Row(
            children: [
              IconButton(
                tooltip: 'Quay lại',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  'Thanh toán đơn hàng',
                  style: TextStyle(
                    fontFamily: SampleA.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                'PayOS',
                style: TextStyle(
                  color: SampleA.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Text(
            widget.order.orderCode,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: SampleA.border),
          const SizedBox(height: 16),

          // Content Body
          _isSuccess
              ? _buildSuccessView()
              : _isLoading
              ? _buildLoadingView()
              : _errorMessage != null
              ? _buildErrorView()
              : _buildPaymentDetailsView(),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: const [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(SampleA.primary),
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Đang tạo mã VietQR từ PayOS...',
              style: TextStyle(
                fontFamily: SampleA.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertTriangle,
                color: Color(0xFFDC2626),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tạo mã thanh toán',
              style: TextStyle(
                fontFamily: SampleA.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage ?? 'Đã có lỗi xảy ra khi kết nối với cổng PayOS.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: SampleA.fontFamily,
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TactileButton(
              scale: 0.96,
              onTap: _loadPaymentLink,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: SampleA.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.rotateCcw, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Thử lại',
                      style: TextStyle(
                        fontFamily: SampleA.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.circleCheck,
                color: Color(0xFF059669),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thanh toán thành công!',
              style: TextStyle(
                fontFamily: SampleA.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đơn hàng của bạn đã được ghi nhận thanh toán.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: SampleA.fontFamily,
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsView() {
    final data = _paymentData!;
    final qrUrl = data.vietQrImageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: SampleA.pale,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Số tiền thanh toán',
                style: TextStyle(color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              Text(
                OrderModel.formatCurrency(data.amount),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  color: SampleA.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        // VietQR Container Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SampleA.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Badge VietQR
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0054A6).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'VietQR',
                      style: TextStyle(
                        fontFamily: SampleA.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0054A6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11922).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NAPAS 247',
                      style: TextStyle(
                        fontFamily: SampleA.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE11922),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // QR Code Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: CachedNetworkImage(
                    imageUrl: qrUrl,
                    fit: BoxFit.contain,
                    placeholder: (ctx, url) => Container(
                      color: const Color(0xFFF8FAFC),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.all(16),
                      child: const Center(
                        child: Text(
                          'Không thể tải ảnh QR\nVui lòng chuyển khoản theo thông tin bên dưới',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: SampleA.fontFamily,
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Quét mã bằng bất kỳ App Ngân hàng nào để thanh toán',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: SampleA.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Transfer Information Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SampleA.border),
          ),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Thông tin chuyển khoản',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              // Số tiền
              _buildInfoRow(
                label: 'Số tiền thanh toán',
                value: OrderModel.formatCurrency(data.amount),
                isHighlight: true,
                onCopy: () =>
                    _copyToClipboard('số tiền', data.amount.toInt().toString()),
              ),
              const Divider(height: 18, color: SampleA.border),

              // Tên ngân hàng nếu có
              if (data.bankName != null && data.bankName!.isNotEmpty) ...[
                _buildInfoRow(
                  label: 'Ngân hàng thụ hưởng',
                  value: data.bankName!,
                ),
                const Divider(height: 18, color: SampleA.border),
              ],

              // Số tài khoản
              if (data.accountNumber != null &&
                  data.accountNumber!.isNotEmpty) ...[
                _buildInfoRow(
                  label: 'Số tài khoản',
                  value: data.accountNumber!,
                  onCopy: () =>
                      _copyToClipboard('số tài khoản', data.accountNumber!),
                ),
                const Divider(height: 18, color: SampleA.border),
              ],

              // Tên chủ tài khoản
              if (data.accountName != null && data.accountName!.isNotEmpty) ...[
                _buildInfoRow(
                  label: 'Người thụ hưởng',
                  value: data.accountName!,
                ),
                const Divider(height: 18, color: SampleA.border),
              ],

              // Nội dung chuyển khoản (CRITICAL)
              _buildInfoRow(
                label: 'Nội dung chuyển khoản',
                value: data.description,
                isContent: true,
                onCopy: () => _copyToClipboard('nội dung', data.description),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4DE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Đang chờ thanh toán',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Important Note Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: 15, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vui lòng giữ nguyên số tiền và nội dung chuyển khoản. Trạng thái sẽ cập nhật khi hệ thống xác nhận.',
                  style: TextStyle(
                    fontFamily: SampleA.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF92400E),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        SizedBox(
          width: double.infinity,
          child: TactileButton(
            scale: 0.96,
            onTap: _openExternalPayos,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: SampleA.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: SampleA.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.externalLink, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Mở cổng thanh toán PayOS',
                    style: TextStyle(
                      fontFamily: SampleA.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Check Payment Status Button
        SizedBox(
          width: double.infinity,
          child: TactileButton(
            scale: 0.96,
            onTap: _isChecking ? () {} : _checkPaymentStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SampleA.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isChecking) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SampleA.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    const Icon(
                      LucideIcons.refreshCw,
                      size: 15,
                      color: SampleA.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _isChecking
                        ? 'Đang kiểm tra giao dịch...'
                        : 'Tôi đã chuyển khoản xong',
                    style: const TextStyle(
                      fontFamily: SampleA.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: SampleA.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Close Button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Quay lại đơn hàng',
              style: TextStyle(
                fontFamily: SampleA.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isHighlight = false,
    bool isContent = false,
    VoidCallback? onCopy,
  }) {
    return AInfoRow(
      label: label,
      value: value,
      onCopy: onCopy,
      highlight: isHighlight,
    );
  }
}
