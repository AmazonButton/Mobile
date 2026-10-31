import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/order_model.dart';
import '../../../widgets/sample_a.dart';
import 'order_card_item.dart';
import 'payos_qr_payment_sheet.dart';

class OrderDetailBottomSheet extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onReorder, onCancel;
  const OrderDetailBottomSheet({
    super.key,
    required this.order,
    this.onReorder,
    this.onCancel,
  });
  static void show(
    BuildContext context, {
    required OrderModel order,
    VoidCallback? onReorder,
    VoidCallback? onCancel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => OrderDetailBottomSheet(
        order: order,
        onReorder: onReorder,
        onCancel: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .9,
    minChildSize: .45,
    maxChildSize: .96,
    builder: (context, controller) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Chi tiết đơn hàng', style: SampleA.section),
                ),
                AIconButton(
                  icon: LucideIcons.x,
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ACard(
              color: SampleA.pale,
              border: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrderStatusBadge(order: order),
                  const SizedBox(height: 12),
                  Text(
                    order.orderCode,
                    style: SampleA.title.copyWith(fontSize: 24),
                  ),
                  if (order.time.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(order.time, style: SampleA.caption),
                    ),
                ],
              ),
            ),
            if (!order.isCancelled) ...[
              const SizedBox(height: 16),
              OrderTimeline(rawStatus: order.rawStatus),
            ],
            if (order.apartment.isNotEmpty) ...[
              const SizedBox(height: 16),
              ACard(
                color: const Color(0xFFF8FAFC),
                border: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.mapPin, color: SampleA.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (order.customerName.isNotEmpty)
                            Text(
                              order.customerName,
                              style: SampleA.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          Text(order.apartment, style: SampleA.body),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            OrderProductLine(order: order),
            if (order.items.length > 1) ...[
              const SizedBox(height: 12),
              for (final item in order.items.skip(1))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${item.quantity} × ${item.name}',
                    style: SampleA.body,
                  ),
                ),
            ],
            const SizedBox(height: 20),
            const Divider(color: SampleA.border),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                const Text('Tổng thanh toán', style: SampleA.body),
                Text(order.price, style: SampleA.title.copyWith(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.isPaid
                  ? 'Đã thanh toán · ${order.paymentMethod}'
                  : order.isPayos
                  ? 'Chưa thanh toán · PayOS'
                  : 'Thanh toán khi nhận hàng',
              style: SampleA.caption,
            ),
            const SizedBox(height: 24),
            if (order.isUnpaid && !order.isCancelled && !order.isCompleted) ...[
              AButton(
                label: order.isPayos
                    ? 'Thanh toán'
                    : 'Thanh toán trước bằng PayOS',
                onPressed: () =>
                    PayosQrPaymentSheet.show(context, order: order),
              ),
              const SizedBox(height: 12),
            ],
            if (order.isEmergencyCancellable && onCancel != null) ...[
              AButton(
                label: 'Hủy đơn hàng này',
                kind: AButtonKind.danger,
                onPressed: () {
                  Navigator.pop(context);
                  onCancel!();
                },
              ),
              const SizedBox(height: 12),
            ],
            if (order.isCompleted && onReorder != null) ...[
              AButton(
                label: 'Đặt lại đơn này',
                onPressed: () {
                  Navigator.pop(context);
                  onReorder!();
                },
              ),
              const SizedBox(height: 12),
            ],
            AButton(
              label: 'Quay lại đơn hàng',
              kind: AButtonKind.secondary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}
