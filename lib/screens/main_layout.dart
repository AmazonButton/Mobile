import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../widgets/smart_order_tour.dart';
import 'home_screen.dart';
import 'devices_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import '../widgets/sample_a.dart';

/// App Shell Architecture with persistent bottom navigation using IndexedStack
class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  /// Allows child widgets to programmatically switch tabs without pushing new routes
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

  void changeTab(int index) {
    if (index >= 0 && index < 4 && index != _currentIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<UserProvider?>()?.accountId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tour.accountChanged(account);
    });
    return PopScope(
      onPopInvokedWithResult: (_, _) => _tour.dismiss(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFD),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomePage(),
            DevicesScreen(tour: _tour),
            const OrdersScreen(showBackButton: false),
            ProfileScreen(showBackButton: false, tour: _tour),
          ],
        ),
        bottomNavigationBar: _currentIndex != 0
            ? SampleANavigation(
                selectedIndex: _currentIndex,
                onSelected: changeTab,
              )
            : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                  ),
                ),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    indicatorColor: _currentIndex == 0
                        ? Colors.transparent
                        : SampleA.pale,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _currentIndex == 0
                              ? const Color(0xFF2563EB)
                              : SampleA.primary,
                          letterSpacing: -0.2,
                        );
                      }
                      return const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8), // Slate 400
                        letterSpacing: -0.2,
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return IconThemeData(
                          color: _currentIndex == 0
                              ? const Color(0xFF2563EB)
                              : SampleA.primary,
                          size: 22,
                        );
                      }
                      return const IconThemeData(
                        color: Color(0xFF94A3B8),
                        size: 22,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (int index) {
                      changeTab(index);
                    },
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    height: 64,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(LucideIcons.home),
                        label: 'Trang chủ',
                      ),
                      NavigationDestination(
                        icon: Icon(LucideIcons.slidersHorizontal),
                        label: 'Thiết bị',
                      ),
                      NavigationDestination(
                        icon: Icon(LucideIcons.receipt),
                        label: 'Đơn hàng',
                      ),
                      NavigationDestination(
                        icon: Icon(LucideIcons.user),
                        label: 'Tài khoản',
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
