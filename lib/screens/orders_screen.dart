import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      if (_cancelCountdown > 0) {
        if (mounted) setState(() => _cancelCountdown--);
      } else {
        timer.cancel();
      }
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
        if (ord.isPending || ord.isShipping || ord.rawStatus == 'CONFIRMED' || ord.rawStatus == 'PROCESSING') {
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
      orderTitle: order.displayTitle,
      onConfirm: () async {
        try {
          OrderProvider? provider;
          try {
            provider = Provider.of<OrderProvider>(context, listen: false);
          } catch (_) {}

          if (provider != null) {
            await provider.cancelOrder(order.id, reason: 'Hủy đơn khẩn cấp từ ứng dụng');
          } else {
            await OrdersApiService().cancelOrder(order.id, reason: 'Hủy đơn khẩn cấp từ ứng dụng');
            await _loadOrders();
          }
          _showFloatingToast('Đã hủy đơn hàng thành công');
        } catch (e) {
          _showFloatingToast('Lỗi khi hủy: ${e is ApiException ? e.message : e.toString()}');
        }
      },
    );
  }

  Future<void> _handleReorder(OrderModel order) async {
    if (order.deviceId.isEmpty) {
      _showFloatingToast('Không tìm thấy thiết bị gán cho đơn hàng này');
      return;
    }

    try {
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
      _showFloatingToast('Đã đặt lại thành công: ${order.displayTitle}');
      _tabController.animateTo(0);
    } catch (e) {
      _showFloatingToast('Lỗi đặt hàng: ${e is ApiException ? e.message : e.toString()}');
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
      backgroundColor: const Color(0xFFF8FAFD),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.35, 1.0],
            colors: [Color(0xFFEBF4FE), Color(0xFFF7FAFD), Colors.white],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
                child: Row(
                  children: [
                    if (widget.showBackButton && Navigator.canPop(context))
                      TactileButton(
                        scale: 0.92,
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1E293B), size: 20),
                        ),
                      ),
                    const Text(
                      'Đơn hàng',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Tab Selector
              OrderTabSelector(
                controller: _tabController,
                activeCount: activeOrders.length,
                historyCount: historyOrders.length,
              ),
              const SizedBox(height: 8),

              // 3. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        provider != null ? await provider.refreshOrders() : await _loadOrders();
                      },
                      color: const Color(0xFF1E293B),
                      child: _buildActiveList(activeOrders, isLoading, errorMessage, () {
                        provider != null ? provider.loadOrders() : _loadOrders();
                      }),
                    ),
                    RefreshIndicator(
                      onRefresh: () async {
                        provider != null ? await provider.refreshOrders() : await _loadOrders();
                      },
                      color: const Color(0xFF1E293B),
                      child: _buildHistoryList(historyOrders, isLoading, errorMessage, () {
                        provider != null ? provider.loadOrders() : _loadOrders();
                      }),
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

  Widget _buildActiveList(List<OrderModel> orders, bool isLoading, String? error, VoidCallback onRetry) {
    if (isLoading && orders.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(strokeWidth: 2.5)));
    }
    if (error != null && orders.isEmpty) {
      return OrderErrorView(message: error, onRetry: onRetry);
    }
    if (orders.isEmpty) {
      return const OrderEmptyView(isHistory: false);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: orders.map((order) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: OrderCardItem(
          order: order,
          cancelCountdown: _cancelCountdown,
          onEmergencyCancel: () => _handleEmergencyCancel(order),
          onCancel: () => _handleEmergencyCancel(order),
          onTrack: () => _showOrderDetail(order),
          onDetailTap: () => _showOrderDetail(order),
        ),
      )).toList(),
    ).animate().fade(duration: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildHistoryList(List<OrderModel> orders, bool isLoading, String? error, VoidCallback onRetry) {
    if (isLoading && orders.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(strokeWidth: 2.5)));
    }
    if (error != null && orders.isEmpty) {
      return OrderErrorView(message: error, onRetry: onRetry);
    }
    if (orders.isEmpty) {
      return const OrderEmptyView(isHistory: true);
    }

    num totalSpend = 0;
    for (final h in orders) {
      if (!h.isCancelled) totalSpend += h.rawAmount;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        OrderHistoryStatsCard(totalOrders: orders.length, totalSpend: totalSpend),
        const SizedBox(height: 16),
        ...orders.map((order) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: OrderCardItem(
            order: order,
            onDetailTap: () => _showOrderDetail(order),
            onReorder: () => _handleReorder(order),
          ),
        )),
      ],
    );
  }
}
