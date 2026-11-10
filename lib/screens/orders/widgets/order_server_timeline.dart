import 'package:flutter/material.dart';
import '../../../models/order_model.dart';
import '../../../models/order_timeline_entry.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/sample_a.dart';

class OrderServerTimeline extends StatelessWidget {
  final List<OrderTimelineEntry> entries;
  const OrderServerTimeline({super.key, required this.entries});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Lịch sử đơn hàng', style: SampleA.section),
      if (entries.isEmpty)
        const Text('Chưa có sự kiện trong lịch sử đơn hàng.'),
      for (final entry in entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                entry.type == 'STATUS_CHANGE' && entry.status != null
                    ? OrderModel.lifecycleLabel(entry.status!)
                    : entry.title,
                style: SampleA.body.copyWith(fontWeight: FontWeight.w700),
              ),
              if (entry.description.isNotEmpty)
                Text(entry.description, style: SampleA.caption),
              Text(
                entry.timestamp == null
                    ? 'Chưa có thời gian xác nhận'
                    : DateTimeFormatter.formatDateTime(entry.timestamp!),
                style: SampleA.caption,
              ),
              if (entry.podImageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    label: 'Ảnh xác nhận giao hàng',
                    image: true,
                    child: Image.network(
                      entry.podImageUrl!,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Text('Không thể tải ảnh xác nhận giao hàng.'),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}
