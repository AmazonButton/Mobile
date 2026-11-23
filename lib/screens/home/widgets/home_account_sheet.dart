import '../../../widgets/user_avatar.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../login_screen.dart';
import '../../main_layout.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/services.dart';

/// Modal Bottom Sheet hiển thị thông tin tài khoản và tùy chọn đăng xuất
class HomeAccountSheet extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userAddress;
  final String userInitials;
  final File? userAvatar;
  final String? userAvatarUrl;
  final VoidCallback? onLogout;

  const HomeAccountSheet({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userAddress,
    required this.userInitials,
    this.userAvatar,
    this.userAvatarUrl,
    this.onLogout,
  });

  static void show(
    BuildContext context, {
    required String userName,
    required String userEmail,
    required String userAddress,
    required String userInitials,
    File? userAvatar,
    String? userAvatarUrl,
    VoidCallback? onLogout,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => HomeAccountSheet(
        userName: userName,
        userEmail: userEmail,
        userAddress: userAddress,
        userInitials: userInitials,
        userAvatar: userAvatar,
        userAvatarUrl: userAvatarUrl,
        onLogout: onLogout,
      ),
    );
  }

  static void showLogoutDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              UserProvider? userProv;
              DeviceProvider? deviceProv;
              OrderProvider? orderProv;
              AddressProvider? addrProv;
              NotificationProvider? notifProv;
              try {
                userProv = Provider.of<UserProvider>(context, listen: false);
                deviceProv = Provider.of<DeviceProvider>(context, listen: false);
                orderProv = Provider.of<OrderProvider>(context, listen: false);
                addrProv = Provider.of<AddressProvider>(context, listen: false);
                notifProv = Provider.of<NotificationProvider>(context, listen: false);
              } catch (_) {}
              Navigator.pop(ctx);
              await NotificationService().unregisterTokenOnLogout();
              await AuthApiService().logout();
              userProv?.reset();
              deviceProv?.reset();
              orderProv?.reset();
              addrProv?.reset();
              await notifProv?.clearAll();
              UserProfileService().reset();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider?>();
    final isAdmin = userProv?.isAdmin ?? false;
    final isSystemStaff = userProv?.isSystemStaff ?? false;
    final isStoreOwner = userProv?.isStoreOwner ?? false;
    final roleLabel = userProv?.roleLabel ?? 'Khách hàng';
    final infoIcon = isAdmin
        ? Icons.admin_panel_settings_outlined
        : isSystemStaff
            ? Icons.build_circle_outlined
            : isStoreOwner
                ? Icons.storefront_outlined
                : Icons.location_on_outlined;
    final infoText = isAdmin
        ? 'Quản trị toàn hệ thống SmartOrder'
        : isSystemStaff
            ? 'Kho nút bấm & Bảo hành kỹ thuật'
            : isStoreOwner
                ? (userProv?.storeName?.isNotEmpty == true
                    ? userProv!.storeName!
                    : 'Không gian chủ cửa hàng')
                : userAddress;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAdmin
                      ? 'Tài khoản quản trị'
                      : isSystemStaff
                          ? 'Tài khoản nhân viên hệ thống'
                          : isStoreOwner
                              ? 'Tài khoản đại lý'
                              : 'Tài khoản cá nhân',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                UserAvatar(
                  size: 52,
                  initials: userInitials,
                  file: userAvatar,
                  url: userAvatarUrl,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? const Color(0xFFEEF2FF)
                                  : isSystemStaff
                                      ? const Color(0xFFECFEFF)
                                      : isStoreOwner
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isAdmin
                                    ? const Color(0xFF4338CA)
                                    : isSystemStaff
                                        ? const Color(0xFF0E7490)
                                        : isStoreOwner
                                            ? const Color(0xFF047857)
                                            : const Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Icon(
                    infoIcon,
                    size: 18,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      infoText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  MainLayout.switchToTab(
                    context,
                    (isStoreOwner || isSystemStaff) ? 4 : 3,
                  );
                },
                icon: const Icon(
                  CupertinoIcons.person_crop_circle,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Xem & chỉnh sửa hồ sơ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64748B),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onLogout?.call();
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: Color(0xFFF43F5E),
                ),
                label: const Text(
                  'Đăng xuất tài khoản',
                  style: TextStyle(
                    color: Color(0xFFF43F5E),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECDD3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
