import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/notification_item.dart';
import '../../providers/notification_provider.dart';
import '../../screens/main_layout.dart';

/// Modern in-app notification center modal bottom sheet.
class NotificationSheet extends StatelessWidget {
  const NotificationSheet({super.key});

  /// Displays the Notification bottom sheet.
  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => const NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, child) {
        final notifications = notifProvider.notifications;
        final unreadCount = notifProvider.unreadCount;

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: const Icon(
                          LucideIcons.bell,
                          size: 20,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Thông báo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$unreadCount mới',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unreadCount > 0
                                  ? 'Bạn có $unreadCount thông báo chưa xem'
                                  : 'Tất cả thông báo đã đọc',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            notifProvider.markAllAsRead();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Đọc tất cả',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                // Sub-toolbar for clearing notifications
                if (notifications.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cập nhật gần đây (${notifications.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            notifProvider.clearAll();
                          },
                          child: const Text(
                            'Xóa tất cả',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main notification list / empty state
                Flexible(
                  child: notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: notifications.length,
                          separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, index) {
                            final item = notifications[index];
                            return _buildNotificationCard(
                              context: context,
                              item: item,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                notifProvider.markAsRead(item.id);
                                if (item.orderId != null || item.orderCode != null) {
                                  Navigator.of(context).pop();
                                  MainLayout.switchToTab(context, 2);
                                }
                              },
                              onDismiss: () {
                                notifProvider.deleteNotification(item.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.bellOff,
                size: 32,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thông báo nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khi bạn đặt hàng hoặc có cập nhật về thiết bị,\nthông báo sẽ hiển thị chi tiết tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required NotificationItem item,
    required VoidCallback onTap,
    required VoidCallback onDismiss,
  }) {
    // Determine category icon and styling
    IconData iconData = LucideIcons.bell;
    Color iconBg = const Color(0xFFEFF6FF);
    Color iconColor = const Color(0xFF2563EB);

    final isCancelled = item.body.toLowerCase().contains('hủy') ||
        item.title.toLowerCase().contains('hủy') ||
        item.body.contains('CANCELLED');
    final isDelivered = item.body.toLowerCase().contains('thành công') ||
        item.body.toLowerCase().contains('hoàn tất') ||
        item.body.contains('COMPLETED') ||
        item.body.contains('DELIVERED');
    final isShipping = item.body.toLowerCase().contains('giao') ||
        item.body.contains('SHIPPING');

    if (item.type == 'ORDER_CREATED') {
      iconData = LucideIcons.shoppingBag;
      iconBg = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF16A34A);
    } else if (isCancelled) {
      iconData = LucideIcons.xCircle;
      iconBg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
    } else if (isDelivered) {
      iconData = LucideIcons.checkCircle2;
      iconBg = const Color(0xFFD1FAE5);
      iconColor = const Color(0xFF059669);
    } else if (isShipping) {
      iconData = LucideIcons.truck;
      iconBg = const Color(0xFFE0F2FE);
      iconColor = const Color(0xFF0284C7);
    } else {
      iconData = LucideIcons.packageCheck;
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
    }

    return Dismissible(
      key: Key('notif_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
              width: item.isRead ? 1 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: item.isRead ? 0.02 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, size: 19, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.timeAgo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: item.isRead ? const Color(0xFF64748B) : const Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                    if (item.orderCode != null && item.orderCode!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Text(
                              item.orderCode!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Row(
                            children: [
                              Text(
                                'Xem đơn',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                LucideIcons.chevronRight,
                                size: 12,
                                color: Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.isRead) ...[
                const SizedBox(width: 6),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
