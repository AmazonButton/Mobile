import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/toast_model.dart';
import '../widgets/sidebar/dashboard_sidebar.dart';
import '../widgets/header/dashboard_header.dart';
import '../widgets/stat_cards/stat_cards_grid.dart';
import '../widgets/charts/animated_bar_chart.dart';
import '../widgets/charts/animated_donut_chart.dart';
import '../widgets/tables/orders_table.dart';
import '../widgets/devices/iot_devices_card.dart';
import '../widgets/timeline/activity_timeline_card.dart';
import '../widgets/footer/dashboard_footer.dart';
import '../widgets/toast/toast_overlay.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isSidebarCollapsed = false;
  String _activePage = 'dashboard';
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  late AnimationController _entranceController;

  final List<ToastModel> _toasts = [];
  Timer? _toast1Timer;
  Timer? _toast2Timer;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _entranceController.forward();

    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 50;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });

    // Initial timed toasts matching app.js
    _toast1Timer = Timer(const Duration(seconds: 2), () {
      _addToast(
        icon: '📦',
        title: 'Đơn hàng mới!',
        message: 'Căn hộ A1-1205 vừa đặt Bình Gas 12kg — Nhấn để xem chi tiết',
        duration: const Duration(seconds: 8),
      );
    });

    _toast2Timer = Timer(const Duration(seconds: 12), () {
      _addToast(
        icon: '⚠️',
        title: 'Cảnh báo thiết bị',
        message: 'ESP32-B2-0301 — Pin còn 12%, cần thay pin sớm',
        duration: const Duration(seconds: 8),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entranceController.dispose();
    _toast1Timer?.cancel();
    _toast2Timer?.cancel();
    super.dispose();
  }

  void _addToast({
    required String icon,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 6),
  }) {
    if (!mounted) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _toasts.insert(
        0,
        ToastModel(
          id: id,
          icon: icon,
          title: title,
          message: message,
          duration: duration,
        ),
      );
    });

    Timer(duration, () {
      _removeToast(id);
    });
  }

  void _removeToast(String id) {
    if (!mounted) return;
    setState(() {
      _toasts.removeWhere((t) => t.id == id);
    });
  }

  void _onNotificationTap() {
    _addToast(
      icon: '🔔',
      title: 'Thông báo hệ thống',
      message: 'Bạn có 5 đơn hàng mới chờ xử lý trong khu vực tòa A & B',
      duration: const Duration(seconds: 5),
    );
  }

  void _onFullscreenTap() {
    _addToast(
      icon: '🖥️',
      title: 'Chế độ toàn màn hình',
      message: 'Nhấn F11 trên trình duyệt hoặc phím tắt hệ thống để chuyển đổi.',
      duration: const Duration(seconds: 4),
    );
  }

  void _handleLogout() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth >= 1024;
    final effectiveCollapsed = !isDesktop || _isSidebarCollapsed;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgPage,
      drawer: isMobile
          ? Drawer(
              width: 270,
              backgroundColor: AppColors.primaryDark,
              child: DashboardSidebar(
                isCollapsed: false,
                onToggle: () => Navigator.of(context).pop(),
                activePage: _activePage,
                onLogout: _handleLogout,
                onPageSelect: (page) {
                  setState(() => _activePage = page);
                  Navigator.of(context).pop();
                  if (page != 'dashboard') {
                    _addToast(
                      icon: '📌',
                      title: 'Chuyển phân hệ',
                      message: 'Đang chuyển đến phân hệ $page...',
                      duration: const Duration(seconds: 3),
                    );
                  }
                },
              ),
            )
          : null,
      body: Stack(
        children: [
          Row(
            children: [
              // ── Collapsible Sidebar (Desktop / Tablet) ──
              if (!isMobile)
                DashboardSidebar(
                  isCollapsed: effectiveCollapsed,
                  onToggle: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                  activePage: _activePage,
                  onLogout: _handleLogout,
                  onPageSelect: (page) {
                    setState(() => _activePage = page);
                    if (page != 'dashboard') {
                      _addToast(
                        icon: '📌',
                        title: 'Chuyển phân hệ',
                        message: 'Đang chuyển đến phân hệ $page...',
                        duration: const Duration(seconds: 3),
                      );
                    }
                  },
                ),

              // ── Main Content Area ──
              Expanded(
                child: Column(
                  children: [
                    // Header
                    DashboardHeader(
                      isScrolled: _isScrolled,
                      isMobile: isMobile,
                      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                      onNotificationTap: _onNotificationTap,
                      onFullscreenTap: _onFullscreenTap,
                      onLogout: _handleLogout,
                      onSearch: (q) {
                        if (q.isNotEmpty && q.length >= 3) {
                          // search trigger
                        }
                      },
                    ),

                    // Scrollable Body
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Page Title Section ──
                                  _buildPageTitleSection(),

                                  const SizedBox(height: 20),

                                  // ── Section 1: Stat Cards ──
                                  StatCardsGrid(
                                    animationController: _entranceController,
                                  ),

                                  const SizedBox(height: 20),

                                  // ── Section 2: Charts Grid ──
                                  _buildChartsSection(screenWidth),

                                  const SizedBox(height: 20),

                                  // ── Section 3: Recent Orders Table ──
                                  OrdersTableCard(
                                    onShowToast: (title, message) => _addToast(
                                      icon: '📄',
                                      title: title,
                                      message: message,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // ── Section 4 & 5: Bottom Grid ──
                                  _buildBottomGrid(screenWidth),
                                ],
                              ),
                            ),

                            // ── Footer ──
                            DashboardFooter(
                              onLinkTap: (link) => _addToast(
                                icon: 'ℹ️',
                                title: link,
                                message: 'Đang mở trang $link...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Floating Toast Overlay ──
          ToastOverlay(
            toasts: _toasts,
            onDismiss: _removeToast,
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng quan hệ thống',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          const TextSpan(
            text: 'Xin chào, ',
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: 'Nguyễn Admin',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: ' — Hôm nay là Thứ Sáu, 19/09/2026',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartsSection(double screenWidth) {
    if (screenWidth < 1180) {
      return Column(
        children: const [
          AnimatedBarChartCard(),
          SizedBox(height: 20),
          AnimatedDonutChartCard(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(
          flex: 7,
          child: AnimatedBarChartCard(),
        ),
        SizedBox(width: 20),
        Expanded(
          flex: 5,
          child: AnimatedDonutChartCard(),
        ),
      ],
    );
  }

  Widget _buildBottomGrid(double screenWidth) {
    if (screenWidth < 1180) {
      return Column(
        children: [
          IotDevicesCard(
            onViewAll: () => _addToast(
              icon: '📡',
              title: 'Mạng lưới IoT',
              message: 'Đang mở danh sách toàn bộ thiết bị ESP32...',
            ),
          ),
          const SizedBox(height: 20),
          ActivityTimelineCard(
            onViewAll: () => _addToast(
              icon: '📋',
              title: 'Nhật ký hoạt động',
              message: 'Đang tải lịch sử hoạt động hệ thống...',
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: IotDevicesCard(
            onViewAll: () => _addToast(
              icon: '📡',
              title: 'Mạng lưới IoT',
              message: 'Đang mở danh sách toàn bộ thiết bị ESP32...',
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 6,
          child: ActivityTimelineCard(
            onViewAll: () => _addToast(
              icon: '📋',
              title: 'Nhật ký hoạt động',
              message: 'Đang tải lịch sử hoạt động hệ thống...',
            ),
          ),
        ),
      ],
    );
  }
}
