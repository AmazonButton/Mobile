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

  bool get _isGas {
    final lower = '$name $product'.toLowerCase();
    return lower.contains('gas') || lower.contains('petrolimex') || lower.contains('bếp ga');
  }

  @override
  Widget build(BuildContext context) {
    final isOrdering = state == 'ordering';
    final isOrdered = state == 'ordered';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
          // ── Category Icon Box ──
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isGas ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                _isGas ? LucideIcons.flame : LucideIcons.droplets,
                size: 20,
                color: _isGas ? const Color(0xFFEA580C) : const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ── Title & Price/Subtext ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                if (_isGas) ...[
                  Text(
                    product,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      if (battery <= 20) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Pin $battery%',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── "Đặt ngay" Button ──
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (!isOrdering) {
                onOrder?.call();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: isOrdered
                    ? const Color(0xFF16A34A)
                    : isOrdering
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (!isOrdering)
                    BoxShadow(
                      color: (isOrdered
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF2563EB))
                          .withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Text(
                isOrdered
                    ? 'Đã đặt'
                    : isOrdering
                        ? 'Đang gửi...'
                        : 'Đặt ngay',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
