import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'main_layout.dart';
import 'device_detail_screen.dart';
import '../models/device_model.dart';
import '../providers/device_provider.dart';
import '../providers/user_provider.dart';
import '../services/user_profile_service.dart';
import '../widgets/modals/product_selection_sheet.dart';
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

  @override
  void dispose() {
    _userService.removeListener(_onProfileChanged);
    _toastController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    try {
      await Provider.of<DeviceProvider>(context, listen: false).refreshDevices();
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

  void _handleButtonPress(String id, String name, String product) {
    HapticFeedback.lightImpact();
    setState(() => _buttonStateMap[id] = 'ordering');

    Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _buttonStateMap[id] = 'ordered');

      _showFloatingToast(
        message: 'Đã gửi lệnh đặt: $product ($name)',
        onUndo: () {
          HapticFeedback.lightImpact();
          setState(() => _buttonStateMap[id] = 'idle');
          _dismissToast();
          _showFloatingToast(message: 'Đã hoàn tác đơn hàng $product', duration: const Duration(seconds: 2));
        },
      );

      Timer(const Duration(milliseconds: 3200), () {
        if (mounted) setState(() => _buttonStateMap[id] = 'idle');
      });
    });
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
                      onAccountTap: _showAccountSheet,
                      onNotificationTap: () => _showToast('Không có thông báo mới'),
                      onLocationTap: _showLocationPicker,
                    ),
                    const SizedBox(height: 20),

                    if (_hasActiveOrder) ...[
                      HomeActiveOrderBanner(
                        statusText: 'ĐANG GIAO',
                        productName: '1× Nước Lavie 20L',
                        progress: 0.45,
                        onCancel: () {
                          setState(() => _hasActiveOrder = false);
                          _showToast('Đã hủy đơn hàng');
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
                      onAddProduct: (prod) => _showToast('Đã thêm ${prod['name']} vào danh sách chờ ghép nút'),
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
