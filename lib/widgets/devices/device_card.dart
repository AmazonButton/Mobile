import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Minimalist Tactile Device Card matching the modern simplified design.
class DeviceCard extends StatelessWidget {
  final String id;
  final String name;
  final String room;
  final String product;
  final String price;
  final int batteryLevel;
  final String? imageUrl;
  final String badgeText;
  final String signal;
  final bool isOnline;
  final VoidCallback? onTap;
  final VoidCallback? onSettings;
  final VoidCallback? onOrder;
  final String state;
  final bool showOrderButton;

  const DeviceCard({
    super.key,
    required this.id,
    required this.name,
    required this.room,
    required this.product,
    required this.price,
    required this.batteryLevel,
    this.imageUrl,
    this.badgeText = '20L',
    this.signal = 'Rất tốt',
    this.isOnline = true,
    this.onTap,
    this.onSettings,
    this.onOrder,
    this.state = 'idle',
    this.showOrderButton = false,
  });

  bool get _isGas {
    final lower = '$name $product'.toLowerCase();
    return lower.contains('gas') || lower.contains('bếp ga') || lower.contains('petrolimex');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Top Row: Icon + Name & Room + Settings Gear ──
            Row(
              children: [
                // Minimalist category icon box
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

                // Name and Room
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Gear Settings Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSettings?.call();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.settings,
                        size: 18,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── 2. Middle Row: Product & Price Strip ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── 3. Bottom Row: Online Status & Battery ──
            Row(
              children: [
                // Online Indicator
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),

                const SizedBox(width: 16),

                // Battery Indicator
                Icon(
                  LucideIcons.battery,
                  size: 14,
                  color: batteryLevel <= 20 ? const Color(0xFFD97706) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 5),
                Text(
                  price.contains('[') ? 'Pin [%]' : 'Pin $batteryLevel%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: batteryLevel <= 20 ? const Color(0xFFD97706) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
