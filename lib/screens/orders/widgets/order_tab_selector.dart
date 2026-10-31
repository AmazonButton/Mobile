import 'package:flutter/material.dart';
import '../../../widgets/sample_a.dart';

class OrderTabSelector extends StatelessWidget {
  final TabController controller;
  final int activeCount, historyCount;
  const OrderTabSelector({
    super.key,
    required this.controller,
    required this.activeCount,
    required this.historyCount,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: SampleA.border, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: SampleA.pale,
          borderRadius: BorderRadius.circular(13),
        ),
        labelColor: SampleA.primary,
        unselectedLabelColor: SampleA.muted,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: const TextStyle(
          fontFamily: 'SampleA Vietnam',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'SampleA Vietnam',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            height: MediaQuery.textScalerOf(context).scale(15) > 22 ? 72 : 48,
            child: Text(
              'Đang xử lý',
              textAlign: TextAlign.center,
              semanticsLabel: 'Đang xử lý, $activeCount đơn',
            ),
          ),
          Tab(
            height: MediaQuery.textScalerOf(context).scale(15) > 22 ? 72 : 48,
            child: Text(
              'Lịch sử',
              textAlign: TextAlign.center,
              semanticsLabel: 'Lịch sử, $historyCount đơn',
            ),
          ),
        ],
      ),
    ),
  );
}
