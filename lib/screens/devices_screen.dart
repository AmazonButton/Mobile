import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/device_model.dart';
import '../providers/address_provider.dart';
import '../providers/device_provider.dart';
import '../providers/order_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';
import '../widgets/app_motion.dart';
import '../widgets/sample_a.dart';
import '../widgets/devices/device_card.dart';
import '../widgets/devices/smart_button_card.dart';
import '../widgets/modals/product_selection_sheet.dart';
import '../widgets/modals/connect_device_sheet.dart';
import 'device_detail_screen.dart';
import 'customer_buttons_screen.dart';
import '../widgets/smart_order_tour.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, this.tour});
  final SmartOrderTour? tour;
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _connectOpen = false;
  final Map<String, String> _buttonStateMap = {};
  final Map<String, Timer> _orderResetTimers = {};

  @override
  void dispose() {
    for (final t in _orderResetTimers.values) {
      t.cancel();
    }
    _orderResetTimers.clear();
    super.dispose();
  }

  Future<void> _handleOneTouchOrder(DeviceModel device) async {
    if (_buttonStateMap[device.id] == 'ordering') return;
    HapticFeedback.lightImpact();
    setState(() => _buttonStateMap[device.id] = 'ordering');
    try {
      final orderProvider = context.read<OrderProvider>();
      final userName = context.read<UserProvider?>()?.name ?? 'Khách hàng';
      final address =
          context.read<AddressProvider?>()?.currentAddressDisplay ?? '';
      await orderProvider.createOneTouchOrder(
        deviceId: device.id,
        buttonName: device.name,
        productName: device.product,
        productPrice: device.price,
        customerName: userName,
        apartment: address,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _buttonStateMap[device.id] = 'ordered');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF059669),
          content: Text('⚡ Đã đặt 1 chạm: ${device.product} (${device.name})!'),
        ),
      );
      _orderResetTimers[device.id]?.cancel();
      _orderResetTimers[device.id] = Timer(const Duration(milliseconds: 2800), () {
        _orderResetTimers.remove(device.id);
        if (mounted) setState(() => _buttonStateMap[device.id] = 'idle');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _buttonStateMap[device.id] = 'idle');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          content: Text(
            e is ApiException ? e.message : 'Không thể đặt hàng. Vui lòng thử lại.',
          ),
        ),
      );
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DeviceProvider?>()?.loadDevices();
    });
  }

  Future<void> _confirmDelete(DeviceModel d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa nút này?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text('Bạn có chắc chắn muốn xóa "${d.name}" khỏi danh sách thiết bị của mình không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Xóa nút'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<DeviceProvider>().removeDevice(d.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF0F172A),
            content: Text('Đã xóa nút bấm thành công'),
          ),
        );
      }
    }
  }

  void _detail(DeviceModel d) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DeviceDetailScreen(
        deviceId: d.id,
        deviceName: d.name,
        room: d.room,
        productName: d.product,
        productPrice: d.price,
        battery: d.battery,
        wifiSsid: d.wifiSsid,
        productImageUrl: d.imageUrl,
      ),
    ),
  );
  Future<void> _connect() async {
    if (_connectOpen) return;
    _connectOpen = true;
    final tour = widget.tour;
    tour?.openConnect();
    try {
      final result = await ConnectDeviceSheet.showAndRefresh(
        context,
        tour: tour,
      );
      tour?.connectClosed(result == true);
    } finally {
      _connectOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider?>();
    final userProv = context.watch<UserProvider?>();
    final isAdmin = userProv?.isAdmin ?? false;
    final isStoreOwner = userProv?.isStoreOwner ?? false;
    final isCustomer = !isAdmin && !isStoreOwner;
    final devices = provider?.devices ?? DeviceModel.sampleDevices;
    final loading = provider?.isLoading ?? false;
    return Scaffold(
      backgroundColor: SampleA.background,
      body: AContent(
        maxWidth: SampleA.listWidth,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await provider?.refreshDevices();
            },
            color: SampleA.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  isAdmin
                      ? 'Kho nút bấm hệ thống'
                      : isStoreOwner
                          ? 'Nút bấm đại lý'
                          : 'Nút của tôi',
                  style: SampleA.title,
                ),
                const SizedBox(height: 6),
                Text(
                  isAdmin
                      ? 'Giám sát toàn bộ thiết bị nút bấm IoT trên toàn nền tảng'
                      : isStoreOwner
                          ? 'Theo dõi nút bấm IoT gắn với sản phẩm tại ${userProv?.storeName?.isNotEmpty == true ? userProv!.storeName! : "cửa hàng"}'
                          : 'Đặt hàng 1 chạm và quản lý các nút trong nhà',
                  style: SampleA.body,
                ),
                if (!isCustomer && devices.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statBox(
                        '${devices.length}',
                        isAdmin ? 'Tổng thiết bị' : 'Nút tại đại lý',
                        const Color(0xFF0E6BA8),
                      ),
                      const SizedBox(width: 10),
                      _statBox(
                        '${devices.where((d) => d.isOnline).length}',
                        'Trực tuyến',
                        const Color(0xFF059669),
                      ),
                      const SizedBox(width: 10),
                      _statBox(
                        '${devices.where((d) => d.battery <= 20).length}',
                        'Pin yếu',
                        const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: AButton(
                        key: widget.tour?.key(TourStep.add),
                        label: isAdmin
                            ? 'Quét kiểm tra nút BLE'
                            : isStoreOwner
                                ? 'Kiểm tra nút BLE'
                                : 'Kết nối nút',
                        icon: isCustomer ? LucideIcons.plus : LucideIcons.bluetooth,
                        onPressed: _connect,
                      ),
                    ),
                    if (isCustomer) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(LucideIcons.cpu, size: 18),
                          label: const Text('Thuê gói nút'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SampleA.primary,
                            side: const BorderSide(color: SampleA.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerButtonsScreen(initialTab: 0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                if (loading && devices.isEmpty)
                  AppMotion.allowAmbient(context)
                      ? Shimmer.fromColors(
                          baseColor: const Color(0xFFF1F5F9),
                          highlightColor: const Color(0xFFFFFFFF),
                          child: Column(
                            children: List.generate(
                              3,
                              (index) => Container(
                                height: 100,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: List.generate(
                            3,
                            (index) => Container(
                              height: 100,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        )
                else if (devices.isEmpty && provider?.errorMessage != null)
                  ACard(
                    child: Column(
                      children: [
                        const Text(
                          'Không thể tải thiết bị',
                          style: SampleA.section,
                        ),
                        const SizedBox(height: 16),
                        AButton(
                          label: 'Thử lại',
                          onPressed: provider?.loadDevices,
                        ),
                      ],
                    ),
                  )
                else if (devices.isEmpty) ...[
                  const SizedBox(height: 32),
                  const Center(child: ABuddy(size: 166)),
                  const SizedBox(height: 28),
                  Text(
                    isStoreOwner
                        ? 'Chưa có nút bấm IoT nào tại đại lý'
                        : isAdmin
                            ? 'Kho nút bấm đang trống'
                            : 'Chào người bạn mới!',
                    style: SampleA.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isStoreOwner
                        ? 'Khi nhân viên kỹ thuật cấp phát hoặc khách hàng gán sản phẩm của đại lý vào nút bấm, danh sách sẽ hiển thị tại đây.'
                        : isAdmin
                            ? 'Chưa có thiết bị nào được đăng ký trên nền tảng.'
                            : 'Thêm nút bấm đầu tiên.',
                    style: SampleA.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  if (isCustomer) ...[
                    const Text(
                      'Đặt nhanh 1 chạm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final singleColumn =
                            constraints.maxWidth < 300 ||
                            MediaQuery.textScalerOf(context).scale(14) > 21;
                        final cardWidth = singleColumn
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: devices
                              .map(
                                (device) => SizedBox(
                                  width: cardWidth,
                                  child: SmartButtonCard(
                                    id: device.id,
                                    name: device.name,
                                    room: device.room,
                                    product: device.product,
                                    price: device.price,
                                    battery: device.battery,
                                    imageUrl: device.imageUrl,
                                    storeName: device.storeName,
                                    badgeText: device.badgeText,
                                    state: _buttonStateMap[device.id] ?? 'idle',
                                    onOrder: () => _handleOneTouchOrder(device),
                                    onSettings: () => _detail(device),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Chi tiết & cấu hình nút',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (int idx = 0; idx < devices.length; idx++)
                    StaggeredReveal(
                      index: idx < 5 ? idx : 4,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DeviceCard(
                          id: devices[idx].id,
                          name: devices[idx].name,
                          room: devices[idx].room,
                          storeName: devices[idx].storeName,
                          product: devices[idx].product,
                          price: devices[idx].price,
                          batteryLevel: devices[idx].battery,
                          imageUrl: devices[idx].imageUrl,
                          badgeText: devices[idx].badgeText,
                          signal: devices[idx].signal,
                          isOnline: devices[idx].isOnline,
                          onTap: () => _detail(devices[idx]),
                          onSettings: () => _detail(devices[idx]),
                          onDelete: isCustomer
                              ? () => _confirmDelete(devices[idx])
                              : null,
                          onSelectProduct: isCustomer
                              ? () => ProductSelectionSheet.show(
                                    context: context,
                                    buttonName: devices[idx].name,
                                    currentProductName: devices[idx].product,
                                    deviceId: devices[idx].id,
                                    onSave: (product, quantity) => context
                                        .read<DeviceProvider>()
                                        .updateDeviceProduct(
                                          devices[idx].id,
                                          product,
                                          quantity: quantity,
                                        ),
                                  )
                              : null,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
