import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../app_motion.dart';

/// Thẻ quản lý thiết bị nhỏ gọn, hiện đại với logo nhỏ và nút xóa tiện lợi.
class DeviceCard extends StatelessWidget {
  final String id, name, room, product, price, badgeText, signal, state;
  final int batteryLevel;
  final String? imageUrl, storeName;
  final bool isOnline, showOrderButton;
  final VoidCallback? onTap, onSettings, onOrder, onSelectProduct, onDelete;

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
    this.onDelete,
    this.state = 'idle',
    this.showOrderButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final unassigned = product == 'Chưa gán sản phẩm' || product.trim().isEmpty;
    final battery = batteryLevel.clamp(0, 100);
    final isLowBattery = battery <= 20;

    return TactilePress(
      scaleDown: 0.985,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppMotion.cardShadow,
        ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── LOGO THUMBNAIL NHỎ GỌN (52x52) ──
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: unassigned
                          ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]
                          : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: unassigned ? const Color(0xFFCBD5E1) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: imageUrl != null && imageUrl!.trim().isNotEmpty
                        ? Image.network(
                            imageUrl!.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                unassigned ? LucideIcons.radio : LucideIcons.packageCheck,
                                size: 24,
                                color: unassigned ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              unassigned ? LucideIcons.radio : LucideIcons.packageCheck,
                              size: 24,
                              color: unassigned ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // ── NỘI DUNG CHI TIẾT NÚT ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (unassigned) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Chưa gán sản phẩm',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (onSelectProduct != null)
                              InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onSelectProduct?.call();
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'Gán món ngay',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          product,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        if (storeName?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            storeName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isLowBattery ? LucideIcons.batteryLow : LucideIcons.batteryMedium,
                              size: 13,
                              color: isLowBattery ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pin $battery%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isLowBattery ? const Color(0xFFEF4444) : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // ── NÚT XÓA BỚT DATA NÚT RỖNG / THÙNG RÁC ──
                if (onDelete != null)
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDelete?.call();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.trash2,
                          size: 15,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),

                // Mũi tên xem chi tiết
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
