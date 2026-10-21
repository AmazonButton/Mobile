import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'main_layout.dart';
import 'device_detail_screen.dart';
import '../models/device_model.dart';
import '../models/order_model.dart';
import '../providers/device_provider.dart';
import '../providers/order_provider.dart';
import '../providers/user_provider.dart';
import '../providers/address_provider.dart';
import '../providers/notification_provider.dart';
import '../services/user_profile_service.dart';
import '../widgets/modals/product_selection_sheet.dart';
import '../widgets/modals/notification_sheet.dart';
import '../widgets/address_picker_sheet.dart';
import 'home/widgets/widgets.dart';

typedef HomePage = HomeScreen;

/// Màn hình Trang chủ - Orchestrator quản lý luồng dữ liệu, làm mới và điều hướng.
class HomeScreen extends StatefulWidget {
  final bool showBottomNav;

  const HomeScreen({super.key, this.showBottomNav = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _hasActiveOrder = true;
  final UserProfileService _userService = UserProfileService();

  UserProvider? get _userProvider {
    try {
      return Provider.of<UserProvider>(context);
    } catch (_) {
      return null;
    }
  }

  String get _userName => _userProvider?.name ?? _userService.name;
  String get _userShortName => _userProvider?.shortName ?? _userService.shortName;
  String get _userEmail => _userProvider?.email ?? _userService.email;
  String get _userAddress => _userProvider?.address ?? _userService.address;
  String get _userInitials => _userProvider?.initials ?? _userService.initials;
  File? get _userAvatar => _userProvider?.avatarFile ?? _userService.avatarFile;

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  late AnimationController _toastController;
  late Animation<Offset> _toastSlideAnimation;
  late Animation<double> _toastFadeAnimation;
  late Animation<double> _toastScaleAnimation;
  String? _toastMessage;
  VoidCallback? _toastOnUndo;
  Timer? _toastTimer;

  final Map<String, String> _buttonStateMap = {'btn-1': 'idle', 'btn-2': 'idle', 'btn-3': 'idle'};
  late final List<DeviceModel> _fallbackDevices = List.from(DeviceModel.sampleDevices);

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onProfileChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try { Provider.of<DeviceProvider>(context, listen: false).loadDevices(); } catch (_) {}
      try { Provider.of<UserProvider>(context, listen: false).loadProfile(); } catch (_) {}
      try {
        final orderProv = Provider.of<OrderProvider>(context, listen: false);
        orderProv.loadOrders().then((_) {
          try {
            if (mounted) {
              Provider.of<NotificationProvider>(context, listen: false).syncOrders(orderProv.orders);
            }
          } catch (_) {}
        });
      } catch (_) {}
      try { Provider.of<AddressProvider>(context, listen: false).loadAddresses(); } catch (_) {}
      try { Provider.of<NotificationProvider>(context, listen: false).loadNotifications(); } catch (_) {}
    });

    _bannerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _toastSlideAnimation = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _toastController, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn),
    );
    _toastFadeAnimation = CurvedAnimation(parent: _toastController, curve: Curves.easeOut, reverseCurve: Curves.easeIn);
    _toastScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _toastController, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn),
    );
  }

  Timer? _bannerTicker;

  @override
  void dispose() {
    _bannerTicker?.cancel();
    _userService.removeListener(_onProfileChanged);
    _toastController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    final deviceProv = Provider.of<DeviceProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    try {
      await deviceProv.refreshDevices();
      await orderProv.refreshOrders();
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 600));
    }
    if (mounted) {
      _showToast('Đã làm mới dữ liệu nút bấm');
    }
  }

  void _showFloatingToast({required String message, VoidCallback? onUndo, Duration duration = const Duration(seconds: 4)}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastOnUndo = onUndo;
    });
    _toastController.forward(from: 0.0);
    _toastTimer = Timer(duration, _dismissToast);
  }

  void _dismissToast() {
    _toastTimer?.cancel();
    if (_toastController.isAnimating || _toastController.isCompleted) {
      _toastController.reverse().then((_) {
        if (mounted) setState(() { _toastMessage = null; _toastOnUndo = null; });
      });
    }
  }

  void _showToast(String message) => _showFloatingToast(message: message);

  Future<void> _handleButtonPress(String id, String name, String product) async {
    HapticFeedback.lightImpact();
    setState(() => _buttonStateMap[id] = 'ordering');

    DeviceModel? targetDevice;
    try {
      final devProvider = Provider.of<DeviceProvider>(context, listen: false);
      targetDevice = devProvider.getDeviceById(id);
    } catch (_) {}

    final currentProduct = targetDevice?.product ?? product;
    final currentPrice = targetDevice?.price ?? '65.000đ';
    final currentName = targetDevice?.name ?? name;

    OrderProvider? orderProvider;
    try {
      orderProvider = Provider.of<OrderProvider>(context, listen: false);
    } catch (_) {}

    OrderModel? createdOrder;
    if (orderProvider != null) {
      createdOrder = await orderProvider.createOneTouchOrder(
        deviceId: id,
        buttonName: currentName,
        productName: currentProduct,
        productPrice: currentPrice,
        customerName: _userName,
        apartment: _userAddress,
      );
    }

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _buttonStateMap[id] = 'ordered';
      _hasActiveOrder = true;
    });

    _showFloatingToast(
      message: '⚡ Đã đặt: $currentProduct ($currentName)! Cửa sổ an toàn 60s để hủy.',
      duration: const Duration(seconds: 5),
      onUndo: () {
        HapticFeedback.lightImpact();
        setState(() => _buttonStateMap[id] = 'idle');
        _dismissToast();
        if (createdOrder != null && orderProvider != null) {
          orderProvider.cancelOrder(createdOrder.id, reason: 'Hoàn tác ngay từ trang chủ');
        }
        _showFloatingToast(message: 'Đã hoàn tác đơn hàng $currentProduct', duration: const Duration(seconds: 2));
      },
    );

    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _buttonStateMap[id] = 'idle');
    });
  }

  void _showAssignProductSheet(Map<String, String> prod, List<DeviceModel> devices) {
    HapticFeedback.lightImpact();
    if (devices.isEmpty) {
      _showToast('Chưa có nút bấm nào để gán sản phẩm');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.radio_button_checked, size: 20, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chọn nút bấm để đặt hàng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Gán ${prod['name']} (${prod['price']}) vào nút:',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...devices.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Hiện tại: ${d.product} • ${d.price}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Gán vào nút', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    try {
                      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
                      deviceProvider.updateDeviceProductByName(d.id, prod['name']!, prod['price']!);
                    } catch (_) {
                      final badge = prod['name']!.contains('Gas') ? '12kg' : '20L';
                      final updated = d.copyWith(product: prod['name']!, price: prod['price']!, badgeText: badge);
                      final idx = _fallbackDevices.indexWhere((dev) => dev.id == d.id);
                      if (idx != -1) setState(() => _fallbackDevices[idx] = updated);
                    }
                    _showFloatingToast(
                      message: 'Đã gán ${prod['name']} vào ${d.name}. Bấm "Đặt ngay" để tạo đơn!',
                      duration: const Duration(seconds: 4),
                    );
                  },
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountSheet() {
    HomeAccountSheet.show(
      context,
      userName: _userName,
      userEmail: _userEmail,
      userAddress: _userAddress,
      userInitials: _userInitials,
      userAvatar: _userAvatar,
      onLogout: () => HomeAccountSheet.showLogoutDialog(context),
    );
  }

  void _showLocationPicker() {
    AddressPickerSheet.show(context, onAddressSelected: (addr) => _showToast('Đã chuyển sang: $addr'));
  }

  void _showSettingsDialog(DeviceModel device) {
    HapticFeedback.lightImpact();
    ProductSelectionSheet.show(
      context: context,
      buttonName: device.name,
      currentProductName: device.product,
      onSave: (selectedProduct) {
        try {
          context.read<DeviceProvider>().updateDeviceProduct(device.id, selectedProduct);
        } catch (_) {
          final badge = selectedProduct.shortName.toLowerCase().contains('gas') ? '12kg' : '20L';
          final updated = device.copyWith(product: selectedProduct.shortName, price: selectedProduct.priceFormatted, badgeText: badge);
          final idx = _fallbackDevices.indexWhere((d) => d.id == device.id);
          if (idx != -1) setState(() => _fallbackDevices[idx] = updated);
        }
        _showToast('Đã gắn "${selectedProduct.name}" vào ${device.name}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DeviceModel> displayDevices = _fallbackDevices;
    bool isDevLoading = false;
    try {
      final provider = Provider.of<DeviceProvider>(context);
      displayDevices = provider.devices;
      isDevLoading = provider.isLoading;
    } catch (_) {}

    OrderProvider? orderProvider;
    OrderModel? currentActiveOrder;
    try {
      orderProvider = Provider.of<OrderProvider>(context);
      if (orderProvider.activeOrders.isNotEmpty) {
        currentActiveOrder = orderProvider.activeOrders.first;
      }
    } catch (_) {}

    NotificationProvider? notifProvider;
    try {
      notifProvider = Provider.of<NotificationProvider>(context);
    } catch (_) {}

    final bool showActiveBanner = _hasActiveOrder && (currentActiveOrder != null || _hasActiveOrder);
    final String bannerTitle = currentActiveOrder?.displayTitle ?? '1× Nước Lavie 20L';
    final String bannerStatus = (currentActiveOrder != null && currentActiveOrder.isWithinSafetyWindow)
        ? 'CỬA SỔ AN TOÀN (${currentActiveOrder.remainingSafetySeconds}S)'
        : (currentActiveOrder != null && currentActiveOrder.isShipping ? 'ĐANG GIAO HÀNG' : 'ĐANG CHUẨN BỊ');
    final double bannerProgress = (currentActiveOrder != null && currentActiveOrder.isShipping)
        ? 0.75
        : (currentActiveOrder != null && !currentActiveOrder.isWithinSafetyWindow)
            ? 0.50
            : 0.25;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF2563EB),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeaderCard(
                      userAvatar: _userAvatar,
                      userInitials: _userInitials,
                      userShortName: _userShortName,
                      userAddress: _userAddress,
                      unreadNotificationCount: notifProvider?.unreadCount ?? 0,
                      onAccountTap: _showAccountSheet,
                      onNotificationTap: () => NotificationSheet.show(context),
                      onLocationTap: _showLocationPicker,
                    ),
                    const SizedBox(height: 20),

                    if (showActiveBanner) ...[
                      HomeActiveOrderBanner(
                        statusText: bannerStatus,
                        productName: bannerTitle,
                        progress: bannerProgress,
                        onCancel: () {
                          if (currentActiveOrder != null && orderProvider != null) {
                            orderProvider.cancelOrder(currentActiveOrder.id, reason: 'Hủy đơn từ trang chủ');
                          }
                          setState(() => _hasActiveOrder = false);
                          _showToast('Đã hủy đơn hàng $bannerTitle');
                        },
                        onTap: () {
                          HapticFeedback.lightImpact();
                          MainLayout.switchToTab(context, 2);
                        },
                      ),
                      const SizedBox(height: 22),
                    ],

                    HomeSmartButtonsGrid(
                      devices: displayDevices,
                      isLoading: isDevLoading,
                      buttonStateMap: _buttonStateMap,
                      onManage: () => MainLayout.switchToTab(context, 1),
                      onAddDevice: () => _showToast('Đang quét Bluetooth tìm Smart Button mới...'),
                      onDeviceTap: (device) {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DeviceDetailScreen(
                              deviceId: device.id,
                              deviceName: device.name,
                              room: device.room,
                              productName: device.product,
                              productPrice: device.price,
                              battery: device.battery,
                            ),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      onDeviceOrder: (device) => _handleButtonPress(device.id, device.name, device.product),
                      onDeviceSettings: _showSettingsDialog,
                    ),
                    const SizedBox(height: 16),

                    HomeQuickShopShelf(
                      onAddProduct: (prod) => _showAssignProductSheet(prod, displayDevices),
                      onSeeAll: () => _showToast('Xem danh mục sản phẩm gợi ý'),
                    ).animate().fade(duration: 400.ms),
                    const SizedBox(height: 24),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hoạt động gần đây',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const HomeRecentActivities(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            if (_toastMessage != null)
              HomeFloatingToast(
                slideAnimation: _toastSlideAnimation,
                fadeAnimation: _toastFadeAnimation,
                scaleAnimation: _toastScaleAnimation,
                message: _toastMessage!,
                onUndo: _toastOnUndo,
              ),
          ],
        ),
      ),
    );
  }
}
