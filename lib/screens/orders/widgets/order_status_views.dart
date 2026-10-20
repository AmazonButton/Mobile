import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/order_model.dart';
import '../../../utils/formatters.dart';

/// Nút bấm có hiệu ứng co giãn xúc giác và haptic feedback
class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const TactileButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Giao diện trống hiển thị khi không có đơn hàng
class OrderEmptyView extends StatelessWidget {
  final bool isHistory;

  const OrderEmptyView({super.key, this.isHistory = false});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              Icon(
                isHistory ? LucideIcons.history : LucideIcons.packageCheck,
                size: 40,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 14),
              Text(
                isHistory
                    ? 'Chưa có đơn hàng nào trong lịch sử'
                    : 'Không có đơn hàng nào đang diễn ra',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isHistory
                    ? 'Lịch sử các đơn hàng đã nhận hoặc đã hủy sẽ hiển thị tại đây.'
                    : 'Nhấn nút vật lý hoặc bấm đặt trên ứng dụng để khởi tạo đơn hàng mới.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Giao diện thông báo lỗi kết nối và nút thử lại
class OrderErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const OrderErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFEE2E2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626), size: 28),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải đơn hàng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.rotateCcw, size: 16),
                label: const Text(
                  'Thử lại',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Thẻ thống kê tổng chi tiêu và số lượng đơn hàng trong tab lịch sử
class OrderHistoryStatsCard extends StatelessWidget {
  final int totalOrders;
  final num totalSpend;

  const OrderHistoryStatsCard({
    super.key,
    required this.totalOrders,
    required this.totalSpend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                LucideIcons.barChart2,
                size: 20,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TỔNG KẾT ĐƠN HÀNG',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalOrders đơn',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng chi: ${CurrencyFormatter.format(totalSpend)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hộp thoại xác nhận hủy đơn khẩn cấp
class OrderCancelDialog {
  static void show(
    BuildContext context, {
    required String orderTitle,
    String? buttonName,
    String? price,
    String? orderCode,
    String? storeName,
    OrderModel? order,
    required Future<void> Function() onConfirm,
  }) {
    final effectiveTitle = order?.displayTitle ?? orderTitle;
    final effectiveButton = order?.buttonName ?? buttonName ?? 'Nút bấm IoT';
    final effectivePrice = order?.price ?? price;
    final effectiveCode = order?.orderCode ?? orderCode;
    final effectiveStore = order?.storeName ?? storeName;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldAlert, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Hủy đơn khẩn cấp',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          effectiveTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (effectivePrice != null && effectivePrice.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            effectivePrice,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.radio, size: 13, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      const Text(
                        'Nút đặt: ',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Expanded(
                        child: Text(
                          effectiveButton,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (effectiveCode != null && effectiveCode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.hash, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          'Mã đơn: $effectiveCode',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        if (effectiveStore != null && effectiveStore.isNotEmpty) ...[
                          const Spacer(),
                          Text(
                            effectiveStore,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đơn hàng đang trong thời gian an toàn 60 giây. Bạn có chắc chắn muốn hủy đơn hàng này ngay bây giờ không?',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text(
              'Giữ đơn',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.x, size: 15, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Xác nhận hủy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
