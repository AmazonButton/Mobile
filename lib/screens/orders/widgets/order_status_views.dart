import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/order_model.dart';
import '../../../widgets/sample_a.dart';
import '../../main_layout.dart';

/// Kept for payment-sheet interactions; replacement screens use accessible AButton.
class TactileButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  const TactileButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = .95,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: child,
    ),
  );
}

class OrderEmptyView extends StatelessWidget {
  final bool isHistory;
  final VoidCallback? onViewHistory;
  const OrderEmptyView({super.key, this.isHistory = false, this.onViewHistory});
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
    children: [
      const Center(child: ABuddy(size: 166)),
      const SizedBox(height: 32),
      Text(
        isHistory ? 'Chưa có lịch sử đơn hàng' : 'Chưa có đơn đang xử lý',
        textAlign: TextAlign.center,
        style: SampleA.title.copyWith(fontSize: 24),
      ),
      const SizedBox(height: 12),
      const Text(
        'Đơn mới sẽ xuất hiện ở đây.',
        textAlign: TextAlign.center,
        style: SampleA.body,
      ),
      const SizedBox(height: 28),
      AButton(
        label: 'Mua sắm ngay',
        onPressed: () {
          MainLayout.switchToTab(context, 0);
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      ),
      if (onViewHistory != null) ...[
        const SizedBox(height: 12),
        AButton(
          label: 'Xem lịch sử',
          onPressed: onViewHistory,
          kind: AButtonKind.secondary,
        ),
      ],
    ],
  );
}

class OrderErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const OrderErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 40),
      const Icon(LucideIcons.wifiOff, color: SampleA.primary, size: 48),
      const SizedBox(height: 20),
      const Text(
        'Không thể tải đơn hàng',
        style: SampleA.section,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(message, style: SampleA.caption, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      AButton(label: 'Thử lại', onPressed: onRetry),
    ],
  );
}

class OrderCancelDialog {
  static void show(
    BuildContext context, {
    required String orderTitle,
    String? buttonName,
    String? price,
    String? orderCode,
    String? storeName,
    OrderModel? order,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CancelConfirmation(
        title: order?.displayTitle ?? orderTitle,
        price: order?.price ?? price,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _CancelConfirmation extends StatefulWidget {
  final String title;
  final String? price;
  final Future<void> Function() onConfirm;
  const _CancelConfirmation({
    required this.title,
    this.price,
    required this.onConfirm,
  });
  @override
  State<_CancelConfirmation> createState() => _CancelConfirmationState();
}

class _CancelConfirmationState extends State<_CancelConfirmation> {
  bool _busy = false;
  String? _error;
  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Không thể hủy đơn. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Hủy đơn hàng?', style: SampleA.section),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: SampleA.body),
            if (widget.price != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(widget.price!, style: SampleA.section),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'SampleA Vietnam',
                    color: SampleA.danger,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            AButton(
              label: 'Xác nhận hủy',
              onPressed: _confirm,
              busy: _busy,
              kind: AButtonKind.danger,
            ),
            const SizedBox(height: 12),
            AButton(
              label: 'Giữ đơn hàng',
              onPressed: _busy ? null : () => Navigator.pop(context),
              kind: AButtonKind.secondary,
            ),
          ],
        ),
      ),
    ),
  );
}
