import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable tactile bounce helper: scales down to 0.96 on press.
class _TactileBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TactileBounce({required this.child, this.onTap});

  @override
  State<_TactileBounce> createState() => _TactileBounceState();
}

class _TactileBounceState extends State<_TactileBounce> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Standalone tactile device card conforming to Anti-AI & Big Tech standards.
///
/// Features:
/// - Flat design with pure Colors.white and thin Border.all(color: Color(0xFFE2E8F0), width: 1)
/// - No heavy box shadow
/// - Settings gear button (LucideIcons.settings) inside soft gray circular container Color(0xFFF1F5F9)
/// - Battery level detection:
///     * batteryLevel > 20: Green LucideIcons.battery and normal text
///     * batteryLevel <= 20: Red icon and text, pulsing fade animation, and low-battery alert banner
/// - High-resolution product thumbnail with CachedNetworkImage & Shimmer
/// - Tactile micro-interactions (0.96 scale on tap)
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
  final String state; // 'idle', 'ordering', 'ordered'
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

  bool get _isLowBattery => batteryLevel <= 20;

  String get _resolvedImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    final lower = product.toLowerCase();
    if (lower.contains('gas') || lower.contains('petrolimex')) {
      return 'https://images.unsplash.com/photo-1584281722572-881585869106?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('gạo') || lower.contains('st25')) {
      return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('giấy') || lower.contains('pulppy')) {
      return 'https://images.unsplash.com/photo-1584556812952-905ffd0c611a?w=200&auto=format&fit=crop&q=80';
    }
    return 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=200&auto=format&fit=crop&q=80';
  }

  Widget _buildBadge({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Thumbnail + Info + Gear Settings Button ──
            Row(
              children: [
                // 1. Product Thumbnail
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _resolvedImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: const Color(0xFFE2E8F0),
                            highlightColor: const Color(0xFFF8FAFC),
                            child: Container(color: const Color(0xFFE2E8F0)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(
                                LucideIcons.package,
                                size: 22,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                        // Smart badge
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // 2. Titles (Name & Room)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status indicator LED dot
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        room,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          children: [
                            TextSpan(text: '$product • '),
                            TextSpan(
                              text: price,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // 3. Tactile Gear Settings Button (LucideIcons.settings in Color(0xFFF1F5F9))
                _TactileBounce(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSettings?.call();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9), // Soft gray tactile button
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.settings, // Gear icon strictly required
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // ── Metadata Badges Row (Online status + Battery + Signal) ──
            Row(
              children: [
                // Online badge
                _buildBadge(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Battery badge: Red if <= 20%, Green if > 20%
                _buildBadge(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLowBattery) ...[
                        // Pulsing red battery icon
                        Icon(
                          LucideIcons.battery,
                          size: 13,
                          color: Colors.red.shade600,
                        )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .fade(begin: 0.6, end: 1.0, duration: 800.ms),
                        const SizedBox(width: 5),
                        Text(
                          '$batteryLevel%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          LucideIcons.battery,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$batteryLevel%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Wi-Fi signal
                _buildBadge(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.wifi,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        signal,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Low Battery Warning Banner (Only when batteryLevel <= 20) ──
            if (_isLowBattery) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), // Soft red background
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.shade200, // Border red 200
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.batteryWarning,
                      size: 16,
                      color: Colors.red.shade600,
                    )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .fade(begin: 0.6, end: 1.0, duration: 800.ms),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pin sắp hết. Vui lòng sạc thiết bị để không gián đoạn.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Optional Action Button (For Home Screen use) ──
            if (showOrderButton) ...[
              const SizedBox(height: 14),
              _TactileActionButton(
                state: state,
                onTap: onOrder,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TactileActionButton extends StatefulWidget {
  final String state;
  final VoidCallback? onTap;

  const _TactileActionButton({
    required this.state,
    this.onTap,
  });

  @override
  State<_TactileActionButton> createState() => _TactileActionButtonState();
}

class _TactileActionButtonState extends State<_TactileActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isOrdered = widget.state == 'ordered';
    final isOrdering = widget.state == 'ordering';

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: isOrdering ? null : widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isOrdered
                ? const Color(0xFF059669)
                : isOrdering
                    ? const Color(0xFF64748B)
                    : const Color(0xFF475569),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOrdered
                      ? Colors.white
                      : isOrdering
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFF34D399),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isOrdered
                              ? Colors.white
                              : isOrdering
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFF34D399))
                          .withValues(alpha: 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOrdered
                    ? 'Đã đặt hàng thành công'
                    : isOrdering
                        ? 'Đang gửi tín hiệu...'
                        : 'Bấm đặt ngay',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
