import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../widgets/app_motion.dart';
import '../../../widgets/modals/connect_device_sheet.dart';
import '../../customer_buttons_screen.dart';
import '../../main_layout.dart';
import '../../store_wallet_screen.dart';
import '../../system_staff/system_staff_warranty_screen.dart';

/// Floating Quick-Action Dock cleanly separated per role:
/// - CUSTOMER: Mua sắm, Nút của tôi, Thuê nút bấm, Quét BLE, Đơn hàng, Tài khoản
/// - STORE_OWNER: Đơn trực tiếp (with live pending badge), Sản phẩm, Nút IoT, Ví doanh thu
/// - SYSTEM_STAFF: Kho nút, Bảo hành, Thu hồi, Quét BLE
/// - ADMIN: Cửa hàng, Kho nút, Đơn hàng, Bảo hành
class HomeGrabServicesGrid extends StatelessWidget {
  final VoidCallback? onScrollToStores;
  final String role;
  final int pendingOrderCount;

  const HomeGrabServicesGrid({
    super.key,
    this.onScrollToStores,
    this.role = 'CUSTOMER',
    this.pendingOrderCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        role == 'SUPER_ADMIN' || role == 'SYSTEM_ADMIN' || role == 'ADMIN';
    final isSystemStaff = role == 'SYSTEM_STAFF';
    final isStoreOwner = role == 'STORE_OWNER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppMotion.dockShadow,
      ),
      child: isSystemStaff
          ? Row(
              children: [
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.cpu,
                    label: 'Kho nút',
                    iconColor: const Color(0xFF0E6BA8),
                    bgColor: const Color(0xFFE0F2FE),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MainLayout.switchToTab(context, 1);
                    },
                  ),
                ),
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.shieldCheck,
                    label: 'Bảo hành',
                    iconColor: const Color(0xFF0E7490),
                    bgColor: const Color(0xFFECFEFF),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MainLayout.switchToTab(context, 2);
                    },
                  ),
                ),
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.rotateCcw,
                    label: 'Thu hồi',
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MainLayout.switchToTab(context, 3);
                    },
                  ),
                ),
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.bluetooth,
                    label: 'Quét BLE',
                    iconColor: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                    badgeText: 'BLE',
                    badgeColor: const Color(0xFF2563EB),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ConnectDeviceSheet.showAndRefresh(context);
                    },
                  ),
                ),
              ],
            )
          : isAdmin
          ? Row(
              children: [
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.store,
                    label: 'Cửa hàng',
                    iconColor: const Color(0xFF4338CA),
                    bgColor: const Color(0xFFEEF2FF),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MainLayout.switchToTab(context, 1);
                    },
                  ),
                ),
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.cpu,
                    label: 'Kho nút',
                    iconColor: const Color(0xFF0E6BA8),
                    bgColor: const Color(0xFFE0F2FE),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MainLayout.switchToTab(context, 2);
                    },
                  ),
                ),
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.receiptText,
                    label: 'Đơn hàng',
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MainLayout.switchToTab(context, 3);
                    },
                  ),
                ),
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.shieldCheck,
                    label: 'Bảo hành',
                    iconColor: const Color(0xFF0E7490),
                    bgColor: const Color(0xFFECFEFF),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SystemStaffWarrantyScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : isStoreOwner
          ? Row(
              children: [
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.shoppingBag,
                    label: 'Đơn hàng',
                    iconColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                    badgeText: pendingOrderCount > 0
                        ? '$pendingOrderCount'
                        : null,
                    badgeColor: const Color(0xFFEF4444),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MainLayout.switchToTab(context, 3);
                    },
                  ),
                ),
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.package,
                    label: 'Sản phẩm',
                    iconColor: const Color(0xFF047857),
                    bgColor: const Color(0xFFECFDF5),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MainLayout.switchToTab(context, 1);
                    },
                  ),
                ),
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.cpu,
                    label: 'Nút IoT',
                    iconColor: const Color(0xFF0E6BA8),
                    bgColor: const Color(0xFFE0F2FE),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MainLayout.switchToTab(context, 2);
                    },
                  ),
                ),
                Expanded(
                  child: _GrabServiceItem(
                    icon: LucideIcons.wallet,
                    label: 'Ví quán',
                    iconColor: const Color(0xFF0D9488),
                    bgColor: const Color(0xFFF0FDFA),
                    badgeText: 'VNĐ',
                    badgeColor: const Color(0xFF047857),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const StoreWalletScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : Column(
              children: [
                // ── HÀNG 1: Mua sắm | Nút của tôi | Thuê nút bấm ──
                Row(
                  children: [
                    Expanded(
                      child: _GrabServiceItem(
                        icon: LucideIcons.shoppingCart,
                        label: 'Mua sắm',
                        iconColor: const Color(0xFF287DA8),
                        bgColor: const Color(0xFFF0F9FF),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onScrollToStores?.call();
                        },
                      ),
                    ),
                    Expanded(
                      child: _GrabServiceItem(
                        icon: LucideIcons.smartphone,
                        label: 'Nút của tôi',
                        iconColor: const Color(0xFF0E6BA8),
                        bgColor: const Color(0xFFE0F2FE),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          MainLayout.switchToTab(context, 1);
                        },
                      ),
                    ),
                    Expanded(
                      child: _GrabServiceItem(
                        icon: LucideIcons.cpu,
                        label: 'Thuê nút bấm',
                        iconColor: const Color(0xFF059669),
                        bgColor: const Color(0xFFECFDF5),
                        badgeText: 'Hot',
                        badgeColor: const Color(0xFF059669),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CustomerButtonsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── HÀNG 2: Quét Bluetooth | Đơn hàng | Tài khoản ──
                Row(
                  children: [
                    Expanded(
                      child: _GrabServiceItem(
                        icon: LucideIcons.bluetooth,
                        label: 'Quét Bluetooth',
                        iconColor: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                        badgeText: 'BLE',
                        badgeColor: const Color(0xFF2563EB),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ConnectDeviceSheet.showAndRefresh(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: _GrabServiceItem(
                        icon: LucideIcons.receiptText,
                        label: 'Đơn hàng',
                        iconColor: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFFFBEB),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          MainLayout.switchToTab(context, 2);
                        },
                      ),
                    ),
                    Expanded(
                      child: _GrabServiceItem(
                        icon: LucideIcons.userRound,
                        label: 'Tài khoản',
                        iconColor: const Color(0xFF4F46E5),
                        bgColor: const Color(0xFFEEF2FF),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          MainLayout.switchToTab(context, 3);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _GrabServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _GrabServiceItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    this.badgeText,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactilePress(
      scaleDown: 0.94,
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: iconColor.withValues(alpha: 0.14)),
                  ),
                  child: Center(child: Icon(icon, size: 23, color: iconColor)),
                ),
                if (badgeText != null)
                  Positioned(
                    top: -5,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFF0E6BA8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeText!,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
