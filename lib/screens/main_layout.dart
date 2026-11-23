import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/app_motion.dart';
import '../widgets/smart_order_tour.dart';
import 'admin_stores_screen.dart';
import 'devices_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'store_products_screen.dart';
import 'system_staff/system_staff_devices_screen.dart';
import 'system_staff/system_staff_returns_screen.dart';
import 'system_staff/system_staff_warranty_screen.dart';

/// Role-segmented App Shell with persistent bottom navigation, smooth tab transitions,
/// and strict per-role workspace isolation (CUSTOMER / STORE_OWNER / SYSTEM_STAFF / ADMIN).
class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  /// Allows child widgets to programmatically switch tabs without pushing new routes.
  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainLayoutState>();
    state?.changeTab(index);
  }

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;
  late final SmartOrderTour _tour;
  String? _lastRoleKey;

  @override
  void dispose() {
    _tour.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tour = SmartOrderTour(context: context, changeTab: changeTab);
  }

  int _tabCountFor(UserProvider? userProv) {
    if (userProv == null) return 4;
    if (userProv.isStoreOwner || userProv.isSystemStaff || userProv.isAdmin) {
      return 5;
    }
    return 4;
  }

  void changeTab(int index) {
    final userProv = context.read<UserProvider?>();
    final maxTabs = _tabCountFor(userProv);
    if (index >= 0 && index < maxTabs && index != _currentIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider?>();
    final orderProv = context.watch<OrderProvider?>();
    final account = userProv?.accountId;
    final role = userProv?.role ?? 'CUSTOMER';
    final isAdmin = userProv?.isAdmin ?? false;
    final isSystemStaff = userProv?.isSystemStaff ?? false;
    final isStoreOwner = userProv?.isStoreOwner ?? false;

    final roleKey = '$account:$role';
    if (_lastRoleKey != null && _lastRoleKey != roleKey && _currentIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }
    _lastRoleKey = roleKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !isAdmin && !isStoreOwner && !isSystemStaff) {
        _tour.accountChanged(account);
      } else if (mounted) {
        _tour.dismiss();
      }
    });

    final screens = isSystemStaff
        ? [
            HomePage(tour: _tour),
            const SystemStaffDevicesScreen(),
            const SystemStaffWarrantyScreen(),
            const SystemStaffReturnsScreen(),
            ProfileScreen(showBackButton: false, tour: _tour),
          ]
        : isAdmin
        ? [
            HomePage(tour: _tour),
            const AdminStoresScreen(),
            const SystemStaffDevicesScreen(),
            OrdersScreen(showBackButton: false, tour: _tour),
            ProfileScreen(showBackButton: false, tour: _tour),
          ]
        : isStoreOwner
        ? [
            HomePage(tour: _tour),
            const StoreProductsScreen(),
            DevicesScreen(tour: _tour),
            OrdersScreen(showBackButton: false, tour: _tour),
            ProfileScreen(showBackButton: false, tour: _tour),
          ]
        : [
            HomePage(tour: _tour),
            DevicesScreen(tour: _tour),
            OrdersScreen(showBackButton: false, tour: _tour),
            ProfileScreen(showBackButton: false, tour: _tour),
          ];

    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    final navItems = isSystemStaff
        ? const [
            AppNavItem(icon: LucideIcons.layoutDashboard, label: 'Tổng quan'),
            AppNavItem(icon: LucideIcons.cpu, label: 'Kho nút'),
            AppNavItem(icon: LucideIcons.shieldCheck, label: 'Bảo hành'),
            AppNavItem(icon: LucideIcons.rotateCcw, label: 'Thu hồi'),
            AppNavItem(icon: LucideIcons.userRound, label: 'Tài khoản'),
          ]
        : isAdmin
        ? const [
            AppNavItem(icon: LucideIcons.layoutDashboard, label: 'Tổng quan'),
            AppNavItem(icon: LucideIcons.store, label: 'Cửa hàng'),
            AppNavItem(icon: LucideIcons.cpu, label: 'Kho nút'),
            AppNavItem(icon: LucideIcons.receiptText, label: 'Đơn hàng'),
            AppNavItem(icon: LucideIcons.userRound, label: 'Tài khoản'),
          ]
        : isStoreOwner
        ? const [
            AppNavItem(icon: LucideIcons.store, label: 'Tổng quan'),
            AppNavItem(icon: LucideIcons.package, label: 'Sản phẩm'),
            AppNavItem(icon: LucideIcons.cpu, label: 'Nút IoT'),
            AppNavItem(icon: LucideIcons.receiptText, label: 'Đơn hàng'),
            AppNavItem(icon: LucideIcons.userRound, label: 'Tài khoản'),
          ]
        : const [
            AppNavItem(icon: LucideIcons.home, label: 'Trang chủ'),
            AppNavItem(icon: LucideIcons.smartphone, label: 'Nút của tôi'),
            AppNavItem(icon: LucideIcons.receiptText, label: 'Đơn hàng'),
            AppNavItem(icon: LucideIcons.userRound, label: 'Tài khoản'),
          ];

    final accentColor = isAdmin
        ? const Color(0xFF4338CA)
        : isSystemStaff
        ? const Color(0xFF0E7490)
        : isStoreOwner
        ? const Color(0xFF047857)
        : const Color(0xFF0E6BA8);

    final accentSoftColor = isAdmin
        ? const Color(0xFFEEF2FF)
        : isSystemStaff
        ? const Color(0xFFECFEFF)
        : isStoreOwner
        ? const Color(0xFFECFDF5)
        : const Color(0xFFE0F2FE);

    final pendingStoreOrders = isStoreOwner
        ? (orderProv?.orders
                  .where((o) => o.rawStatus.toUpperCase() == 'PENDING')
                  .length ??
              0)
        : 0;

    return PopScope(
      onPopInvokedWithResult: (_, _) => _tour.dismiss(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: AppAnimatedTabBody(
          key: ValueKey<String>(role),
          currentIndex: safeIndex,
          children: screens,
        ),
        bottomNavigationBar: AppFloatingNavBar(
          selectedIndex: safeIndex,
          onSelected: changeTab,
          items: navItems,
          compactLabels: isStoreOwner || isSystemStaff || isAdmin,
          accentColor: accentColor,
          accentSoftColor: accentSoftColor,
          badges: pendingStoreOrders > 0 ? {3: pendingStoreOrders} : const {},
        ),
      ),
    );
  }
}
