import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/order_model.dart';

class OrdersTableCard extends StatefulWidget {
  final Function(String title, String message)? onShowToast;

  const OrdersTableCard({super.key, this.onShowToast});

  @override
  State<OrdersTableCard> createState() => _OrdersTableCardState();
}

class _OrdersTableCardState extends State<OrdersTableCard> {
  final List<OrderModel> _orders = OrderModel.sampleOrders;
  int? _hoveredRowIndex;
  int _activePage = 1;

  void _exportCSV() {
    widget.onShowToast?.call(
      'Xuất dữ liệu thành công',
      'Đã xuất 248 đơn hàng ra tệp sob_orders_20260919.csv',
    );
  }

  void _viewAll() {
    widget.onShowToast?.call(
      'Danh sách đơn hàng',
      'Đang chuyển đến trang quản lý tất cả đơn hàng...',
    );
  }

  void _viewDetail(OrderModel order) {
    widget.onShowToast?.call(
      'Chi tiết đơn hàng',
      'Đơn ${order.id} — ${order.customerName} (${order.apartment})',
    );
  }

  void _editOrder(OrderModel order) {
    widget.onShowToast?.call(
      'Chỉnh sửa đơn hàng',
      'Mở bảng cập nhật trạng thái đơn ${order.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Title & Action Buttons ──
          Padding(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                final buttons = Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _TableButton(
                      icon: Icons.file_download_outlined,
                      label: 'Xuất CSV',
                      isPrimary: false,
                      onTap: _exportCSV,
                    ),
                    _TableButton(
                      icon: Icons.all_inbox_rounded,
                      label: 'Xem tất cả',
                      isPrimary: true,
                      onTap: _viewAll,
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đơn hàng gần đây',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      buttons,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đơn hàng gần đây',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    buttons,
                  ],
                );
              },
            ),
          ),

          // ── Data Table (Scrollable horizontally for responsiveness) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 880),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    color: AppColors.bgPage,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 160,
                          child: Text(
                            'MÃ ĐƠN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: Text(
                            'CƯ DÂN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'CĂN HỘ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: Text(
                            'SẢN PHẨM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'THỜI GIAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            'TRẠNG THÁI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'THAO TÁC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rows
                  ..._orders.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final order = entry.value;
                    final isHovered = _hoveredRowIndex == idx;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredRowIndex = idx),
                      onExit: (_) => setState(() => _hoveredRowIndex = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? AppColors.bgPage
                              : (idx % 2 == 0 ? Colors.white : const Color(0xFFFAFAFC)),
                          border: const Border(
                            bottom: BorderSide(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Mã đơn
                            SizedBox(
                              width: 160,
                              child: Text(
                                order.id,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            // Cư dân
                            SizedBox(
                              width: 160,
                              child: Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            // Căn hộ
                            SizedBox(
                              width: 100,
                              child: Text(
                                order.apartment,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            // Sản phẩm
                            SizedBox(
                              width: 160,
                              child: Text(
                                order.product,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            // Thời gian
                            SizedBox(
                              width: 100,
                              child: Text(
                                order.time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            // Trạng thái
                            SizedBox(
                              width: 120,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: order.statusBgColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    order.statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: order.statusColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Thao tác
                            SizedBox(
                              width: 80,
                              child: Row(
                                children: [
                                  _RowActionButton(
                                    icon: Icons.visibility_outlined,
                                    tooltip: 'Xem chi tiết',
                                    onTap: () => _viewDetail(order),
                                  ),
                                  const SizedBox(width: 6),
                                  _RowActionButton(
                                    icon: Icons.edit_outlined,
                                    tooltip: 'Chỉnh sửa',
                                    onTap: () => _editOrder(order),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Pagination Footer ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 550;

                final info = const Text.rich(
                  TextSpan(
                    text: 'Hiển thị ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: '1-10',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(text: ' trong '),
                      TextSpan(
                        text: '248',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(text: ' đơn hàng'),
                    ],
                  ),
                );

                final controls = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PaginationButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () {
                          if (_activePage > 1) {
                            setState(() => _activePage--);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      _PaginationButton(
                        text: '1',
                        isActive: _activePage == 1,
                        onTap: () => setState(() => _activePage = 1),
                      ),
                      const SizedBox(width: 4),
                      _PaginationButton(
                        text: '2',
                        isActive: _activePage == 2,
                        onTap: () => setState(() => _activePage = 2),
                      ),
                      const SizedBox(width: 4),
                      _PaginationButton(
                        text: '3',
                        isActive: _activePage == 3,
                        onTap: () => setState(() => _activePage = 3),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _PaginationButton(
                        text: '25',
                        isActive: _activePage == 25,
                        onTap: () => setState(() => _activePage = 25),
                      ),
                      const SizedBox(width: 4),
                      _PaginationButton(
                        icon: Icons.chevron_right_rounded,
                        onTap: () {
                          if (_activePage < 25) {
                            setState(() => _activePage++);
                          }
                        },
                      ),
                    ],
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      info,
                      const SizedBox(height: 12),
                      controls,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [info, controls],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _TableButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_TableButton> createState() => _TableButtonState();
}

class _TableButtonState extends State<_TableButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_hovered ? AppColors.accentHover : AppColors.accent)
                : (_hovered ? AppColors.borderLight : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isPrimary
                  ? (_hovered ? AppColors.accentHover : AppColors.accent)
                  : AppColors.border,
            ),
            boxShadow: widget.isPrimary && _hovered
                ? [
                    BoxShadow(
                      color: AppColors.accentGlow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.isPrimary
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isPrimary
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RowActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_RowActionButton> createState() => _RowActionButtonState();
}

class _RowActionButtonState extends State<_RowActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.borderLight : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _PaginationButton({
    this.text,
    this.icon,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_PaginationButton> createState() => _PaginationButtonState();
}

class _PaginationButtonState extends State<_PaginationButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary
                : (_hovered ? AppColors.borderLight : AppColors.bgPage),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: widget.icon != null
              ? Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isActive
                      ? Colors.white
                      : AppColors.textSecondary,
                )
              : Text(
                  widget.text ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isActive
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }
}
