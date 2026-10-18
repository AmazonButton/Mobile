import 'package:flutter/material.dart';

/// Tab Selector dạng Segmented Pill chuyển đổi giữa đơn Đang diễn ra và Lịch sử
class OrderTabSelector extends StatelessWidget {
  final TabController controller;
  final int activeCount;
  final int historyCount;

  const OrderTabSelector({
    super.key,
    required this.controller,
    required this.activeCount,
    required this.historyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: controller,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: const Color(0xFF1E293B),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: 'Đang diễn ra ($activeCount)'),
            Tab(text: 'Lịch sử ($historyCount)'),
          ],
        ),
      ),
    );
  }
}
