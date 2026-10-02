import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class DashboardHeader extends StatefulWidget {
  final bool isScrolled;
  final bool isMobile;
  final VoidCallback? onMenuTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onFullscreenTap;
  final Function(String query)? onSearch;

  final VoidCallback? onLogout;

  const DashboardHeader({
    super.key,
    this.isScrolled = false,
    this.isMobile = false,
    this.onMenuTap,
    required this.onNotificationTap,
    required this.onFullscreenTap,
    this.onSearch,
    this.onLogout,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchFocused = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.isScrolled ? 58 : 68,
      padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: widget.isScrolled ? AppColors.shadowMd : null,
      ),
      child: Row(
        children: [
          // ── Mobile Menu Hamburger ──
          if (widget.isMobile) ...[
            GestureDetector(
              onTap: widget.onMenuTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.bgPage,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.menu_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // ── Breadcrumb ──
          if (!widget.isMobile)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  'Tổng quan',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/smart_order_button_logo.png',
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(
                      Icons.radio_button_checked,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SmartOrder',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          if (!widget.isMobile) const SizedBox(width: 24),

          // ── Search Bar (Desktop) ──
          if (!widget.isMobile)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Focus(
                    onFocusChange: (focused) =>
                        setState(() => _searchFocused = focused),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.bgPage,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _searchFocused
                              ? AppColors.accent
                              : AppColors.border,
                          width: _searchFocused ? 1.5 : 1,
                        ),
                        boxShadow: _searchFocused
                            ? [
                                const BoxShadow(
                                  color: AppColors.accentGlow,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: widget.onSearch,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Tìm kiếm đơn hàng, thiết bị, tài khoản...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Actions Right ──
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: 5,
            tooltip: 'Thông báo',
            onTap: widget.onNotificationTap,
          ),

          if (!widget.isMobile) ...[
            const SizedBox(width: 8),
            _HeaderIconButton(
              icon: Icons.fullscreen_rounded,
              tooltip: 'Toàn màn hình',
              onTap: widget.onFullscreenTap,
            ),
            Container(
              height: 24,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.border,
            ),
          ] else ...[
            const SizedBox(width: 10),
          ],

          // User info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
              if (!widget.isMobile) ...[
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Nguyễn Admin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Administrator',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          // ── Logout Button ──
          if (widget.onLogout != null) ...[
            const SizedBox(width: 10),
            _HeaderIconButton(
              icon: Icons.logout_rounded,
              tooltip: 'Đăng xuất',
              color: const Color(0xFFEF4444),
              hoverColor: const Color(0xFFDC2626),
              onTap: widget.onLogout!,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final int? badgeCount;
  final String tooltip;
  final Color? color;
  final Color? hoverColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    this.badgeCount,
    required this.tooltip,
    this.color,
    this.hoverColor,
    required this.onTap,
  });

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _hovered
        ? (widget.hoverColor ?? AppColors.accent)
        : (widget.color ?? AppColors.textSecondary);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.borderLight : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: effectiveColor,
                ),
                if (widget.badgeCount != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
