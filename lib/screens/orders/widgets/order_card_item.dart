import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/order_model.dart';
import '../../../widgets/sample_a.dart';
import 'payos_qr_payment_sheet.dart';

class OrderCardItem extends StatelessWidget {
  final OrderModel order;
  final int cancelCountdown;
  final bool isReordering;
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
    this.isReordering = false,
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
    final showPayment = order.canPay && order.isPayos && order.isPending;
    final showReorder = order.isCompleted && onReorder != null;
    final openDetails = onDetailTap ?? onTrack;
    final cancel = onEmergencyCancel ?? onCancel;
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
              Text(order.orderCode, style: SampleA.section),
              OrderStatusBadge(order: order),
            ],
          ),
          if (order.storeName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(order.storeName, style: SampleA.caption)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: OrderProductLine(order: order),
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
              const Text('Tổng tiền', style: SampleA.body),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(order.price, style: SampleA.section),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: order.isPaid
                          ? const Color(0xFFDCFCE7)
                          : SampleA.warningLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      order.paymentStatus == 'REFUNDED'
                          ? 'Đã hoàn tiền'
                          : order.isPaid
                          ? 'Đã thanh toán'
                          : 'Chưa thanh toán',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: order.isPaid ? SampleA.success : SampleA.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (order.time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(order.time, style: SampleA.caption),
            ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final primary = AButton(
                label: showPayment
                    ? 'Thanh toán'
                    : showReorder
                    ? 'Đặt lại'
                    : order.isTerminal
                    ? 'Xem chi tiết'
                    : 'Theo dõi đơn',
                kind: showPayment || showReorder
                    ? AButtonKind.primary
                    : AButtonKind.secondary,
                busy: isReordering,
                onPressed: showPayment
                    ? onPay ??
                          () => PayosQrPaymentSheet.show(context, order: order)
                    : showReorder
                    ? onReorder
                    : order.isTerminal
                    ? openDetails
                    : onTrack ?? openDetails,
              );
              if (!(showPayment || showReorder) || openDetails == null) {
                return primary;
              }
              final secondary = AButton(
                label: 'Xem chi tiết',
                onPressed: openDetails,
                kind: AButtonKind.secondary,
              );
              if (constraints.maxWidth < 330 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [primary, const SizedBox(height: 8), secondary],
                );
              }
              return Row(
                children: [
                  Expanded(child: primary),
                  const SizedBox(width: 10),
                  Expanded(child: secondary),
                ],
              );
            },
          ),
          if (emergency && cancel != null) ...[
            const SizedBox(height: 8),
            AButton(
              label: 'Hủy đơn · 00:${_seconds.toString().padLeft(2, '0')}',
              onPressed: cancel,
              kind: AButtonKind.danger,
            ),
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
    final awaitingPayment = order.isUnpaid && order.isPayos && order.isPending;
    final label = awaitingPayment
        ? 'Chờ thanh toán'
        : OrderModel.lifecycleLabel(order.rawStatus);
    final icon = switch (order.status) {
      OrderStatus.danger => LucideIcons.x,
      OrderStatus.success => LucideIcons.check,
      OrderStatus.warning => LucideIcons.clock,
      OrderStatus.info =>
        order.isShipping ? LucideIcons.truck : LucideIcons.package,
    };
    final color = order.statusColor;
    final background = order.statusBgColor;
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
        size: 76,
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
            if (order.items.isNotEmpty)
              Text('x${order.items.first.quantity}', style: SampleA.caption),
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
    final status = rawStatus ?? (isShipping ? 'SHIPPING' : 'PENDING');
    final stage = OrderModel.timelineStage(status);
    final labels = OrderModel.timelineLabels;
    if (stage < 0 || status == 'DELIVERY_FAILED') {
      return Text(OrderModel.lifecycleLabel(status), style: SampleA.body);
    }
    return Semantics(
      label:
          'Tiến trình đơn hàng. Bước ${stage + 1} trên ${labels.length}. '
          '${labels[stage]}',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: ColoredBox(
                      color: i <= stage ? SampleA.primary : SampleA.border,
                      child: const SizedBox(height: 3),
                    ),
                  ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= stage ? SampleA.primary : Colors.white,
                    border: Border.all(
                      color: i <= stage ? SampleA.primary : SampleA.border,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: i < stage || stage == labels.length - 1
                      ? const Icon(
                          LucideIcons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : i == stage
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 6, height: 6),
                        )
                      : null,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(labels.first, style: SampleA.caption)),
              Expanded(
                child: Text(
                  labels.last,
                  style: SampleA.caption,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
