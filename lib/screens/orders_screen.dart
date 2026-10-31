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

  const OrdersScreen({super.key, this.showBackButton = true});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _cancelCountdown = 60;
  Timer? _countdownTimer;

  final Set<String> _reordering = {};
  bool _isLoading = true;
  String? _localErrorMessage;
  List<OrderModel> _activeOrders = [];
  List<OrderModel> _historyOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<OrderProvider>(context, listen: false).loadOrders();
      } catch (_) {
        _loadOrders();
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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _localErrorMessage = null;
    });
    try {
      final orders = await OrdersApiService().getOrders();
      final active = <OrderModel>[];
      final history = <OrderModel>[];

      for (final ord in orders) {
        if (ord.isPending ||
            ord.isShipping ||
            ord.rawStatus == 'CONFIRMED' ||
            ord.rawStatus == 'PROCESSING') {
          active.add(ord);
        } else {
          history.add(ord);
        }
      }

      if (mounted) {
        setState(() {
          _activeOrders = active;
          _historyOrders = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localErrorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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
    OrderProvider? provider;
    List<OrderModel> activeOrders = _activeOrders;
    List<OrderModel> historyOrders = _historyOrders;
    bool isLoading = _isLoading;
    String? errorMessage = _localErrorMessage;

    try {
      provider = Provider.of<OrderProvider>(context);
      activeOrders = provider.activeOrders;
      historyOrders = provider.historyOrders;
      isLoading = provider.isLoading;
      errorMessage = provider.errorMessage;
    } catch (_) {}

    return Scaffold(
      backgroundColor: SampleA.background,
      body: SafeArea(
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
                  const Expanded(child: Text('Đơn hàng', style: SampleA.title)),
                  AIconButton(
                    icon: LucideIcons.refreshCw,
                    tooltip: 'Làm mới đơn hàng',
                    onPressed: isLoading
                        ? null
                        : () {
                            provider != null
                                ? provider.refreshOrders()
                                : _loadOrders();
                          },
                  ),
                ],
              ),
            ),
            OrderTabSelector(
              controller: _tabController,
              activeCount: activeOrders.length,
              historyCount: historyOrders.length,
            ),
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
                      provider != null
                          ? await provider.refreshOrders()
                          : await _loadOrders();
                    },
                    child: _buildList(
                      activeOrders,
                      isLoading,
                      errorMessage,
                      () {
                        provider != null
                            ? provider.loadOrders()
                            : _loadOrders();
                      },
                    ),
                  ),
                  RefreshIndicator(
                    color: SampleA.primary,
                    onRefresh: () async {
                      provider != null
                          ? await provider.refreshOrders()
                          : await _loadOrders();
                    },
                    child: _buildList(
                      historyOrders,
                      isLoading,
                      errorMessage,
                      () {
                        provider != null
                            ? provider.loadOrders()
                            : _loadOrders();
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
              onReorder: _reordering.contains(order.deviceId)
                  ? null
                  : () => _handleReorder(order),
            ),
          ),
      ],
    );
  }
}
