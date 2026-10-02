import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/activity_model.dart';

class ActivityTimelineCard extends StatefulWidget {
  final VoidCallback? onViewAll;

  const ActivityTimelineCard({super.key, this.onViewAll});

  @override
  State<ActivityTimelineCard> createState() => _ActivityTimelineCardState();
}

class _ActivityTimelineCardState extends State<ActivityTimelineCard> {
  final List<ActivityModel> _activities = ActivityModel.sampleActivities;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Hoạt động gần đây',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onViewAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Timeline list ──
          ..._activities.asMap().entries.map((entry) {
            final idx = entry.key;
            final activity = entry.value;
            final bool isLast = idx == _activities.length - 1;
            final bool isHovered = _hoveredIndex == idx;

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = idx),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isHovered ? AppColors.bgPage : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dot + Connecting Line column
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: activity.dotBgColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: activity.dotColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              activity.icon,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppColors.borderLight,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: '${activity.title} ',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: activity.description,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                activity.time,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
