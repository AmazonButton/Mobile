import '../../../widgets/sample_a.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Top header card for HomeScreen showing user avatar, dynamic greeting, notification bell, and location pill.
class HomeHeaderCard extends StatelessWidget {
  final File? userAvatar;
  final String? userAvatarUrl;
  final String userInitials;
  final String userShortName;
  final String userAddress;
  final VoidCallback onAccountTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback onLocationTap;
  final int unreadNotificationCount;

  const HomeHeaderCard({
    super.key,
    this.userAvatar,
    this.userAvatarUrl,
    required this.userInitials,
    required this.userShortName,
    required this.userAddress,
    required this.onAccountTap,
    this.onNotificationTap,
    required this.onLocationTap,
    this.unreadNotificationCount = 0,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onLocationTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      color: SampleA.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giao đến',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Text(
                            userAddress.trim().isEmpty
                                ? 'Chọn địa chỉ giao hàng'
                                : userAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () {
              HapticFeedback.lightImpact();
              onNotificationTap?.call();
            },
            icon: Badge(
              isLabelVisible: unreadNotificationCount > 0,
              backgroundColor: SampleA.primary,
              child: const Icon(LucideIcons.bell, size: 25),
            ),
          ),
        ],
      ),
      const Divider(height: 20, color: Color(0xFFE8EDF5)),
      InkWell(
        onTap: onAccountTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Chào ${userShortName.trim().isEmpty ? 'bạn' : userShortName} 👋',
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
      const Text(
        'Hôm nay nhà mình cần gì?',
        style: TextStyle(
          fontSize: 25,
          height: 1.25,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
          color: SampleA.ink,
        ),
      ),
    ],
  );
}
