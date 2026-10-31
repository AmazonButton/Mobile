import '../widgets/devices/a_stock_status.dart';
import '../widgets/devices/device_order_sheet.dart';
import '../widgets/sample_a.dart';
import '../services/stock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../widgets/modals/product_selection_sheet.dart';
import '../widgets/modals/store_selection_sheet.dart';
import '../widgets/modals/wifi_provisioning_sheet.dart';
import '../widgets/modals/rename_device_dialog.dart';

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
    this.wifiSsid = 'Home_Network_5G',
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

enum _DevicePage { overview, order, connection }

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late String _deviceName;
  late String _room;
  late String _productName;
  late String _productPrice;
  late String _productImageUrl;
  late int _battery;
  late String _wifiSsid;
  _DevicePage _page = _DevicePage.overview;
  bool _wifiChanged = false;

  @override
  void initState() {
    super.initState();
    _deviceName = widget.deviceName;
    _room = widget.room;
    _productName = widget.productName;
    _productPrice = widget.productPrice;
    _productImageUrl = widget.productImageUrl ?? '';
    _battery = widget.battery;
    _wifiSsid = widget.wifiSsid;
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

          _productImageUrl = '';
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
    final saved = await StoreSelectionSheet.show(
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
        _productImageUrl = device.imageUrl ?? '';
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
        _showToast('Đã kết nối Wi-Fi thành công: $newSsid');
      },
    );
  }

  void _handleDeleteDevice() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: const Text(
          'Xóa thiết bị',
          style: TextStyle(
            fontFamily: 'SampleA Vietnam',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "$_deviceName"? Thao tác này sẽ gỡ thiết bị khỏi tài khoản.',
          style: const TextStyle(
            fontFamily: 'SampleA Vietnam',
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'SampleA Vietnam',
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast(
                'Chức năng xóa thiết bị hiện chưa khả dụng. Vui lòng liên hệ cửa hàng.',
              );
            },
            child: Text(
              'Xóa',
              style: TextStyle(
                fontFamily: 'SampleA Vietnam',
                color: Colors.red.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 2),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'SampleA Vietnam',
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showPage(_DevicePage page) {
    FocusScope.of(context).unfocus();
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceProvider?>()?.getDeviceById(
      widget.deviceId ?? '',
    );
    final name = device?.name ?? _deviceName;
    final room = device?.room ?? _room;
    final product = device?.product ?? _productName;
    final price = device?.price ?? _productPrice;
    final battery = device?.battery ?? _battery;
    final store = device?.storeName ?? 'Chưa chọn cửa hàng';
    final wifi = _wifiChanged ? _wifiSsid : device?.wifiSsid ?? _wifiSsid;
    final offline = device?.isOffline ?? false;
    final title = switch (_page) {
      _DevicePage.overview => name,
      _DevicePage.order => 'Thiết lập đặt hàng',
      _DevicePage.connection => 'Kết nối & thiết bị',
    };
    return PopScope(
      canPop: _page == _DevicePage.overview,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showPage(_DevicePage.overview);
      },
      child: Scaffold(
        backgroundColor: SampleA.background,
        appBar: AppBar(
          backgroundColor: SampleA.background,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: false,
          toolbarHeight: 64,
          leadingWidth: 72,
          leading: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: AIconButton(
              tooltip: 'Quay lại',
              icon: LucideIcons.chevronLeft,
              onPressed: () {
                if (_page == _DevicePage.overview) {
                  Navigator.of(context).maybePop();
                } else {
                  _showPage(_DevicePage.overview);
                }
              },
            ),
          ),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SampleA.section,
          ),
          actions: [
            if (_page == _DevicePage.overview)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AIconButton(
                  key: const ValueKey('renameDevice'),
                  tooltip: 'Đổi tên',
                  icon: LucideIcons.pencil,
                  onPressed: _handleRename,
                ),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                key: ValueKey(_page),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: switch (_page) {
                    _DevicePage.overview => [
                      ACard(
                        color: SampleA.pale,
                        border: false,
                        child: Row(
                          children: [
                            AProductImage(
                              product: product,
                              imageUrl: device?.imageUrl ?? _productImageUrl,
                              size: 64,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room,
                                    style: SampleA.body.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  AStatus(
                                    label: offline
                                        ? 'Mất kết nối'
                                        : 'Đang kết nối',
                                    icon: offline
                                        ? LucideIcons.wifiOff
                                        : LucideIcons.check,
                                    color: offline
                                        ? SampleA.danger
                                        : SampleA.primary,
                                    background: offline
                                        ? SampleA.dangerLight
                                        : Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stats = [
                            _stat(
                              LucideIcons.battery,
                              '$battery%',
                              'Pin thiết bị',
                            ),
                            _stat(
                              LucideIcons.wifi,
                              offline ? 'Ngoại tuyến' : 'Đã kết nối',
                              wifi,
                            ),
                          ];
                          return constraints.maxWidth < 300 ||
                                  MediaQuery.textScalerOf(context).scale(16) >
                                      22
                              ? Column(
                                  children: [
                                    stats[0],
                                    const SizedBox(height: 12),
                                    stats[1],
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: stats[0]),
                                    const SizedBox(width: 12),
                                    Expanded(child: stats[1]),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Sản phẩm đã gán', style: SampleA.section),
                      const SizedBox(height: 12),
                      ACard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AProductImage(
                                  product: product,
                                  imageUrl:
                                      device?.imageUrl ?? _productImageUrl,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product,
                                        style: SampleA.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        price,
                                        style: SampleA.body.copyWith(
                                          color: SampleA.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(store, style: SampleA.caption),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (widget.deviceId != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: AStockStatus(deviceId: widget.deviceId!),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ListenableBuilder(
                        listenable: StockService.instance,
                        builder: (context, _) => AButton(
                          label: offline
                              ? 'Kết nối lại'
                              : 'Đặt ${device?.quantity ?? 1} sản phẩm',
                          onPressed: offline
                              ? () => _showPage(_DevicePage.connection)
                              : device == null ||
                                    StockService.instance.problem(device.id) !=
                                        null
                              ? null
                              : () => showDeviceOrderSheet(context, device),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AButton(
                        label: 'Đổi sản phẩm',
                        onPressed: _handleChangeProduct,
                        kind: AButtonKind.secondary,
                      ),
                      const SizedBox(height: 16),
                      _SettingsRow(
                        icon: LucideIcons.package,
                        title: 'Thiết lập đặt hàng',
                        onTap: () => _showPage(_DevicePage.order),
                      ),
                      _SettingsRow(
                        icon: LucideIcons.settings,
                        title: 'Kết nối & thiết bị',
                        onTap: () => _showPage(_DevicePage.connection),
                      ),
                      const SizedBox(height: 14),
                      AButton(
                        key: const ValueKey('deleteDevice'),
                        label: 'Xóa thiết bị',
                        onPressed: _handleDeleteDevice,
                        kind: AButtonKind.danger,
                      ),
                    ],
                    _DevicePage.order => [
                      const Text(
                        'Đơn hàng của nút bấm',
                        style: SampleA.section,
                      ),
                      const SizedBox(height: 16),
                      ACard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: LucideIcons.store,
                              title: 'Cửa hàng',
                              subtitle: store,
                              onTap: _handleChangeStore,
                            ),
                            const Divider(height: 1, color: SampleA.border),
                            _SettingsRow(
                              icon: LucideIcons.package,
                              title: 'Sản phẩm',
                              subtitle: [
                                product,
                                if (price.isNotEmpty) price,
                              ].join(' · '),
                              onTap: _handleChangeProduct,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AButton(
                        label: 'Xong',
                        onPressed: () => _showPage(_DevicePage.overview),
                      ),
                    ],
                    _DevicePage.connection => [
                      const Text('Mạng Wi-Fi', style: SampleA.section),
                      const SizedBox(height: 16),
                      ACard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: LucideIcons.wifi,
                              title: wifi.isEmpty ? 'Chưa kết nối Wi-Fi' : wifi,
                              subtitle: offline || wifi.isEmpty
                                  ? 'Chưa kết nối'
                                  : 'Đã kết nối',
                            ),
                            const Divider(height: 1, color: SampleA.border),
                            _SettingsRow(
                              title: 'Thay đổi Wi-Fi',
                              onTap: () {
                                _wifiSsid = wifi;
                                _handleResetWifi();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AButton(
                        label: 'Xong',
                        onPressed: () => _showPage(_DevicePage.overview),
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

  Widget _stat(IconData icon, String value, String label) => ACard(
    padding: const EdgeInsets.all(12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: SampleA.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: SampleA.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(label, style: SampleA.caption),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _SettingsRow({
    this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: SampleA.primary),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SampleA.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: SampleA.caption),
                ],
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: SampleA.muted,
            ),
        ],
      ),
    ),
  );
}
