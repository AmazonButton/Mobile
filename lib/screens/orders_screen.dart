import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/services.dart';

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
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _historyOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _cancelCountdown = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cancelCountdown > 0) {
        if (mounted) {
          setState(() {
            _cancelCountdown--;
          });
        }
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

  String _formatCurrency(num amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join()}đ';
  }

  Map<String, dynamic> _parseOrder(Map<String, dynamic> ord) {
    String title = 'Đơn hàng SmartOrder';
    if (ord['items'] is List && (ord['items'] as List).isNotEmpty) {
      final first = (ord['items'] as List).first;
      final qty = first['quantity'] ?? 1;
      final name = first['productNameSnapshot'] ?? first['product']?['productName'] ?? 'Sản phẩm';
      title = '${qty}x $name';
    } else if (ord['orderItems'] is List && (ord['orderItems'] as List).isNotEmpty) {
      final first = (ord['orderItems'] as List).first;
      final qty = first['quantity'] ?? 1;
      final name = first['product']?['name'] ?? first['productName'] ?? 'Sản phẩm';
      title = '${qty}x $name';
    }

    final buttonName = ord['button']?['buttonName'] ?? ord['buttonName'] ?? 'Nút bấm IoT';
    final deviceId = ord['button']?['deviceId'] ?? ord['deviceId'] ?? '';

    String dateStr = 'Gần đây';
    if (ord['createdAt'] != null) {
      try {
        final dt = DateTime.parse(ord['createdAt'].toString()).toLocal();
        final now = DateTime.now();
        if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
          dateStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}, Hôm nay';
        } else {
          dateStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}, ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        }
      } catch (_) {
        dateStr = ord['createdAt'].toString();
      }
    }

    final rawAmount = ord['totalAmount'] ?? ord['subtotalAmount'] ?? 0;
    final num amt = num.tryParse(rawAmount.toString()) ?? 0;
    final priceStr = _formatCurrency(amt);

    final rawStatus = (ord['orderStatus'] ?? ord['status'] ?? 'PENDING').toString().toUpperCase();

    IconData icon = LucideIcons.package;
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('nước') || lowerTitle.contains('lavie')) {
      icon = LucideIcons.droplets;
    } else if (lowerTitle.contains('gas') || lowerTitle.contains('petrolimex')) {
      icon = LucideIcons.flame;
    } else if (lowerTitle.contains('gạo') || lowerTitle.contains('st25')) {
      icon = LucideIcons.shoppingBag;
    }

    return {
      'id': ord['orderId']?.toString() ?? ord['id']?.toString() ?? '',
      'orderNumber': ord['orderNumber'] ?? ord['orderCode'] ?? '#ORD',
      'title': title,
      'buttonName': buttonName,
      'deviceId': deviceId,
      'date': dateStr,
      'price': priceStr,
      'rawAmount': amt,
      'status': rawStatus,
      'icon': icon,
      'raw': ord,
    };
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final rawOrders = await OrdersApiService().getOrders();
      final active = <Map<String, dynamic>>[];
      final history = <Map<String, dynamic>>[];

      for (final raw in rawOrders) {
        final ord = Map<String, dynamic>.from(raw as Map);
        final parsed = _parseOrder(ord);
        final status = parsed['status'] as String;

        if (status == 'PENDING' || status == 'CONFIRMED' || status == 'PROCESSING' || status == 'SHIPPING') {
          active.add(parsed);
        } else {
          history.add(parsed);
        }
      }

      if (mounted) {
        setState(() {
          _activeOrders = active;
          _historyOrders = history;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFloatingToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 10,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.checkCircle2,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleEmergencyCancel(Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final orderTitle = order['title'] as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(LucideIcons.shieldAlert, color: Color(0xFFEF4444), size: 22),
            SizedBox(width: 10),
            Text(
              'Hủy đơn khẩn cấp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          'Đơn hàng "$orderTitle" đang trong thời gian an toàn. Bạn có muốn hủy ngay lập tức không?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Giữ đơn',
                style: TextStyle(
                    color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await OrdersApiService().cancelOrder(orderId, reason: 'Hủy đơn khẩn cấp từ ứng dụng');
                _showFloatingToast('Đã hủy đơn hàng thành công');
                _loadOrders();
              } catch (e) {
                _showFloatingToast('Lỗi khi hủy: ${e is ApiException ? e.message : e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xác nhận hủy',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReorder(Map<String, dynamic> order) async {
    final deviceId = order['deviceId']?.toString() ?? '';
    final title = order['title'] as String;

    if (deviceId.isEmpty) {
      _showFloatingToast('Không tìm thấy thiết bị gán cho đơn hàng này');
      return;
    }

    try {
      await OrdersApiService().quickReorder(deviceId: deviceId);
      _showFloatingToast('Đã đặt lại thành công: $title');
      _tabController.animateTo(0);
      _loadOrders();
    } catch (e) {
      _showFloatingToast('Lỗi đặt hàng: ${e is ApiException ? e.message : e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            colors: [
              Color(0xFFEBF4FE),
              Color(0xFFF7FAFD),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= 1. APP BAR =================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
                child: Row(
                  children: [
                    if ((widget.showBackButton as dynamic) == true && Navigator.canPop(context))
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
                          child: const Icon(
                            LucideIcons.chevronLeft,
                            color: Color(0xFF1E293B),
                            size: 20,
                          ),
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

              // ================= 2. CUSTOM SEGMENTED TAB BAR =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
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
                      Tab(text: 'Đang diễn ra (${_activeOrders.length})'),
                      Tab(text: 'Lịch sử (${_historyOrders.length})'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ================= 3. TAB VIEWS =================
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Đang diễn ra
                    RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: const Color(0xFF1E293B),
                      child: _buildActiveTabView(),
                    ),

                    // Tab 2: Lịch sử
                    RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: const Color(0xFF1E293B),
                      child: _buildHistoryTabView(),
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

  // ================= TAB 1: ĐANG DIỄN RA =================
  Widget _buildActiveTabView() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_activeOrders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Column(
              children: [
                Icon(LucideIcons.packageCheck, size: 40, color: Color(0xFF94A3B8)),
                SizedBox(height: 14),
                Text(
                  'Không có đơn hàng nào đang diễn ra',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Nhấn nút vật lý hoặc bấm đặt trên ứng dụng để khởi tạo đơn hàng mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        ..._activeOrders.map((order) {
          final isPending = order['status'] == 'PENDING';

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: isPending
                ? _buildPendingEmergencyCard(order)
                : _buildLiveTrackingCard(order),
          );
        }),
      ],
    ).animate().fade(duration: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildPendingEmergencyCard(Map<String, dynamic> order) {
    final title = order['title'] as String;
    final buttonName = order['buttonName'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    LucideIcons.shieldAlert,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'CỬA SỔ AN TOÀN 60 GIÂY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  '⏱ ${_cancelCountdown}s',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$buttonName • Vừa gửi lệnh',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 14),

          TactileButton(
            scale: 0.96,
            onTap: () => _handleEmergencyCancel(order),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.x, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Hủy đơn ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTrackingCard(Map<String, dynamic> order) {
    final title = order['title'] as String;
    final buttonName = order['buttonName'] as String;
    final orderNumber = order['orderNumber'] as String;
    final status = order['status'] as String;
    final isShipping = status == 'SHIPPING';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isShipping ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isShipping ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isShipping ? 'Đang giao hàng' : 'Đang chuẩn bị',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isShipping ? const Color(0xFF2563EB) : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                orderNumber,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$buttonName • ${order['price']}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 22),

          _buildTimeline(isShipping),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                flex: 6,
                child: TactileButton(
                  scale: 0.96,
                  onTap: () => _showFloatingToast('Đơn hàng đang được điều phối'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Theo dõi tiến trình',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: TactileButton(
                  scale: 0.96,
                  onTap: () => _handleEmergencyCancel(order),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: const Center(
                      child: Text(
                        'Hủy đơn',
                        style: TextStyle(
                          color: Color(0xFFF43F5E),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(bool isShipping) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTimelineNode(
              icon: LucideIcons.checkCircle2,
              isCompleted: true,
              isActive: false,
            ),
            Expanded(
              child: Container(
                height: 2,
                color: const Color(0xFF10B981),
              ),
            ),
            _buildTimelineNode(
              icon: LucideIcons.package,
              isCompleted: true,
              isActive: !isShipping,
            ),
            Expanded(
              child: Container(
                height: 2,
                color: isShipping ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              ),
            ),
            _buildTimelineNode(
              icon: LucideIcons.truck,
              isCompleted: false,
              isActive: isShipping,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đã nhận',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
            Text(
              'Chuẩn bị',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
            Text(
              'Đang giao',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineNode({
    required IconData icon,
    required bool isCompleted,
    required bool isActive,
  }) {
    Color bg;
    Color iconColor;
    Border? border;

    if (isCompleted) {
      bg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF10B981);
      border = Border.all(color: const Color(0xFF10B981), width: 1.5);
    } else if (isActive) {
      bg = const Color(0xFFA3B8CD);
      iconColor = Colors.white;
      border = Border.all(color: const Color(0xFF64748B), width: 1.5);
    } else {
      bg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF94A3B8);
      border = Border.all(color: const Color(0xFFE2E8F0), width: 1);
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Center(
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  // ================= TAB 2: LỊCH SỬ =================
  Widget _buildHistoryTabView() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_historyOrders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Column(
              children: [
                Icon(LucideIcons.history, size: 40, color: Color(0xFF94A3B8)),
                SizedBox(height: 14),
                Text(
                  'Chưa có đơn hàng nào trong lịch sử',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Lịch sử các đơn hàng đã nhận hoặc đã hủy sẽ hiển thị tại đây.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Calculate total spend
    num totalSpend = 0;
    for (final h in _historyOrders) {
      if (h['status'] != 'CANCELLED') {
        totalSpend += (h['rawAmount'] as num? ?? 0);
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // ── Card 1: Stats ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.barChart2,
                    size: 20,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TỔNG KẾT ĐƠN HÀNG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_historyOrders.length} đơn',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tổng chi: ${_formatCurrency(totalSpend)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── List of Past Orders ──
        ..._historyOrders.map((order) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildPastOrderCard(order),
          );
        }),
      ],
    );
  }

  Widget _buildPastOrderCard(Map<String, dynamic> order) {
    final title = order['title'] as String;
    final date = order['date'] as String;
    final price = order['price'] as String;
    final icon = order['icon'] as IconData;
    final status = order['status'] as String;
    final isCancelled = status == 'CANCELLED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCancelled ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCancelled ? 'Đã hủy' : 'Đã giao',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCancelled ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TactileButton(
                  scale: 0.96,
                  onTap: () => _showFloatingToast('Mã đơn: ${order['orderNumber']}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.receipt,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TactileButton(
                  scale: 0.96,
                  onTap: () => _handleReorder(order),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.rotateCcw,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const TactileButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
