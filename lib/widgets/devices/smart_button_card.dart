import '../device_stock_status.dart';
import '../../services/stock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Minimalist SmartButtonCard matching Screen 1 in the design.
class SmartButtonCard extends StatelessWidget {
  final String id;
  final String name;
  final String? room;
  final String product;
  final String price;
  final int battery;
  final String? imageUrl;
  final String badgeText;
  final String state; // 'idle', 'ordering', 'ordered'
  final VoidCallback? onOrder;
  final VoidCallback? onSettings;

  const SmartButtonCard({
    super.key,
    required this.id,
    required this.name,
    this.room,
    required this.product,
    required this.price,
    required this.battery,
    this.imageUrl,
    this.badgeText = '20L',
    this.state = 'idle',
    this.onOrder,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: StockService.instance,
    builder: (context, _) {
      final ordering = state == 'ordering';
      final ordered = state == 'ordered';
      final blocked = StockService.instance.problem(id) != null;
      final url = imageUrl?.trim();
      const blue = Color(0xFF2563EB);
      final fallback = Icon(LucideIcons.package, size: 25, color: blue);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E8F5)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDCE7FF)),
              ),
              child: ClipOval(
                child: ColoredBox(
                  color: const Color(0xFFF0F5FF),
                  child: url == null || url.isEmpty
                      ? Center(child: fallback)
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Center(child: fallback),
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$product · $price',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (blocked) ...[
                    const SizedBox(height: 4),
                    DeviceStockStatus(deviceId: id),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: ordering
                    ? 'Đang đặt hàng'
                    : ordered
                    ? 'Đã đặt'
                    : blocked
                    ? 'Chưa thể đặt hàng'
                    : 'Đặt hàng',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEDF3FF),
                  foregroundColor: blue,
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: ordering || ordered || blocked
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onOrder?.call();
                      },
                icon: ordering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        ordered ? Icons.check_rounded : Icons.add_rounded,
                        size: 23,
                      ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
