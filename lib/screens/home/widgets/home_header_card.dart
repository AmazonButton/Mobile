import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Top header card for HomeScreen showing user avatar, dynamic greeting, notification bell, and location pill.
class HomeHeaderCard extends StatelessWidget {
  final File? userAvatar;
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
    required this.userInitials,
    required this.userShortName,
    required this.userAddress,
    required this.onAccountTap,
    this.onNotificationTap,
    required this.onLocationTap,
    this.unreadNotificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onAccountTap,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                      image: userAvatar != null
                          ? DecorationImage(
                              image: FileImage(userAvatar!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: userAvatar == null
                        ? Center(
                            child: Text(
                              userInitials,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chào buổi sáng,',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      userShortName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Minimalist Notification bell icon button with red badge dot
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onNotificationTap?.call();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      LucideIcons.bell,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Location Selector Pill
        GestureDetector(
          onTap: onLocationTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userAddress.trim().isNotEmpty ? userAddress : 'Chọn địa chỉ giao hàng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: userAddress.trim().isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                      color: userAddress.trim().isNotEmpty ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
