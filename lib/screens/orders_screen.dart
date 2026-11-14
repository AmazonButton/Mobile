import '../widgets/smart_order_tour.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/sample_a.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../services/services.dart';
import 'orders/widgets/widgets.dart';

/// Màn hình Quản lý Đơn hàng - Orchestrator quản lý danh sách, phân tab và tác vụ hủy/đặt lại
class OrdersScreen extends StatefulWidget {
  final bool showBackButton;
  final SmartOrderTour? tour;
  final String? initialOrderId;

  const OrdersScreen({
    super.key,
    this.showBackButton = true,
    this.initialOrderId,
    this.tour,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _cancelCountdown = 60;
  Timer? _countdownTimer;

  final Set<String> _reordering = {};
  final OrderProvider _fallback = OrderProvider();
  OrderProvider _ordersProvider({bool listen = false}) {
    try {
      return Provider.of<OrderProvider>(context, listen: listen);
    } catch (_) {
      return _fallback;
    }
  }

  void _redrawFallback() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fallback.addListener(_redrawFallback);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = _ordersProvider();
      provider.startLiveUpdates();
      await provider.loadOrders();
      final id = widget.initialOrderId;
      if (!mounted || id == null || id.isEmpty) return;
      try {
        final json = await OrdersApiService().getOrderById(id);
        if (mounted) _showOrderDetail(OrderModel.fromJson(json));
      } catch (_) {
        if (mounted) {
          _showFloatingToast('Không thể mở đơn hàng. Vui lòng tải lại.');
        }
      }
    });
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _cancelCountdown = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cancelCountdown > 0) _cancelCountdown--;
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _fallback.removeListener(_redrawFallback);
    _fallback.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() => _fallback.loadOrders();

  void _showFloatingToast(String message) => OrderToast.show(context, message);

  void _handleEmergencyCancel(OrderModel order) {
    OrderCancelDialog.show(
      context,
      order: order,
      orderTitle: order.displayTitle,
      buttonName: order.buttonName,
      price: order.price,
      orderCode: order.orderCode,
      storeName: order.storeName,
      onConfirm: () async {
        try {
          OrderProvider? provider;
          try {
            provider = Provider.of<OrderProvider>(context, listen: false);
          } catch (_) {}

          if (provider != null) {
            await provider.cancelOrder(
              order.id,
              reason: 'Hủy đơn khẩn cấp từ ứng dụng',
            );
          } else {
            await OrdersApiService().cancelOrder(
              order.id,
              reason: 'Hủy đơn khẩn cấp từ ứng dụng',
            );
            await _loadOrders();
          }
          _showFloatingToast(
            'Đã hủy đơn hàng ${order.displayTitle} từ ${order.buttonName} thành công',
          );
        } catch (e) {
          _showFloatingToast(
            'Lỗi khi hủy: ${e is ApiException ? e.message : e.toString()}',
          );
          rethrow;
        }
      },
    );
  }

  Future<void> _handleReorder(OrderModel order) async {
    if (order.deviceId.isEmpty) {
      _showFloatingToast('Không tìm thấy thiết bị gán cho đơn hàng này');
      return;
    }

    if (!_reordering.add(order.deviceId)) return;
    setState(() {});
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Đặt lại đơn hàng?', style: SampleA.section),
          content: Text(order.displayTitle, style: SampleA.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Quay lại'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xác nhận đặt lại'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      OrderProvider? provider;
      try {
        provider = Provider.of<OrderProvider>(context, listen: false);
      } catch (_) {}

      if (provider != null) {
        await provider.quickReorder(order.deviceId);
      } else {
        await OrdersApiService().quickReorder(deviceId: order.deviceId);
        await _loadOrders();
      }
      if (!mounted) return;
      _showFloatingToast('Đã đặt lại thành công: ${order.displayTitle}');
      _tabController.animateTo(0);
    } catch (e) {
      if (mounted) {
        _showFloatingToast(
          'Lỗi đặt hàng: ${e is ApiException ? e.message : e.toString()}',
        );
      }
    } finally {
      _reordering.remove(order.deviceId);
      if (mounted) setState(() {});
    }
  }

  void _showOrderDetail(OrderModel order) {
    OrderDetailBottomSheet.show(
      context,
      order: order,
      onReorder: () => _handleReorder(order),
      onCancel: () => _handleEmergencyCancel(order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _ordersProvider(listen: true);
    final activeOrders = provider.activeOrders;
    final historyOrders = provider.historyOrders;
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    return Scaffold(
      backgroundColor: SampleA.background,
      body: AContent(
        maxWidth: SampleA.listWidth,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    if (widget.showBackButton && Navigator.canPop(context)) ...[
                      AIconButton(
                        icon: LucideIcons.chevronLeft,
                        tooltip: 'Quay lại',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Expanded(
                      child: Text('Đơn hàng', style: SampleA.title),
                    ),
                    AIconButton(
                      icon: LucideIcons.filter,
                      tooltip: 'Lọc đơn hàng',
                      onPressed: () => _showFilters(provider),
                    ),
                    AIconButton(
                      icon: LucideIcons.refreshCw,
                      tooltip: 'Làm mới đơn hàng',
                      onPressed: isLoading
                          ? null
                          : () {
                              provider.refreshOrders();
                            },
                    ),
                  ],
                ),
              ),
              OrderTabSelector(
                key: widget.tour?.key(TourStep.orders),
                controller: _tabController,
                activeCount: activeOrders.length,
                historyCount: historyOrders.length,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  provider.totalItems == null
                      ? 'Đã tải ${provider.orders.length} đơn'
                      : 'Đã tải ${provider.orders.length}/${provider.totalItems} đơn',
                  style: SampleA.caption,
                ),
              ),
              if (isLoading) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              if (errorMessage != null &&
                  (activeOrders.isNotEmpty || historyOrders.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Chưa thể làm mới dữ liệu. Kéo xuống để thử lại.',
                    style: SampleA.caption.copyWith(color: SampleA.warning),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      color: SampleA.primary,
                      onRefresh: () async {
                        await provider.refreshOrders();
                      },
                      child: _buildList(
                        activeOrders,
                        isLoading,
                        errorMessage,
                        () {
                          provider.loadOrders();
                        },
                      ),
                    ),
                    RefreshIndicator(
                      color: SampleA.primary,
                      onRefresh: () async {
                        await provider.refreshOrders();
                      },
                      child: _buildList(
                        historyOrders,
                        isLoading,
                        errorMessage,
                        () {
                          provider.loadOrders();
                        },
                        history: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadMoreButton(OrderProvider provider) => Column(
    children: [
      if (provider.loadMoreError != null)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Chưa tải được trang tiếp theo. Vui lòng thử lại.'),
        ),
      AButton(
        label: provider.loadMoreError == null
            ? 'Tải thêm đơn hàng'
            : 'Thử tải thêm',
        busy: provider.loadingMore,
        onPressed: provider.loadingMore ? null : provider.loadMore,
      ),
    ],
  );

  Future<void> _showFilters(OrderProvider provider) async {
    var status = provider.statusFilter ?? '';
    var payment = provider.paymentFilter ?? '';
    DateTimeRange? range = provider.fromDate != null && provider.toDate != null
        ? DateTimeRange(
            start: DateUtils.dateOnly(provider.fromDate!),
            end: DateUtils.dateOnly(provider.toDate!),
          )
        : null;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Lọc đơn hàng', style: SampleA.section),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái đơn',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Tất cả trạng thái'),
                    ),
                    for (final value in [
                      'PENDING',
                      'CONFIRMED',
                      'PROCESSING',
                      'PREPARING',
                      'READY_FOR_DELIVERY',
                      'SHIPPING',
                      'DELIVERY_FAILED',
                      'DELIVERED',
                      'COMPLETED',
                      'CANCELLED',
                      'REJECTED',
                    ])
                      DropdownMenuItem(
                        value: value,
                        child: Text(OrderModel.lifecycleLabel(value)),
                      ),
                  ],
                  onChanged: (value) => update(() => status = value ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: payment,
                  decoration: const InputDecoration(labelText: 'Thanh toán'),
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Tất cả thanh toán'),
                    ),
                    DropdownMenuItem(
                      value: 'PAID',
                      child: Text('Đã thanh toán'),
                    ),
                    DropdownMenuItem(
                      value: 'UNPAID',
                      child: Text('Chưa thanh toán'),
                    ),
                    DropdownMenuItem(
                      value: 'REFUNDED',
                      child: Text('Đã hoàn tiền'),
                    ),
                  ],
                  onChanged: (value) => update(() => payment = value ?? ''),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    range == null
                        ? 'Chọn khoảng ngày'
                        : '${range!.start.day}/${range!.start.month}/${range!.start.year} – ${range!.end.day}/${range!.end.month}/${range!.end.year}',
                  ),
                  onPressed: () async {
                    final selected = await showDateRangePicker(
                      context: sheetContext,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: range,
                    );
                    if (sheetContext.mounted && selected != null) {
                      update(() => range = selected);
                    }
                  },
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    provider.setFilters(
                      status: status.isEmpty ? null : status,
                      paymentStatus: payment.isEmpty ? null : payment,
                      fromDate: range?.start,
                      toDate: range == null
                          ? null
                          : DateTime(
                              range!.end.year,
                              range!.end.month,
                              range!.end.day + 1,
                            ).subtract(const Duration(microseconds: 1)),
                    );
                  },
                  child: const Text('Áp dụng'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    provider.setFilters();
                  },
                  child: const Text('Xóa bộ lọc'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    List<OrderModel> orders,
    bool loading,
    String? error,
    VoidCallback retry, {
    bool history = false,
  }) {
    if (loading && orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(48),
        children: const [
          Center(child: CircularProgressIndicator(color: SampleA.primary)),
        ],
      );
    }
    if (error != null && orders.isEmpty) {
      return OrderErrorView(message: error, onRetry: retry);
    }
    final paging = _ordersProvider();
    if (orders.isEmpty && paging.hasMore) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Chưa có đơn thuộc tab này trong số đơn đã tải.'),
          _loadMoreButton(paging),
        ],
      );
    }
    if (orders.isEmpty) {
      return OrderEmptyView(
        isHistory: history,
        onViewHistory: history ? null : () => _tabController.animateTo(1),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (history)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Gần đây', style: SampleA.section),
          ),
        for (final order in orders)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OrderCardItem(
              key: ValueKey(order.id),
              order: order,
              cancelCountdown: _cancelCountdown,
              onEmergencyCancel: () => _handleEmergencyCancel(order),
              onCancel: () => _handleEmergencyCancel(order),
              onTrack: () => _showOrderDetail(order),
              onDetailTap: () => _showOrderDetail(order),
              isReordering: _reordering.contains(order.deviceId),
              onReorder: order.deviceId.isEmpty
                  ? null
                  : () => _handleReorder(order),
            ),
          ),
        if (paging.hasMore) _loadMoreButton(paging),
      ],
    );
  }
}
