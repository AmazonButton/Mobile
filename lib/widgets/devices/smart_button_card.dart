import '../sample_a.dart';
import '../device_stock_status.dart';
import '../../services/stock_service.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Minimalist SmartButtonCard matching Screen 1 in the design.
class SmartButtonCard extends StatelessWidget {
  final String id;
  final String name;
  final String? room;
  final String? storeName;
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
    this.storeName,
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
      const blue = SampleA.primary;
      final fallback = Icon(LucideIcons.package, size: 44, color: blue);
      return Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E8F5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x090F172A),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 132,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF5F9FF), Color(0xFFDEECFF)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 32,
                    bottom: 6,
                    left: 6,
                    right: 6,
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
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                          ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7E7FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: onSettings,
                      tooltip: 'Cài đặt thiết bị',
                      icon: const Icon(LucideIcons.slidersHorizontal, size: 19),
                      style: IconButton.styleFrom(foregroundColor: blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: SampleA.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              storeName?.trim().isNotEmpty == true
                  ? storeName!
                  : 'Sản phẩm đã gán',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 3),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: SampleA.ink,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: battery.clamp(0, 100) / 100,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(5),
                    color: battery <= 15 ? const Color(0xFFEF4444) : blue,
                    backgroundColor: const Color(0xFFDCE5F3),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Pin ${battery.clamp(0, 100)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            if (blocked) ...[
              const SizedBox(height: 6),
              DeviceStockStatus(deviceId: id),
            ],
            const SizedBox(height: 8),
            Semantics(
              liveRegion: ordering || ordered,
              child: FilledButton(
                onPressed: ordering || ordered || blocked ? null : onOrder,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  backgroundColor: blue,
                  disabledForegroundColor: const Color(0xFF475569),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Text(
                  ordering
                      ? 'Đang đặt…'
                      : ordered
                      ? 'Đã đặt'
                      : blocked
                      ? 'Chưa thể đặt hàng'
                      : 'Đặt hàng',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
