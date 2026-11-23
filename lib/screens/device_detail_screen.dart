import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/device_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/devices/device_order_sheet.dart';
import '../widgets/modals/product_selection_sheet.dart';
import '../widgets/modals/rename_device_dialog.dart';
import '../widgets/modals/wifi_provisioning_sheet.dart';
import 'store_selection_screen.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String? deviceId;
  final String deviceName;
  final String room;
  final String productName;
  final String productPrice;
  final String? productImageUrl;
  final int battery;
  final String wifiSsid;

  const DeviceDetailScreen({
    super.key,
    this.deviceId,
    this.deviceName = 'Nút Bếp',
    this.room = 'Khu vực Bếp',
    this.productName = 'Nước Lavie 20L',
    this.productPrice = '65.000đ',
    this.productImageUrl,
    this.battery = 85,
    this.wifiSsid = '',
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

enum _DevicePage { overview, connection }

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late String _deviceName;
  late String _productName;
  late String _productPrice;
  late int _battery;
  late String _wifiSsid;
  _DevicePage _page = _DevicePage.overview;
  bool _wifiChanged = false;

  @override
  void initState() {
    super.initState();
    _deviceName = widget.deviceName;
    _productName = widget.productName;
    _productPrice = widget.productPrice;
    _battery = widget.battery;
    _wifiSsid = widget.wifiSsid;
  }

  String _formatPrice(String price) {
    final clean = price.replaceAll(RegExp(r'[^0-9]'), '');
    final numVal = int.tryParse(clean);
    if (numVal != null && numVal > 0) {
      final s = numVal.toString();
      final buffer = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
        buffer.write(s[i]);
      }
      return '${buffer.toString()} ₫';
    }
    return price.isNotEmpty ? price : '0 ₫';
  }

  Future<void> _handleRename() async {
    final id = widget.deviceId;
    if (id == null || id.isEmpty) {
      _showToast('Không tìm thấy thiết bị');
      return;
    }
    final provider = context.read<DeviceProvider>();
    final current = provider.getDeviceById(id);
    if (current == null) {
      _showToast('Không tìm thấy thiết bị');
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RenameDeviceDialog(
        initialName: current.name,
        onSave: (name) => provider.renameDevice(id, name),
      ),
    );
    if (!mounted || saved != true) return;
    setState(
      () => _deviceName = provider.getDeviceById(id)?.name ?? _deviceName,
    );
    _showToast('Đã đổi tên nút');
  }

  void _handleChangeProduct() {
    HapticFeedback.lightImpact();
    ProductSelectionSheet.show(
      context: context,
      buttonName: _deviceName,
      currentProductName: _productName,
      deviceId: widget.deviceId,
      onSave: (selectedProduct, quantity) async {
        final deviceId = widget.deviceId;
        if (deviceId == null || deviceId.isEmpty) {
          throw StateError('Không tìm thấy thiết bị');
        }
        await context.read<DeviceProvider>().updateDeviceProduct(
          deviceId,
          selectedProduct,
          quantity: quantity,
        );
        if (!mounted) return;
        setState(() {
          _productName = selectedProduct.shortName;
          _productPrice = selectedProduct.priceFormatted;
        });

        _showToast('Đã gán $_productName vào $_deviceName');
      },
    );
  }

  Future<void> _handleChangeStore() async {
    final deviceId = widget.deviceId;
    if (deviceId == null || deviceId.isEmpty) {
      _showToast('Không tìm thấy thiết bị');
      return;
    }
    final provider = context.read<DeviceProvider>();
    final saved = await StoreSelectionScreen.show(
      context: context,
      deviceId: deviceId,
      onSave: (storeId) => provider.updateDeviceStore(deviceId, storeId),
    );
    if (!mounted || saved != true) return;
    final device = provider.getDeviceById(deviceId);
    if (device != null) {
      setState(() {
        _productName = device.product;
        _productPrice = device.price;
      });
    }
    _showToast('Đã đổi cửa hàng. Hãy chọn sản phẩm của cửa hàng mới.');
  }

  void _handleResetWifi() {
    HapticFeedback.lightImpact();
    WifiProvisioningSheet.show(
      context: context,
      initialSsid: _wifiSsid,
      onConnected: (newSsid) {
        if (!mounted) return;
        setState(() {
          _wifiChanged = true;
          _wifiSsid = newSsid;
        });
        _showToast('Đã cấu hình Wi-Fi thành công: $newSsid');
      },
    );
  }

  Future<void> _handleDeleteDevice() async {
    final id = widget.deviceId;
    if (id == null || id.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa nút này?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text('Bạn có chắc chắn muốn xóa "$_deviceName" khỏi tài khoản không?'),
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
      await context.read<DeviceProvider>().removeDevice(id);
      if (mounted) {
        Navigator.of(context).pop();
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

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPage(_DevicePage page) {
    FocusScope.of(context).unfocus();
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final device = context.select<DeviceProvider, dynamic>(
      (p) => widget.deviceId != null ? p.getDeviceById(widget.deviceId!) : null,
    );
    final userProv = context.watch<UserProvider?>();
    final isCustomer = userProv?.isCustomer ?? true;
    final userAddress = userProv?.address;
    final deliveryAddress = (userAddress != null && userAddress.trim().isNotEmpty)
        ? userAddress.trim()
        : 'Địa chỉ nhận hàng mặc định của bạn';

    final name = device?.name ?? _deviceName;
    final product = device?.product ?? _productName;
    final price = _formatPrice(device?.price ?? _productPrice);
    final battery = device?.battery ?? _battery;
    final store = device?.storeName ?? 'Đại lý Nước & Gas Gia Định';
    final wifi = (_wifiChanged ? _wifiSsid : device?.wifiSsid ?? _wifiSsid).trim();
    final hasWifi = wifi.isNotEmpty;
    final offline = device?.isOffline ?? false;

    return PopScope(
      canPop: _page == _DevicePage.overview,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showPage(_DevicePage.overview);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 64,
          leadingWidth: 68,
          leading: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Center(
              child: InkWell(
                onTap: () {
                  if (_page == _DevicePage.overview) {
                    Navigator.of(context).maybePop();
                  } else {
                    _showPage(_DevicePage.overview);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(LucideIcons.chevronLeft, size: 20, color: Color(0xFF0F172A)),
                ),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _page == _DevicePage.overview ? name : 'Cấu hình Wi-Fi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (_page == _DevicePage.overview) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: offline ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      offline ? 'Chưa kết nối Wi-Fi' : 'Sẵn sàng 1 chạm',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: offline ? const Color(0xFF64748B) : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            if (isCustomer && _page == _DevicePage.overview)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: InkWell(
                    key: const ValueKey('renameDevice'),
                    onTap: _handleRename,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Icon(LucideIcons.pencil, size: 16, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFF1F5F9), height: 1),
          ),
        ),

        // ── STICKY FLOATING ORDER BAR (CHỈ DÀNH CHO KHÁCH HÀNG) ──
        bottomNavigationBar: isCustomer && _page == _DevicePage.overview
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            // Khối hiển thị Tổng tiền & Freeship
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Tổng cộng',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Freeship',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    price,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2563EB),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '1 sản phẩm • Giao ngay ⚡',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Nút Grab Primary Action
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                showDeviceOrderSheet(context, device);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.zap, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Đặt 1 chạm',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,

        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: switch (_page) {
                    _DevicePage.overview => [
                      if (!isCustomer) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                LucideIcons.eye,
                                color: Color(0xFF047857),
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Chế độ giám sát thiết bị — chỉ xem trạng thái nút, pin và sản phẩm đang gán.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (isCustomer) ...[
                      // ── 1. GRAB DELIVERY STRIP (Thanh địa chỉ giao hàng) ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                LucideIcons.mapPin,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Giao đến',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '⚡ 15-30 phút',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    deliveryAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── 2. GRAB QUICK SERVICE SHORTCUTS (4 Icon Tròn Phong Cách Grab) ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _GrabServiceIcon(
                              icon: LucideIcons.zap,
                              label: 'Đặt ngay',
                              iconColor: const Color(0xFF2563EB),
                              bgColor: const Color(0xFFEFF6FF),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                showDeviceOrderSheet(context, device);
                              },
                            ),
                            _GrabServiceIcon(
                              icon: LucideIcons.shoppingBag,
                              label: 'Đổi món',
                              iconColor: const Color(0xFFEA580C),
                              bgColor: const Color(0xFFFFF7ED),
                              onTap: _handleChangeProduct,
                            ),
                            _GrabServiceIcon(
                              icon: LucideIcons.store,
                              label: 'Cửa hàng',
                              iconColor: const Color(0xFF7C3AED),
                              bgColor: const Color(0xFFF5F3FF),
                              onTap: _handleChangeStore,
                            ),
                            _GrabServiceIcon(
                              icon: LucideIcons.wifi,
                              label: 'Cài Wi-Fi',
                              iconColor: const Color(0xFF059669),
                              bgColor: const Color(0xFFECFDF5),
                              onTap: () => _showPage(_DevicePage.connection),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      ],

                      // ── 3. THẺ SẢN PHẨM CHUẨN GRAB MART / GRAB FOOD ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sản phẩm gắn với nút',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFDBEAFE)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.sparkles, size: 12, color: Color(0xFF2563EB)),
                                      SizedBox(width: 4),
                                      Text(
                                        '1-CHẠM',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail sản phẩm phong cách Grab
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      LucideIcons.packageCheck,
                                      color: Color(0xFF2563EB),
                                      size: 34,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Thông tin chi tiết món
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.store, size: 12, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              store,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            LucideIcons.badgeCheck,
                                            size: 13,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            price,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF2563EB),
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Giá chuẩn',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF64748B),
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

                            const SizedBox(height: 14),

                            // Dải ưu đãi Grab Style
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(LucideIcons.checkCircle2, size: 15, color: Color(0xFF16A34A)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Miễn phí giao hàng cho tất cả đơn bấm nút 1-chạm',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── 4. THẺ THÔNG SỐ THIẾT BỊ PIN & WI-FI CÂN BẰNG ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              // Pin
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        LucideIcons.batteryMedium,
                                        color: Color(0xFF16A34A),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$battery%',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          const Text(
                                            'Pin rất tốt',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const VerticalDivider(width: 20, thickness: 1, color: Color(0xFFF1F5F9)),

                              // Wi-Fi
                              Expanded(
                                child: InkWell(
                                  onTap: isCustomer
                                      ? () => _showPage(_DevicePage.connection)
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: hasWifi ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          hasWifi ? LucideIcons.wifi : LucideIcons.wifiOff,
                                          color: hasWifi ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                          size: 19,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              hasWifi ? wifi : 'Chưa có Wi-Fi',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: hasWifi ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              isCustomer
                                                  ? (hasWifi ? 'Chạm để đổi' : 'Cài Wi-Fi ngay')
                                                  : (hasWifi ? 'Đã cấu hình' : 'Chưa cấu hình'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isCustomer
                                                    ? const Color(0xFF2563EB)
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── 5. GRAB TRUST & SAFETY BANNER (Cam kết chất lượng Zero-Touch) ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.shieldCheck, size: 18, color: Color(0xFF0284C7)),
                                SizedBox(width: 8),
                                Text(
                                  'Cam kết dịch vụ Zero-Touch',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildCommitItem('Tự động tạo đơn ngay khi bạn nhấn nút vật lý'),
                            _buildCommitItem('Cửa sổ 60s hủy an toàn trên ứng dụng nếu bấm nhầm'),
                            _buildCommitItem('Đối tác giao hàng chính hãng, đổi trả tận cửa'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (isCustomer) ...[
                      // ── 6. CÀI ĐẶT THIẾT BỊ (Settings Card) ──
                      const Text(
                        'Cài đặt & Tùy chỉnh',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: LucideIcons.store,
                              iconColor: const Color(0xFF2563EB),
                              iconBg: const Color(0xFFEFF6FF),
                              title: 'Đổi cửa hàng cung cấp',
                              subtitle: store,
                              onTap: _handleChangeStore,
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _SettingsTile(
                              icon: LucideIcons.wifi,
                              iconColor: const Color(0xFF059669),
                              iconBg: const Color(0xFFECFDF5),
                              title: 'Cài đặt mạng Wi-Fi cho nút',
                              subtitle: hasWifi ? wifi : 'Chưa thiết lập Wi-Fi',
                              onTap: () => _showPage(_DevicePage.connection),
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _SettingsTile(
                              icon: LucideIcons.pencil,
                              iconColor: const Color(0xFF7C3AED),
                              iconBg: const Color(0xFFF5F3FF),
                              title: 'Đổi tên nút bấm',
                              subtitle: name,
                              onTap: _handleRename,
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _SettingsTile(
                              icon: LucideIcons.trash2,
                              iconColor: const Color(0xFFEF4444),
                              iconBg: const Color(0xFFFEF2F2),
                              title: 'Xóa nút khỏi tài khoản',
                              subtitle: 'Hủy liên kết nút bấm này',
                              onTap: _handleDeleteDevice,
                            ),
                          ],
                        ),
                      ),
                      ],
                      const SizedBox(height: 24),
                    ],

                    _DevicePage.connection => [
                      // TRANG CẤU HÌNH WI-FI CHO THIẾT BỊ
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(LucideIcons.wifi, color: Color(0xFF2563EB), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hasWifi ? wifi : 'Chưa kết nối Wi-Fi',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hasWifi ? 'Thiết bị đang sử dụng mạng này' : 'Bấm nút dưới để nạp Wi-Fi vào nút',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                _wifiSsid = wifi;
                                _handleResetWifi();
                              },
                              icon: const Icon(LucideIcons.refreshCw, size: 16),
                              label: const Text('Cấu hình mạng Wi-Fi mới'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => _showPage(_DevicePage.overview),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        child: const Text('Quay lại chi tiết nút', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF0369A1), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrabServiceIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _GrabServiceIcon({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
