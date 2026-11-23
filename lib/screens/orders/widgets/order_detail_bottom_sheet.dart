import 'dart:async';
import '../../../services/orders_api_service.dart';
import '../../../services/order_updates.dart';
import '../../../models/order_timeline_entry.dart';
import 'order_server_timeline.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/order_model.dart';
import '../../../widgets/sample_a.dart';
import 'order_card_item.dart';
import 'payos_qr_payment_sheet.dart';

class OrderDetailBottomSheet extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onReorder, onCancel;
  final bool isStoreOwner;
  final bool isAdmin;
  final Future<void> Function(OrderModel order, String nextStatus, String label)?
      onStoreAdvanceStatus;
  final OrdersApiService? service;
  const OrderDetailBottomSheet({
    super.key,
    required this.order,
    this.onReorder,
    this.onCancel,
    this.isStoreOwner = false,
    this.isAdmin = false,
    this.onStoreAdvanceStatus,
    this.service,
  });
  static Future<void> show(
    BuildContext context, {
    required OrderModel order,
    VoidCallback? onReorder,
    VoidCallback? onCancel,
    bool isStoreOwner = false,
    bool isAdmin = false,
    Future<void> Function(OrderModel order, String nextStatus, String label)?
        onStoreAdvanceStatus,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => OrderDetailBottomSheet(
        order: order,
        onReorder: onReorder,
        onCancel: onCancel,
        isStoreOwner: isStoreOwner,
        isAdmin: isAdmin,
        onStoreAdvanceStatus: onStoreAdvanceStatus,
      ),
    ),
  );
  @override
  State<OrderDetailBottomSheet> createState() => _OrderDetailBottomSheetState();
}

class _OrderDetailBottomSheetState extends State<OrderDetailBottomSheet>
    with WidgetsBindingObserver {
  late OrderModel _order = widget.order;
  late final _api = widget.service ?? OrdersApiService();
  List<OrderTimelineEntry> _timeline = [];
  bool _loading = true, _reloadAgain = false, _advancing = false;
  String? _detailError, _timelineError;
  StreamSubscription<String?>? _updates;
  Timer? _debounce;

  (String, String)? _nextAction(OrderModel order) {
    switch (order.rawStatus.toUpperCase()) {
      case 'PENDING':
        return ('CONFIRMED', 'Xác nhận đơn');
      case 'CONFIRMED':
        return ('PREPARING', 'Bắt đầu chuẩn bị');
      case 'PREPARING':
      case 'PROCESSING':
        return ('READY_FOR_DELIVERY', 'Sẵn sàng giao');
      case 'READY_FOR_DELIVERY':
        return ('SHIPPING', 'Xuất giao hàng');
      case 'SHIPPING':
        return ('DELIVERED', 'Xác nhận đã giao');
      default:
        return null;
    }
  }

  Future<void> _handleStoreAdvance() async {
    final next = _nextAction(_order);
    if (next == null || _advancing || widget.onStoreAdvanceStatus == null) return;
    setState(() => _advancing = true);
    try {
      await widget.onStoreAdvanceStatus!(_order, next.$1, next.$2);
      await _reload();
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updates = OrderUpdates.events.listen((id) {
      if (id == null || id == _order.id || id == _order.orderCode) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 250), _reload);
      }
    });
    _loading = false;
    _reload();
  }

  @override
  void dispose() {
    _updates?.cancel();
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<void> _reload() async {
    if (!mounted) return;
    if (_loading) {
      _reloadAgain = true;
      return;
    }
    setState(() {
      _loading = true;
      _detailError = null;
      _timelineError = null;
    });
    await Future.wait([
      () async {
        try {
          final data = await _api.getOrderById(widget.order.id);
          final order = OrderModel.fromJson(data);
          if (order.id != widget.order.id) {
            throw const FormatException('Sai mã đơn hàng');
          }
          if (mounted) setState(() => _order = order);
        } catch (_) {
          if (mounted) {
            setState(
              () => _detailError = 'Chưa thể cập nhật chi tiết đơn hàng.',
            );
          }
        }
      }(),
      () async {
        try {
          final entries = await _api.getTimeline(widget.order.id);
          if (mounted) setState(() => _timeline = entries);
        } catch (_) {
          if (mounted) {
            setState(() => _timelineError = 'Chưa tải được lịch sử đơn hàng.');
          }
        }
      }(),
    ]);
    if (!mounted) return;
    setState(() => _loading = false);
    if (_reloadAgain) {
      _reloadAgain = false;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.isStoreOwner ? _nextAction(_order) : null;
    return _OrderDetailContent(
      order: _order,
      onReorder: widget.onReorder,
      onCancel: widget.onCancel,
      isStoreOwner: widget.isStoreOwner,
      isAdmin: widget.isAdmin,
      storeActionLabel: next?.$2,
      advancing: _advancing,
      onAdvanceStatus: next != null && widget.onStoreAdvanceStatus != null
          ? _handleStoreAdvance
          : null,
      entries: _timeline,
      loading: _loading,
      detailError: _detailError,
      timelineError: _timelineError,
      reload: _reload,
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onReorder, onCancel, onAdvanceStatus;
  final bool isStoreOwner, isAdmin, advancing;
  final String? storeActionLabel;
  final List<OrderTimelineEntry> entries;
  final bool loading;
  final String? detailError, timelineError;
  final VoidCallback reload;
  const _OrderDetailContent({
    required this.order,
    this.onReorder,
    this.onCancel,
    this.isStoreOwner = false,
    this.isAdmin = false,
    this.storeActionLabel,
    this.advancing = false,
    this.onAdvanceStatus,
    required this.entries,
    required this.loading,
    this.detailError,
    this.timelineError,
    required this.reload,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text('Chi tiết đơn hàng'),
      backgroundColor: Colors.white,
    ),
    body: AContent(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              ACard(
                color: SampleA.pale,
                border: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrderStatusBadge(order: order),
                    const SizedBox(height: 12),
                    Text(
                      order.orderCode,
                      style: SampleA.title.copyWith(fontSize: 24),
                    ),
                    if (order.storeName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(order.storeName, style: SampleA.body),
                      ),
                    if (order.time.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(order.time, style: SampleA.caption),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (loading) const LinearProgressIndicator(),
              if (detailError != null)
                Text(detailError!, style: SampleA.caption),
              if (timelineError != null)
                Text(timelineError!, style: SampleA.caption),
              TextButton.icon(
                onPressed: loading ? null : reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới chi tiết'),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ACard(
                  color: SampleA.pale,
                  border: false,
                  child: Text(
                    OrderModel.lifecycleLabel(order.rawStatus),
                    style: SampleA.body,
                  ),
                ),
              ),
              OrderTimeline(rawStatus: order.rawStatus),
              const SizedBox(height: 16),
              if (entries.isNotEmpty || (!loading && timelineError == null))
                OrderServerTimeline(entries: entries),
              if (order.apartment.isNotEmpty) ...[
                const SizedBox(height: 16),
                ACard(
                  color: const Color(0xFFF8FAFC),
                  border: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.mapPin, color: SampleA.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Địa chỉ nhận hàng',
                              style: SampleA.section,
                            ),
                            const SizedBox(height: 6),
                            if (order.customerName.isNotEmpty)
                              Text(
                                order.customerName,
                                style: SampleA.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            Text(order.apartment, style: SampleA.body),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text('Sản phẩm', style: SampleA.section),
              const SizedBox(height: 12),
              OrderProductLine(order: order),
              if (order.items.length > 1) ...[
                const SizedBox(height: 12),
                for (final item in order.items.skip(1))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${item.quantity} × ${item.name}',
                      style: SampleA.body,
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              const Divider(color: SampleA.border),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  const Text('Tổng thanh toán', style: SampleA.body),
                  Text(
                    order.price,
                    style: SampleA.title.copyWith(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.isPaid
                    ? 'Đã thanh toán · ${order.paymentMethod}'
                    : order.isPayos
                    ? 'Chưa thanh toán · PayOS'
                    : 'Thanh toán khi nhận hàng',
                style: SampleA.caption,
              ),
              const SizedBox(height: 24),
              if (isStoreOwner && storeActionLabel != null && onAdvanceStatus != null) ...[
                AButton(
                  label: storeActionLabel!,
                  busy: advancing,
                  onPressed: advancing ? null : onAdvanceStatus,
                ),
                const SizedBox(height: 12),
              ],
              if (!isStoreOwner && !isAdmin && order.canPay) ...[
                AButton(
                  label: order.isPayos
                      ? 'Thanh toán'
                      : 'Thanh toán trước bằng PayOS',
                  onPressed: () =>
                      PayosQrPaymentSheet.show(context, order: order),
                ),
                const SizedBox(height: 12),
              ],
              if (!isStoreOwner && !isAdmin && order.isEmergencyCancellable && onCancel != null) ...[
                AButton(
                  label: 'Hủy đơn hàng này',
                  kind: AButtonKind.danger,
                  onPressed: () {
                    Navigator.pop(context);
                    onCancel!();
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (!isStoreOwner && !isAdmin && order.isCompleted && onReorder != null) ...[
                AButton(
                  label: 'Đặt lại đơn này',
                  onPressed: () {
                    Navigator.pop(context);
                    onReorder!();
                  },
                ),
                const SizedBox(height: 12),
              ],
              AButton(
                label: 'Quay lại đơn hàng',
                kind: AButtonKind.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
