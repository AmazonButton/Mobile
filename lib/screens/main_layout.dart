import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'home_screen.dart';
import 'devices_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomePage(),
          DevicesScreen(),
          OrdersScreen(showBackButton: false),
          ProfileScreen(showBackButton: false),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent, // Override Android MD3 purple tint
            indicatorColor: const Color(0xFFE2E8F0), // Pill-shaped active indicator
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B), // Slate 800
                  letterSpacing: -0.2,
                );
              }
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B), // Slate 500
                letterSpacing: -0.2,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: Color(0xFF1E293B),
                  size: 22,
                );
              }
              return const IconThemeData(
                color: Color(0xFF64748B),
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
            height: 68,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(LucideIcons.home),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.settings2),
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
    );
  }
}
