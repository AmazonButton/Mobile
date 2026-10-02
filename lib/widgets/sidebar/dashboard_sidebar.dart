import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class DashboardSidebar extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;
  final String activePage;
  final Function(String page) onPageSelect;
  final VoidCallback? onLogout;

  const DashboardSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.activePage,
    required this.onPageSelect,
    this.onLogout,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  String? _hoveredItem;
  bool _toggleHovered = false;

  @override
  Widget build(BuildContext context) {
    final double width = widget.isCollapsed ? 72 : 260;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          width: width,
          decoration: const BoxDecoration(
            gradient: AppColors.sidebarGradient,
          ),
          child: Column(
            children: [
              // ── Header / Logo ──
              _buildHeader(),

              // ── Navigation Items ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('TỔNG QUAN'),
                      _buildNavItem(
                        id: 'dashboard',
                        title: 'Dashboard',
                        icon: Icons.grid_view_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildSectionLabel('QUẢN LÝ'),
                      _buildNavItem(
                        id: 'accounts',
                        title: 'Tài khoản & RBAC',
                        icon: Icons.people_outline_rounded,
                        badge: '12',
                      ),
                      _buildNavItem(
                        id: 'products',
                        title: 'Danh mục sản phẩm',
                        icon: Icons.inventory_2_outlined,
                      ),
                      _buildNavItem(
                        id: 'orders',
                        title: 'Đơn hàng',
                        icon: Icons.receipt_long_outlined,
                        badge: '5',
                      ),
                      const SizedBox(height: 12),
                      _buildSectionLabel('GIÁM SÁT'),
                      _buildNavItem(
                        id: 'iot',
                        title: 'Thiết bị IoT',
                        icon: Icons.sensors_rounded,
                      ),
                      _buildNavItem(
                        id: 'analytics',
                        title: 'Phân tích & Báo cáo',
                        icon: Icons.bar_chart_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildSectionLabel('HỆ THỐNG'),
                      _buildNavItem(
                        id: 'notifications',
                        title: 'Cấu hình thông báo',
                        icon: Icons.notifications_none_rounded,
                      ),
                      _buildNavItem(
                        id: 'settings',
                        title: 'Cài đặt hệ thống',
                        icon: Icons.settings_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer / User profile ──
              _buildFooter(),
            ],
          ),
        ),

        // ── Floating Toggle Button ──
        Positioned(
          top: 24,
          right: -14,
          child: MouseRegion(
            onEnter: (_) => setState(() => _toggleHovered = true),
            onExit: (_) => setState(() => _toggleHovered = false),
            child: GestureDetector(
              onTap: widget.onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                transform: Matrix4.diagonal3Values(
                  _toggleHovered ? 1.12 : 1.0,
                  _toggleHovered ? 1.12 : 1.0,
                  1.0,
                ),
                decoration: BoxDecoration(
                  color: _toggleHovered ? AppColors.accent : AppColors.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _toggleHovered ? AppColors.accent : AppColors.border,
                    width: 2,
                  ),
                  boxShadow: AppColors.shadowMd,
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: widget.isCollapsed ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 16,
                      color: _toggleHovered ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/smart_order_button_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.radio_button_checked,
                color: AppColors.accent,
                size: 24,
              ),
            ),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SOB Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Management Panel',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    if (widget.isCollapsed) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String id,
    required String title,
    required IconData icon,
    String? badge,
  }) {
    final bool isActive = widget.activePage == id;
    final bool isHovered = _hoveredItem == id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredItem = id),
      onExit: (_) => setState(() => _hoveredItem = null),
      child: GestureDetector(
        onTap: () => widget.onPageSelect(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 3),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 12 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0x26F5862B)
                : (isHovered
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Active Indicator bar
              if (isActive)
                Positioned(
                  left: -14,
                  top: 2,
                  bottom: 2,
                  child: Container(
                    width: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(3),
                      ),
                    ),
                  ),
                ),

              Row(
                mainAxisAlignment: widget.isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isActive
                        ? Colors.white
                        : (isHovered
                            ? Colors.white.withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.65)),
                  ),
                  if (!widget.isCollapsed) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : (isHovered
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : Colors.white.withValues(alpha: 0.65)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: widget.isCollapsed
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, Color(0xFFE06B18)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              'AD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nguyễn Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'System Administrator',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (widget.onLogout != null)
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                tooltip: 'Đăng xuất',
                onPressed: widget.onLogout,
              ),
          ] else ...[
            if (widget.onLogout != null)
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                tooltip: 'Đăng xuất',
                onPressed: widget.onLogout,
              ),
          ],
        ],
      ),
    );
  }
}
