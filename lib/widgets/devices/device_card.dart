import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../sample_a.dart';

/// Device management card; ordering remains on Home and device detail.
class DeviceCard extends StatelessWidget {
  final String id, name, room, product, price, badgeText, signal, state;
  final int batteryLevel;
  final String? imageUrl, storeName;
  final bool isOnline, showOrderButton;
  final VoidCallback? onTap, onSettings, onOrder, onSelectProduct;
  const DeviceCard({
    super.key,
    required this.id,
    required this.name,
    required this.room,
    required this.product,
    required this.price,
    required this.batteryLevel,
    this.imageUrl,
    this.storeName,
    this.badgeText = '20L',
    this.signal = 'Rất tốt',
    this.isOnline = true,
    this.onTap,
    this.onSettings,
    this.onOrder,
    this.onSelectProduct,
    this.state = 'idle',
    this.showOrderButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final unassigned = product == 'Chưa gán sản phẩm';
    final battery = batteryLevel.clamp(0, 100);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: SampleA.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: const Color(0xFFF0F3F8),
                  child: unassigned
                      ? SizedBox(
                          width: largeText ? 60 : 90,
                          height: largeText ? 80 : 108,
                          child: const Icon(
                            LucideIcons.circleDot,
                            size: 45,
                            color: SampleA.muted,
                          ),
                        )
                      : AProductImage(
                          product: product,
                          imageUrl: imageUrl,
                          size: largeText ? 60 : 90,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: SampleA.section.copyWith(fontSize: 17)),
                    const SizedBox(height: 7),
                    _line(LucideIcons.package, product),
                    if (!unassigned && storeName?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      _line(LucideIcons.store, storeName!),
                    ],
                    if (unassigned)
                      TextButton(
                        onPressed: onSelectProduct,
                        child: const Text('Chọn sản phẩm'),
                      )
                    else ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 44,
                            child: LinearProgressIndicator(
                              value: battery / 100,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              color: battery <= 20
                                  ? SampleA.warning
                                  : SampleA.success,
                              backgroundColor: SampleA.border,
                            ),
                          ),
                          Text(
                            'Pin $battery%',
                            style: SampleA.caption.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    if (!isOnline)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Mất kết nối',
                          style: TextStyle(color: SampleA.danger, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cài đặt $name',
                onPressed: onSettings ?? onTap,
                icon: const Icon(LucideIcons.chevronRight, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: SampleA.ink),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text, style: SampleA.caption.copyWith(fontSize: 13)),
      ),
    ],
  );
}
