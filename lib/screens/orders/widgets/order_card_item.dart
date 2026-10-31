import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/order_model.dart';
import '../../../widgets/sample_a.dart';
import 'payos_qr_payment_sheet.dart';

class OrderCardItem extends StatelessWidget {
  final OrderModel order;
  final int cancelCountdown;
  final VoidCallback? onEmergencyCancel,
      onCancel,
      onReorder,
      onTrack,
      onPay,
      onDetailTap;
  const OrderCardItem({
    super.key,
    required this.order,
    this.cancelCountdown = 60,
    this.onEmergencyCancel,
    this.onCancel,
    this.onReorder,
    this.onTrack,
    this.onPay,
    this.onDetailTap,
  });
  int get _seconds => order.createdAt != null
      ? order.remainingSafetySeconds
      : cancelCountdown.clamp(0, 60);
  @override
  Widget build(BuildContext context) {
    final past = order.isCompleted || order.isCancelled;
    final canPay = order.isUnpaid && !past;
    final emergency = order.isPending && _seconds > 0;
    return ACard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OrderStatusBadge(order: order),
              Text(
                order.orderCode,
                style: SampleA.caption.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onDetailTap ?? onTrack,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: OrderProductLine(order: order),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: SampleA.border, height: 1),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(order.price, style: SampleA.title.copyWith(fontSize: 22)),
              Text(
                order.isPaid
                    ? 'Đã thanh toán'
                    : order.isPayos
                    ? 'PayOS'
                    : 'COD',
                style: SampleA.caption,
              ),
            ],
          ),
          if (order.time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(order.time, style: SampleA.caption),
            ),
          const SizedBox(height: 8),
          if (past) ...[
            AButton(
              label: order.isCancelled || onReorder == null
                  ? 'Xem chi tiết'
                  : 'Đặt lại',
              onPressed: order.isCancelled || onReorder == null
                  ? onDetailTap
                  : onReorder,
              kind: AButtonKind.secondary,
            ),
            if (!order.isCancelled && onDetailTap != null)
              TextButton(
                onPressed: onDetailTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: SampleA.primary,
                ),
                child: const Text(
                  'Chi tiết',
                  style: TextStyle(fontFamily: 'SampleA Vietnam', fontSize: 14),
                ),
              ),
          ] else ...[
            if (canPay && order.isPayos && order.isPending)
              AButton(
                label: 'Thanh toán',
                onPressed:
                    onPay ??
                    () => PayosQrPaymentSheet.show(context, order: order),
              ),
            if (!(canPay && order.isPayos && order.isPending))
              AButton(label: 'Theo dõi đơn', onPressed: onTrack ?? onDetailTap)
            else
              TextButton(
                onPressed: onTrack ?? onDetailTap,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: SampleA.primary,
                ),
                child: const Text('Xem chi tiết'),
              ),
            if (emergency && (onEmergencyCancel ?? onCancel) != null) ...[
              const SizedBox(height: 8),
              AButton(
                label: 'Hủy đơn · 00:${_seconds.toString().padLeft(2, '0')}',
                onPressed: onEmergencyCancel ?? onCancel,
                kind: AButtonKind.danger,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  final OrderModel order;
  const OrderStatusBadge({super.key, required this.order});
  @override
  Widget build(BuildContext context) {
    final (label, icon, color, background) = order.isCancelled
        ? ('Đã hủy', LucideIcons.x, SampleA.danger, SampleA.dangerLight)
        : order.isCompleted
        ? (
            'Đã giao',
            LucideIcons.check,
            SampleA.success,
            const Color(0xFFECFDF5),
          )
        : order.isUnpaid && order.isPayos && order.isPending
        ? (
            'Chờ thanh toán',
            LucideIcons.clock,
            SampleA.warning,
            SampleA.warningLight,
          )
        : order.isShipping
        ? ('Đang giao', LucideIcons.truck, SampleA.primary, SampleA.pale)
        : order.isPending
        ? (
            'Chờ xác nhận',
            LucideIcons.clock,
            SampleA.warning,
            SampleA.warningLight,
          )
        : ('Đang xử lý', LucideIcons.package, SampleA.primary, SampleA.pale);
    return AStatus(
      label: label,
      icon: icon,
      color: color,
      background: background,
    );
  }
}

class OrderProductLine extends StatelessWidget {
  final OrderModel order;
  const OrderProductLine({super.key, required this.order});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      AProductImage(
        product: order.product,
        imageUrl: order.items.isNotEmpty ? order.items.first.imageUrl : null,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.displayTitle,
              style: SampleA.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (order.storeName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(order.storeName, style: SampleA.caption),
              ),
          ],
        ),
      ),
    ],
  );
}

/// Progress is derived only from server state; no invented delivery times.
class OrderTimeline extends StatelessWidget {
  final bool isShipping;
  final String? rawStatus;
  const OrderTimeline({super.key, this.isShipping = false, this.rawStatus});
  @override
  Widget build(BuildContext context) {
    final stage = switch (rawStatus) {
      'DELIVERED' || 'COMPLETED' => 3,
      'SHIPPING' => 2,
      'CONFIRMED' || 'PROCESSING' => 1,
      _ => isShipping ? 2 : 0,
    };
    final labels = [
      'Đã đặt',
      'Đã xác nhận',
      'Đang giao hàng',
      'Giao thành công',
    ];
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= stage ? SampleA.primary : Colors.white,
                    border: Border.all(
                      color: i <= stage ? SampleA.primary : SampleA.border,
                      width: 2,
                    ),
                  ),
                  child: i < stage
                      ? const Icon(
                          LucideIcons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    labels[i],
                    style: SampleA.body.copyWith(
                      color: i <= stage ? SampleA.ink : SampleA.muted,
                      fontWeight: i == stage
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
