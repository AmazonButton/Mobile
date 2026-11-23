import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/device_model.dart';
import '../models/order_model.dart';
import '../providers/address_provider.dart';
import '../providers/device_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';
import '../services/stores_api_service.dart';
import '../services/system_staff_api_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/address_picker_sheet.dart';
import '../widgets/app_motion.dart';
import '../widgets/modals/connect_device_sheet.dart';
import '../widgets/modals/notification_sheet.dart';
import '../widgets/sample_a.dart';
import '../widgets/smart_order_tour.dart';
import 'customer_buttons_screen.dart';
import 'home/widgets/widgets.dart';
import 'main_layout.dart';
import 'shop_stores_screen.dart';
import 'store_wallet_screen.dart';
import 'system_staff/system_staff_returns_screen.dart';
import 'system_staff/system_staff_warranty_screen.dart';

typedef HomePage = HomeScreen;

/// Role-aware Home Orchestrator:
/// - CUSTOMER: Delivery location, live active order tracker, 6-service dock, 1-touch IoT hero, 3-step onboarding.
/// - STORE_OWNER: Emerald merchant command center with live order queue stats, store wallet balance, store info sheet & product/device shortcuts.
/// - SYSTEM_STAFF: Technical IoT hub with fleet stats, warehouse/allocation/template, 1-1 warranty & return receipt flows.
/// - ADMIN: Platform governance hub with live partner store count, fleet telemetry, orders & warranty supervision.
class HomeScreen extends StatefulWidget {
  final bool showBottomNav;
  final SmartOrderTour? tour;

  const HomeScreen({super.key, this.showBottomNav = false, this.tour});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final UserProfileService _userService = UserProfileService();

  UserProvider? get _userProvider {
    try {
      return Provider.of<UserProvider>(context);
    } catch (_) {
      return null;
    }
  }

  String get _userShortName =>
      _userProvider?.shortName ?? _userService.shortName;
  String get _userAddress {
    final address = context.read<AddressProvider?>()?.currentAddressDisplay ?? '';
    return address.isEmpty ? 'Thêm địa chỉ giao hàng' : address;
  }

  String get _userInitials => _userProvider?.initials ?? _userService.initials;
  String? get _userAvatarUrl =>
      _userProvider?.avatarUrl ?? _userService.avatarUrl;
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
  final _homeScrollController = ScrollController();
  bool _showCompactHeader = false;

  Map<String, dynamic>? _fleetStats;
  Map<String, dynamic>? _storeWallet;
  int _adminStoreCount = 0;

  Future<void> _loadFleetStats() async {
    try {
      final stats = await SystemStaffApiService().getFleetStats();
      if (mounted) setState(() => _fleetStats = stats);
    } catch (_) {}
  }

  Future<void> _loadStoreWallet() async {
    try {
      final wallet = await StoresApiService().getStoreWallet();
      if (mounted) setState(() => _storeWallet = wallet);
    } catch (_) {}
  }

  Future<void> _loadAdminStoreCount() async {
    try {
      final stores = await StoresApiService().getAdminStores();
      if (mounted) setState(() => _adminStoreCount = stores.length);
    } catch (_) {}
  }

  int _readIntStat(Map<String, dynamic>? m, List<String> keys, int fallback) {
    if (m == null) return fallback;
    for (final k in keys) {
      final v = m[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  String _formatVnd(num value) {
    final str = value.abs().round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final pos = str.length - i;
      buf.write(str[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return '${value < 0 ? '-' : ''}${buf.toString()} ₫';
  }

  void _onHomeScroll() {
    final compact = _homeScrollController.offset > 170;
    if (compact != _showCompactHeader) {
      setState(() => _showCompactHeader = compact);
    }
  }

  void _openShopStores() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopStoresScreen(tour: widget.tour),
      ),
    );
  }

  void _openStoreWallet() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StoreWalletScreen()),
    );
  }

  Future<void> _openStoreInfoSheet() async {
    HapticFeedback.lightImpact();
    final userProv = context.read<UserProvider?>();
    Map<String, dynamic> store = {};
    try {
      store = await StoresApiService().getMyStore();
    } catch (_) {}
    if (!mounted) return;

    final nameCtrl = TextEditingController(
      text: (store['name'] ?? userProv?.storeName ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (store['phone'] ?? '').toString(),
    );
    final addrCtrl = TextEditingController(
      text: (store['address'] ?? userProv?.storeAddress ?? '').toString(),
    );
    bool saving = false;
    String? sheetError;

    bool? updated;
    try {
      updated = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Thông tin cửa hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mã đại lý: ${store['code'] ?? 'STORE'} · Trạng thái: ${store['status'] ?? 'ACTIVE'}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (sheetError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(11),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        sheetError!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên cửa hàng',
                      prefixIcon: Icon(LucideIcons.store, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại liên hệ',
                      prefixIcon: Icon(LucideIcons.phone, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addrCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ cửa hàng',
                      prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AButton(
                    label: 'Lưu thông tin cửa hàng',
                    busy: saving,
                    onPressed: saving
                        ? null
                        : () async {
                            setSheet(() {
                              saving = true;
                              sheetError = null;
                            });
                            try {
                              final res = await StoresApiService().updateMyStore(
                                name: nameCtrl.text,
                                phone: phoneCtrl.text,
                                address: addrCtrl.text,
                              );
                              userProv?.updateStoreInfo(
                                name: res['name']?.toString() ?? nameCtrl.text,
                                address:
                                    res['address']?.toString() ?? addrCtrl.text,
                              );
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (e) {
                              if (ctx.mounted) {
                                setSheet(() {
                                  saving = false;
                                  sheetError = e is ApiException
                                      ? e.message
                                      : 'Không thể cập nhật thông tin cửa hàng.';
                                });
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      addrCtrl.dispose();
    }
    if (updated == true && mounted) {
      _showToast('Đã cập nhật thông tin cửa hàng thành công');
    }
  }

  Widget _buildStoreOverview(List<DeviceModel> devices) {
    final orders = context.watch<OrderProvider?>()?.orders ?? const [];
    final pendingCount = orders
        .where((o) => o.rawStatus.toUpperCase() == 'PENDING')
        .length;
    final activeCount = orders
        .where(
          (o) => [
            'CONFIRMED',
            'PROCESSING',
            'PREPARING',
            'READY_FOR_DELIVERY',
            'SHIPPING',
            'OUT_FOR_DELIVERY',
            'DELIVERING',
          ].contains(o.rawStatus.toUpperCase()),
        )
        .length;
    final completedCount = orders
        .where(
          (o) => ['COMPLETED', 'DELIVERED'].contains(o.rawStatus.toUpperCase()),
        )
        .length;
    final walletBalance =
        num.tryParse(_storeWallet?['balance']?.toString() ?? '') ?? 0;
    final frozenBalance =
        num.tryParse(_storeWallet?['frozenBalance']?.toString() ?? '') ?? 0;

    final storeScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final storeHeroHeight = (224.0 * (1.0 + (storeScale - 1.0) * 0.6)).clamp(224.0, 340.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store Operations Swipeable Hero Slide Deck
        StaggeredReveal(
          index: 0,
          child: HeroSlideDeck(
            height: storeHeroHeight,
            viewportFraction: 0.95,
            activeDotColor: const Color(0xFF047857),
            slides: [
              // Slide 1: Dispatch Command Center
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF064E3B),
                      Color(0xFF047857),
                      Color(0xFF0D9488),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF047857).withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulsingDot(color: Color(0xFF6EE7B7), size: 6),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Bảng điều phối đại lý • Trực tuyến',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userProvider?.storeName?.isNotEmpty == true
                          ? _userProvider!.storeName!
                          : 'Không gian quản lý cửa hàng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        pendingCount > 0
                            ? 'Đang có $pendingCount đơn hàng mới chờ xác nhận. Kiểm tra tồn kho và điều phối giao ngay!'
                            : 'Tiếp nhận đơn hàng một chạm từ khách hàng, quản lý tồn kho, nút IoT và ví doanh thu đại lý.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TactilePress(
                            scaleDown: 0.96,
                            borderRadius: BorderRadius.circular(13),
                            child: ElevatedButton.icon(
                              onPressed: () => MainLayout.switchToTab(context, 3),
                              icon: const Icon(LucideIcons.shoppingBag, size: 15),
                              label: Text(
                                pendingCount > 0
                                    ? 'Xử lý ($pendingCount)'
                                    : 'Đơn trực tiếp',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF047857),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TactilePress(
                            scaleDown: 0.96,
                            borderRadius: BorderRadius.circular(13),
                            child: OutlinedButton.icon(
                              onPressed: _openStoreWallet,
                              icon: const Icon(LucideIcons.wallet, size: 15),
                              label: const Text(
                                'Ví doanh thu',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.44),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Slide 2: Inventory & IoT Fleet Quick Access
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF115E59),
                      Color(0xFF0E7490),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0E7490).withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.cpu,
                            size: 13,
                            color: Color(0xFF99F6E4),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Kho hàng & Mạng nút IoT',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${devices.length} nút IoT đang gắn đại lý',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        'Theo dõi sản phẩm sắp hết hàng, trạng thái pin nút bấm khách hàng và cập nhật thông tin cửa hàng tức thì.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TactilePress(
                            scaleDown: 0.96,
                            borderRadius: BorderRadius.circular(13),
                            child: ElevatedButton.icon(
                              onPressed: () => MainLayout.switchToTab(context, 1),
                              icon: const Icon(LucideIcons.package, size: 15),
                              label: const Text(
                                'Kho sản phẩm',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F766E),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TactilePress(
                            scaleDown: 0.96,
                            borderRadius: BorderRadius.circular(13),
                            child: OutlinedButton.icon(
                              onPressed: () => MainLayout.switchToTab(context, 2),
                              icon: const Icon(LucideIcons.radio, size: 15),
                              label: const Text(
                                'Xem nút IoT',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.44),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Live Store Wallet Snapshot Card
        StaggeredReveal(
          index: 1,
          child: TactilePress(
            scaleDown: 0.985,
            haptic: true,
            borderRadius: BorderRadius.circular(18),
            onTap: _openStoreWallet,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD1FAE5)),
                boxShadow: AppMotion.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      LucideIcons.wallet,
                      size: 21,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số dư ví khả dụng',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatVnd(walletBalance),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF047857),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (frozenBalance > 0)
                          Text(
                            'Đang đối soát: ${_formatVnd(frozenBalance)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Rút tiền',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'Tổng quan vận hành đơn hàng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        StaggeredReveal(
          index: 2,
          child: Row(
            children: [
              _buildCountPill(
                icon: LucideIcons.clock,
                count: pendingCount,
                suffix: ' đơn',
                subtitle: 'Chờ duyệt',
                color: const Color(0xFFD97706),
              ),
              const SizedBox(width: 10),
              _buildCountPill(
                icon: LucideIcons.truck,
                count: activeCount,
                suffix: ' đơn',
                subtitle: 'Đang giao',
                color: const Color(0xFF0E6BA8),
              ),
              const SizedBox(width: 10),
              _buildCountPill(
                icon: LucideIcons.checkCircle2,
                count: completedCount,
                suffix: ' đơn',
                subtitle: 'Hoàn tất',
                color: const Color(0xFF059669),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StaggeredReveal(
          index: 3,
          child: Column(
            children: [
              _buildLandingStepCard(
                step: 'KHO',
                accent: const Color(0xFF047857),
                softBg: const Color(0xFFECFDF5),
                icon: LucideIcons.package,
                title: 'Sản phẩm & tồn kho đại lý',
                subtitle:
                    'Theo dõi giá bán, tồn kho khả dụng và cảnh báo sắp hết hàng đồng bộ với Web.',
                onTap: () => MainLayout.switchToTab(context, 1),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: 'IoT',
                accent: const Color(0xFF0E6BA8),
                softBg: const Color(0xFFE0F2FE),
                icon: LucideIcons.cpu,
                title: 'Nút bấm IoT của cửa hàng (${devices.length} thiết bị)',
                subtitle:
                    'Kiểm tra trạng thái online, pin và sản phẩm định tuyến trên từng nút bấm.',
                onTap: () => MainLayout.switchToTab(context, 2),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: 'ĐƠN',
                accent: const Color(0xFFD97706),
                softBg: const Color(0xFFFFFBEB),
                icon: LucideIcons.receiptText,
                title: 'Đơn hàng trực tiếp (${orders.length} đơn)',
                subtitle:
                    'Xác nhận đơn một chạm, cập nhật chuẩn bị hàng, xuất giao và xác nhận đã giao.',
                onTap: () => MainLayout.switchToTab(context, 3),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: 'VÍ',
                accent: const Color(0xFF0D9488),
                softBg: const Color(0xFFF0FDFA),
                icon: LucideIcons.landmark,
                title: 'Ví doanh thu & Rút tiền ngân hàng',
                subtitle:
                    'Xem lịch sử đối soát, liên kết ngân hàng và gửi lệnh rút tiền doanh thu.',
                onTap: _openStoreWallet,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemStaffOverview(List<DeviceModel> devices) {
    final totalDevices = _readIntStat(
      _fleetStats,
      ['total', 'totalDevices', 'totalButtons'],
      devices.length,
    );
    final onlineCount = _readIntStat(
      _fleetStats,
      ['online', 'active', 'activeDevices', 'onlineDevices'],
      devices.where((d) => d.isOnline).length,
    );
    final lowBatteryCount = _readIntStat(
      _fleetStats,
      ['lowBattery', 'lowBatteryDevices', 'lowBatteryCount'],
      devices.where((d) => d.battery <= 20).length,
    );
    final unassignedCount = _readIntStat(
      _fleetStats,
      ['unassigned', 'unassignedDevices', 'inWarehouse', 'available'],
      0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggeredReveal(
          index: 0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF155E75),
                  Color(0xFF0E7490),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0E7490).withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.wrench,
                        size: 13,
                        color: Color(0xFF67E8F9),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'System Staff • Trung tâm kỹ thuật IoT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFCFFAFE),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kho nút bấm, Bảo hành & Thu hồi',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nhập kho, cấp phát nút cho đại lý, triển khai mẫu hàng loạt, xử lý bảo hành 1-1 và kiểm tra nút khách trả.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TactilePress(
                        scaleDown: 0.96,
                        borderRadius: BorderRadius.circular(13),
                        child: ElevatedButton.icon(
                          onPressed: () => MainLayout.switchToTab(context, 1),
                          icon: const Icon(LucideIcons.cpu, size: 15),
                          label: const Text(
                            'Kho nút bấm',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0E7490),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TactilePress(
                        scaleDown: 0.96,
                        borderRadius: BorderRadius.circular(13),
                        child: OutlinedButton.icon(
                          onPressed: () => MainLayout.switchToTab(context, 2),
                          icon: const Icon(LucideIcons.shieldCheck, size: 15),
                          label: const Text(
                            'Bảo hành',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Tình trạng đội nút bấm toàn sàn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        StaggeredReveal(
          index: 1,
          child: Row(
            children: [
              _buildCountPill(
                icon: LucideIcons.cpu,
                count: totalDevices,
                suffix: ' nút',
                subtitle: unassignedCount > 0
                    ? '$unassignedCount trong kho'
                    : 'Tổng kho IoT',
                color: const Color(0xFF0E6BA8),
              ),
              const SizedBox(width: 10),
              _buildCountPill(
                icon: LucideIcons.wifi,
                count: onlineCount,
                suffix: ' online',
                subtitle: 'Đang hoạt động',
                color: const Color(0xFF059669),
              ),
              const SizedBox(width: 10),
              _buildCountPill(
                icon: LucideIcons.batteryLow,
                count: lowBatteryCount,
                suffix: ' pin yếu',
                subtitle: 'Cần kiểm tra',
                color: const Color(0xFFD97706),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StaggeredReveal(
          index: 2,
          child: Column(
            children: [
              _buildLandingStepCard(
                step: 'KHO',
                accent: const Color(0xFF0E7490),
                softBg: const Color(0xFFECFEFF),
                icon: LucideIcons.cpu,
                title: 'Kho nút & Vận hành thiết bị',
                subtitle:
                    'Đăng ký nút mới, sinh lô, nhập CSV, ghép nối, đổi WiFi, cấu hình hành vi & reset.',
                onTap: () => MainLayout.switchToTab(context, 1),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: 'MẪU',
                accent: const Color(0xFF0E6BA8),
                softBg: const Color(0xFFE0F2FE),
                icon: LucideIcons.layers,
                title: 'Cấp phát cửa hàng & Mẫu cấu hình',
                subtitle:
                    'Chuyển nút về custodyStoreId của cửa hàng và triển khai mẫu tối đa 100 nút/lần.',
                onTap: () => MainLayout.switchToTab(context, 1),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: 'BH',
                accent: const Color(0xFF0891B2),
                softBg: const Color(0xFFECFEFF),
                icon: LucideIcons.shieldCheck,
                title: 'Bảo hành kỹ thuật (Đổi 1-1 & Khóa nút)',
                subtitle:
                    'Xử lý phiếu bảo hành, đổi nút kế thừa hợp đồng thuê, khóa nút lỗi gửi Admin duyệt hoàn cọc.',
                onTap: () => MainLayout.switchToTab(context, 2),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: 'THU',
                accent: const Color(0xFFD97706),
                softBg: const Color(0xFFFFFBEB),
                icon: LucideIcons.rotateCcw,
                title: 'Thu hồi nút thuê & Xác nhận nhận lại',
                subtitle:
                    'Kiểm tra tình trạng vật lý nút khách trả và xác nhận nhập lại kho trung tâm.',
                onTap: () => MainLayout.switchToTab(context, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminOverview(List<DeviceModel> devices) {
    final orders = context.watch<OrderProvider?>()?.orders ?? const [];
    final totalDevices = _readIntStat(
      _fleetStats,
      ['total', 'totalDevices'],
      devices.length,
    );
    final activeDevices = _readIntStat(
      _fleetStats,
      ['activeDevices', 'online', 'active'],
      devices.where((d) => d.isOnline).length,
    );
    final completedOrders = orders
        .where(
          (o) => ['COMPLETED', 'DELIVERED'].contains(o.rawStatus.toUpperCase()),
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggeredReveal(
          index: 0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF312E81),
                  Color(0xFF4338CA),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4338CA).withValues(alpha: 0.24),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 13,
                        color: Color(0xFFA5B4FC),
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Admin Hub • Toàn hệ thống',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE0E7FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Trung tâm điều hành SmartOrder',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Giám sát toàn bộ cửa hàng đối tác, kho thiết bị nút bấm IoT, bảo hành và đơn hàng thời gian thực.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TactilePress(
                        scaleDown: 0.96,
                        borderRadius: BorderRadius.circular(13),
                        child: ElevatedButton.icon(
                          onPressed: () => MainLayout.switchToTab(context, 1),
                          icon: const Icon(LucideIcons.store, size: 15),
                          label: const Text(
                            'Cửa hàng',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF3730A3),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TactilePress(
                        scaleDown: 0.96,
                        borderRadius: BorderRadius.circular(13),
                        child: OutlinedButton.icon(
                          onPressed: () => MainLayout.switchToTab(context, 2),
                          icon: const Icon(LucideIcons.cpu, size: 15),
                          label: const Text(
                            'Kho nút IoT',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.42),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredReveal(
          index: 1,
          child: Row(
            children: [
              _buildCountPill(
                icon: LucideIcons.store,
                count: _adminStoreCount,
                suffix: ' CH',
                subtitle: 'Đối tác',
                color: const Color(0xFF4338CA),
              ),
              const SizedBox(width: 10),
              _buildCountPill(
                icon: LucideIcons.cpu,
                count: totalDevices,
                suffix: ' nút',
                subtitle: '$activeDevices đang bật',
                color: const Color(0xFF0E6BA8),
              ),
              const SizedBox(width: 10),
              _buildCountPill(
                icon: LucideIcons.checkCircle2,
                count: completedOrders,
                suffix: ' xong',
                subtitle: '${orders.length} đơn tải',
                color: const Color(0xFF059669),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StaggeredReveal(
          index: 2,
          child: Column(
            children: [
              _buildLandingStepCard(
                step: '01',
                accent: const Color(0xFF4338CA),
                softBg: const Color(0xFFEEF2FF),
                icon: LucideIcons.store,
                title: 'Giám sát cửa hàng đối tác ($_adminStoreCount đại lý)',
                subtitle:
                    'Tra cứu danh sách đại lý, trạng thái hoạt động, chiết khấu và liên hệ.',
                onTap: () => MainLayout.switchToTab(context, 1),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: '02',
                accent: const Color(0xFF0E6BA8),
                softBg: const Color(0xFFE0F2FE),
                icon: LucideIcons.cpu,
                title: 'Kho nút bấm toàn hệ thống ($totalDevices thiết bị)',
                subtitle:
                    'Quản lý kho trung tâm, cấp phát nút cho đại lý và triển khai mẫu hàng loạt.',
                onTap: () => MainLayout.switchToTab(context, 2),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: '03',
                accent: const Color(0xFFD97706),
                softBg: const Color(0xFFFFFBEB),
                icon: LucideIcons.receiptText,
                title: 'Giám sát đơn hàng toàn sàn (${orders.length} đơn)',
                subtitle:
                    'Theo dõi trạng thái xử lý, giao vận và lịch sử thanh toán trên toàn hệ thống.',
                onTap: () => MainLayout.switchToTab(context, 3),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: '04',
                accent: const Color(0xFF0E7490),
                softBg: const Color(0xFFECFEFF),
                icon: LucideIcons.shieldCheck,
                title: 'Bảo hành & Thu hồi thiết bị',
                subtitle:
                    'Giám sát phiếu bảo hành đổi 1-1 và tiếp nhận thiết bị hoàn trả.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SystemStaffWarrantyScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: '05',
                accent: const Color(0xFF7C3AED),
                softBg: const Color(0xFFF5F3FF),
                icon: LucideIcons.rotateCcw,
                title: 'Phiếu thu hồi & Hoàn cọc',
                subtitle:
                    'Kiểm tra danh sách nút khách hoàn trả và trạng thái chờ duyệt hoàn cọc.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SystemStaffReturnsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandingShowcase() {
    final activeOrders = context.watch<OrderProvider?>()?.activeOrders ?? const [];
    final latestActive = activeOrders.isNotEmpty ? activeOrders.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latestActive != null) ...[
          StaggeredReveal(
            index: 0,
            child: HomeActiveOrderBanner(
              statusText: OrderModel.lifecycleLabel(
                latestActive.rawStatus,
              ).toUpperCase(),
              productName: latestActive.displayTitle,
              progress: _progressForOrder(latestActive.rawStatus),
              onTap: () => MainLayout.switchToTab(context, 2),
              onCancel: () => MainLayout.switchToTab(context, 2),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 1. Interactive 3-Slide Hero Showcase Carousel
        StaggeredReveal(
          index: latestActive != null ? 1 : 0,
          child: HeroSlideDeck(
            height: (242.0 *
                    (1.0 +
                        (MediaQuery.textScalerOf(context)
                                    .scale(1.0)
                                    .clamp(1.0, 2.0) -
                                1.0) *
                            0.55))
                .clamp(242.0, 360.0),
            viewportFraction: 0.94,
            activeDotColor: const Color(0xFF0E6BA8),
            slides: [
              // Slide 1: 1-Touch Smart Order Hero
              _buildCustomerHeroSlide(
                gradient: const [Color(0xFF0F172A), Color(0xFF0E6BA8)],
                shadowColor: const Color(0xFF0E6BA8),
                badgeIcon: LucideIcons.sparkles,
                badgeIconColor: const Color(0xFF7DD3FC),
                badgeText: 'SmartOrder IoT • Đặt hàng 1 chạm',
                title: 'Hết nước, hết gas?\nBấm 1 chạm — Giao tận cửa!',
                subtitle:
                    'Kết nối nút bấm thông minh SmartOrder với đại lý quanh nhà. Chỉ 1 lần nhấn là giao trong 15–25 phút.',
                primaryIcon: LucideIcons.shoppingBag,
                primaryLabel: 'Mua sắm ngay',
                primaryColor: const Color(0xFF0E6BA8),
                onPrimary: _openShopStores,
                secondaryIcon: LucideIcons.bluetooth,
                secondaryLabel: 'Ghép nút BLE',
                onSecondary: () => ConnectDeviceSheet.showAndRefresh(context),
              ),
              // Slide 2: Rent Smart Button IoT
              _buildCustomerHeroSlide(
                gradient: const [Color(0xFF1E1B4B), Color(0xFF2563EB)],
                shadowColor: const Color(0xFF2563EB),
                badgeIcon: LucideIcons.cpu,
                badgeIconColor: const Color(0xFFA5B4FC),
                badgeText: 'Gói thuê nút IoT • Bảo hành 1-1',
                title: 'Thuê nút bấm thông minh\nLắp gọn trên tường nhà bạn',
                subtitle:
                    'Pin dùng nhiều tháng, đổi mới 1-1 khi có lỗi kỹ thuật và hoàn cọc minh bạch bất cứ lúc nào.',
                primaryIcon: LucideIcons.package,
                primaryLabel: 'Xem gói thuê',
                primaryColor: const Color(0xFF1D4ED8),
                onPrimary: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CustomerButtonsScreen(initialTab: 0, tour: widget.tour),
                  ),
                ),
                secondaryIcon: LucideIcons.smartphone,
                secondaryLabel: 'Nút của tôi',
                onSecondary: () => MainLayout.switchToTab(context, 1),
              ),
              // Slide 3: Super-fast Freeship 5km Delivery
              _buildCustomerHeroSlide(
                gradient: const [Color(0xFF064E3B), Color(0xFF0D9488)],
                shadowColor: const Color(0xFF059669),
                badgeIcon: LucideIcons.truck,
                badgeIconColor: const Color(0xFF6EE7B7),
                badgeText: 'Freeship 5km • Giao siêu tốc',
                title: 'Đại lý chính hãng gần nhà\nTheo dõi hành trình trực tiếp',
                subtitle:
                    'Cửa sổ 60s hủy đơn an toàn nếu bấm nhầm, cập nhật trạng thái đơn theo thời gian thực ngay trên app.',
                primaryIcon: LucideIcons.store,
                primaryLabel: 'Chọn đại lý',
                primaryColor: const Color(0xFF047857),
                onPrimary: _openShopStores,
                secondaryIcon: LucideIcons.receiptText,
                secondaryLabel: 'Theo dõi đơn',
                onSecondary: () => MainLayout.switchToTab(context, 2),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Trust / Value Highlights Strip
        StaggeredReveal(
          index: latestActive != null ? 2 : 1,
          child: Row(
            children: [
              _buildTrustPill(
                icon: LucideIcons.zap,
                title: '15–25 phút',
                subtitle: 'Giao siêu tốc',
                color: const Color(0xFF0E6BA8),
              ),
              const SizedBox(width: 10),
              _buildTrustPill(
                icon: LucideIcons.truck,
                title: 'Freeship 5km',
                subtitle: 'Đại lý gần nhà',
                color: const Color(0xFF059669),
              ),
              const SizedBox(width: 10),
              _buildTrustPill(
                icon: LucideIcons.shieldCheck,
                title: 'Bảo mật IoT',
                subtitle: 'HMAC-SHA256',
                color: const Color(0xFF4F46E5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // 3. Cách hoạt động (3 bước Landing)
        const Text(
          'Cách hoạt động siêu đơn giản',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Chỉ 3 bước để tự động hóa nhu yếu phẩm trong nhà',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        StaggeredReveal(
          index: latestActive != null ? 3 : 2,
          child: Column(
            children: [
              _buildLandingStepCard(
                step: '01',
                icon: LucideIcons.store,
                title: 'Chọn cửa hàng & sản phẩm quen dùng',
                subtitle:
                    'Nước uống 20L, bình gas, gạo ST25 từ đại lý chính hãng quanh khu vực.',
                onTap: _openShopStores,
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: '02',
                icon: LucideIcons.bluetoothConnected,
                title: 'Ghép nối nút bấm qua Bluetooth',
                subtitle:
                    'Bấm nhanh 5 lần vào nút vật lý, quét BLE và nạp Wi-Fi 2.4GHz trong 30 giây.',
                onTap: () => ConnectDeviceSheet.showAndRefresh(context),
              ),
              const SizedBox(height: 10),
              _buildLandingStepCard(
                step: '03',
                icon: LucideIcons.pointer,
                title: 'Bấm 1 chạm — Giao tận cửa',
                subtitle:
                    'Nhấn nhẹ nút bấm trên tường hoặc trong mục "Nút của tôi", đơn tạo tự động tức thì.',
                onTap: () => MainLayout.switchToTab(context, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerHeroSlide({
    required List<Color> gradient,
    required Color shadowColor,
    required IconData badgeIcon,
    required Color badgeIconColor,
    required String badgeText,
    required String title,
    required String subtitle,
    required IconData primaryIcon,
    required String primaryLabel,
    required Color primaryColor,
    required VoidCallback onPrimary,
    required IconData secondaryIcon,
    required String secondaryLabel,
    required VoidCallback onSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 13, color: badgeIconColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              height: 1.24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.42,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TactilePress(
                  scaleDown: 0.96,
                  borderRadius: BorderRadius.circular(14),
                  child: ElevatedButton.icon(
                    onPressed: onPrimary,
                    icon: Icon(primaryIcon, size: 15),
                    label: Text(
                      primaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TactilePress(
                  scaleDown: 0.96,
                  borderRadius: BorderRadius.circular(14),
                  child: OutlinedButton.icon(
                    onPressed: onSecondary,
                    icon: Icon(secondaryIcon, size: 15),
                    label: Text(
                      secondaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.42),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

  double _progressForOrder(String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      case 'PENDING':
        return 0.2;
      case 'CONFIRMED':
        return 0.4;
      case 'PREPARING':
      case 'PROCESSING':
        return 0.6;
      case 'READY_FOR_DELIVERY':
        return 0.75;
      case 'SHIPPING':
      case 'OUT_FOR_DELIVERY':
      case 'DELIVERING':
        return 0.9;
      default:
        return 0.5;
    }
  }

  Widget _buildCountPill({
    required IconData icon,
    required int count,
    required String suffix,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppMotion.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 8),
            AnimatedCountText(
              value: count,
              suffix: suffix,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustPill({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppMotion.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                fontFeatures: [FontFeature.tabularFigures()],
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandingStepCard({
    required String step,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color accent = const Color(0xFF0E6BA8),
    Color softBg = const Color(0xFFE0F2FE),
  }) {
    return TactilePress(
      scaleDown: 0.98,
      haptic: true,
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppMotion.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              LucideIcons.chevronRight,
              size: 17,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  late final List<DeviceModel> _fallbackDevices = List.from(
    DeviceModel.sampleDevices,
  );

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(_onHomeScroll);
    _userService.addListener(_onProfileChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      UserProvider? userProv;
      try {
        userProv = Provider.of<UserProvider>(context, listen: false);
        await userProv.loadProfile();
      } catch (_) {}
      if (!mounted) return;
      final isStaff = userProv?.isSystemStaff ?? false;
      final isAdmin = userProv?.isAdmin ?? false;
      final isStoreOwner = userProv?.isStoreOwner ?? false;
      final isCustomer = userProv?.isCustomer ?? true;

      if (isStaff || isAdmin) {
        _loadFleetStats();
      }
      if (isAdmin) {
        _loadAdminStoreCount();
      }
      if (isStoreOwner) {
        _loadStoreWallet();
      }
      if (!isStaff && !isAdmin) {
        try {
          Provider.of<DeviceProvider>(context, listen: false).loadDevices();
        } catch (_) {}
      }
      if (!isStaff) {
        try {
          final orderProv = Provider.of<OrderProvider>(context, listen: false);
          orderProv.loadOrders().then((_) {
            try {
              if (mounted) {
                Provider.of<NotificationProvider>(
                  context,
                  listen: false,
                ).syncOrders(orderProv.orders);
              }
            } catch (_) {}
          });
        } catch (_) {}
      }
      if (isCustomer) {
        try {
          Provider.of<AddressProvider>(context, listen: false).loadAddresses();
        } catch (_) {}
      }
      try {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).loadNotifications();
      } catch (_) {}
    });

    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 170),
    );
    _toastSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _toastController,
            curve: AppMotion.easeOut,
            reverseCurve: AppMotion.easeOut,
          ),
        );
    _toastFadeAnimation = CurvedAnimation(
      parent: _toastController,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeOut,
    );
    _toastScaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _toastController,
        curve: AppMotion.easeOut,
        reverseCurve: AppMotion.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _userService.removeListener(_onProfileChanged);
    _toastController.dispose();
    _homeScrollController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    final deviceProv = Provider.of<DeviceProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final userProv = Provider.of<UserProvider>(context, listen: false);
    try {
      if (userProv.isSystemStaff) {
        await _loadFleetStats();
      } else if (userProv.isAdmin) {
        await Future.wait([
          _loadFleetStats(),
          _loadAdminStoreCount(),
          orderProv.refreshOrders(),
        ]);
      } else if (userProv.isStoreOwner) {
        await Future.wait([
          deviceProv.refreshDevices(),
          orderProv.refreshOrders(),
          _loadStoreWallet(),
        ]);
      } else {
        await Future.wait([
          deviceProv.refreshDevices(),
          orderProv.refreshOrders(),
        ]);
      }
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (mounted) {
      _showToast('Đã làm mới dữ liệu thành công');
    }
  }

  void _showFloatingToast({
    required String message,
    VoidCallback? onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
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
        if (mounted) {
          setState(() {
            _toastMessage = null;
            _toastOnUndo = null;
          });
        }
      });
    }
  }

  void _showToast(String message) => _showFloatingToast(message: message);

  void _showAccountSheet() {
    final isFiveTab =
        (_userProvider?.isStoreOwner == true) ||
        (_userProvider?.isSystemStaff == true) ||
        (_userProvider?.isAdmin == true);
    MainLayout.switchToTab(context, isFiveTab ? 4 : 3);
  }

  void _showLocationPicker() {
    AddressPickerSheet.show(
      context,
      onAddressSelected: (addr) => _showToast('Đã chuyển sang: $addr'),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AddressProvider?>();
    List<DeviceModel> displayDevices = _fallbackDevices;
    try {
      final provider = Provider.of<DeviceProvider>(context);
      displayDevices = provider.devices;
    } catch (_) {}

    NotificationProvider? notifProvider;
    try {
      notifProvider = Provider.of<NotificationProvider>(context);
    } catch (_) {}

    final isAdmin = _userProvider?.isAdmin ?? false;
    final isSystemStaff = _userProvider?.isSystemStaff ?? false;
    final isStoreOwner = _userProvider?.isStoreOwner ?? false;
    final role = _userProvider?.role ?? 'CUSTOMER';

    final pendingStoreOrders = isStoreOwner
        ? (context.watch<OrderProvider?>()?.orders
                  .where((o) => o.rawStatus.toUpperCase() == 'PENDING')
                  .length ??
              0)
        : 0;

    final compactTitle = isAdmin
        ? 'SmartOrder • Admin'
        : isSystemStaff
        ? 'SmartOrder • Kỹ thuật'
        : isStoreOwner
        ? 'SmartOrder • Đại lý'
        : 'SmartOrder';

    final compactColor = isAdmin
        ? const Color(0xFF4338CA)
        : isSystemStaff
        ? const Color(0xFF0E7490)
        : isStoreOwner
        ? const Color(0xFF047857)
        : const Color(0xFF0E6BA8);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: AContent(
        maxWidth: SampleA.listWidth,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _handleRefresh,
              color: compactColor,
              child: SingleChildScrollView(
                controller: _homeScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeHeaderCard(
                      userAvatar: _userAvatar,
                      userAvatarUrl: _userAvatarUrl,
                      userInitials: _userInitials,
                      userShortName: _userShortName,
                      userAddress: _userAddress,
                      deviceCount: (isSystemStaff || isAdmin)
                          ? _readIntStat(
                              _fleetStats,
                              ['total', 'totalDevices', 'totalButtons'],
                              displayDevices.length,
                            )
                          : displayDevices.length,
                      role: role,
                      storeName: _userProvider?.storeName,
                      storeAddress: _userProvider?.storeAddress,
                      unreadNotificationCount: notifProvider?.unreadCount ?? 0,
                      onAccountTap: _showAccountSheet,
                      onNotificationTap: () => NotificationSheet.show(context),
                      onLocationTap: () {
                        if (isStoreOwner) {
                          _openStoreInfoSheet();
                        } else if (isAdmin || isSystemStaff) {
                          MainLayout.switchToTab(context, 1);
                        } else {
                          _showLocationPicker();
                        }
                      },
                    ),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HomeGrabServicesGrid(
                              role: role,
                              pendingOrderCount: pendingStoreOrders,
                              onScrollToStores: _openShopStores,
                            ),
                            const SizedBox(height: 18),
                            KeyedSubtree(
                              key: ValueKey<String>(role),
                              child: isAdmin
                                  ? _buildAdminOverview(displayDevices)
                                  : isSystemStaff
                                  ? _buildSystemStaffOverview(displayDevices)
                                  : isStoreOwner
                                  ? _buildStoreOverview(displayDevices)
                                  : _buildLandingShowcase(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Frosted Glass Sticky Compact Header on scroll
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_showCompactHeader,
                child: AnimatedSlide(
                  offset: _showCompactHeader
                      ? Offset.zero
                      : const Offset(0, -1),
                  duration: AppMotion.uiDuration,
                  curve: AppMotion.easeOut,
                  child: AnimatedOpacity(
                    opacity: _showCompactHeader ? 1.0 : 0.0,
                    duration: AppMotion.fastDuration,
                    curve: AppMotion.easeOut,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.92),
                          child: SafeArea(
                            bottom: false,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      compactTitle,
                                      style: TextStyle(
                                        color: compactColor,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Thông báo',
                                    onPressed: () =>
                                        NotificationSheet.show(context),
                                    icon: Badge(
                                      isLabelVisible:
                                          (notifProvider?.unreadCount ?? 0) > 0,
                                      backgroundColor: const Color(0xFFEF4444),
                                      child: const Icon(
                                        Icons.notifications_none_rounded,
                                        size: 24,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                onDismiss: _dismissToast,
              ),
          ],
        ),
      ),
    );
  }
}
