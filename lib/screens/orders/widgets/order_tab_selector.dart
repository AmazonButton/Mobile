import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/app_motion.dart';
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
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F7),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: controller,
        onTap: (_) => HapticFeedback.selectionClick(),
        splashBorderRadius: BorderRadius.circular(12),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: const Color(0xFF0E6BA8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0E6BA8).withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF475569),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        labelStyle: const TextStyle(
          fontFamily: SampleA.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: SampleA.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            height: MediaQuery.textScalerOf(context).scale(15) > 22 ? 68 : 42,
            child: Semantics(
              label: 'Đang xử lý, $activeCount đơn',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'Đang xử lý',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: AppMotion.fastDuration,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Tab(
            height: MediaQuery.textScalerOf(context).scale(15) > 22 ? 68 : 42,
            child: Semantics(
              label: 'Lịch sử, $historyCount đơn',
              child: Text(
                historyCount > 0 ? 'Lịch sử ($historyCount)' : 'Lịch sử',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
