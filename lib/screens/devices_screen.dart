import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/device_model.dart';
import '../providers/device_provider.dart';
import '../widgets/sample_a.dart';
import '../widgets/devices/device_card.dart';
import '../widgets/modals/product_selection_sheet.dart';
import '../widgets/modals/connect_device_sheet.dart';
import 'device_detail_screen.dart';
import '../widgets/smart_order_tour.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, this.tour});
  final SmartOrderTour? tour;
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _connectOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DeviceProvider?>()?.loadDevices();
    });
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
                const Text('Thiết bị', style: SampleA.title),
                const SizedBox(height: 6),
                const Text('Quản lý các nút trong nhà', style: SampleA.body),
                const SizedBox(height: 20),
                AButton(
                  key: widget.tour?.key(TourStep.add),
                  label: 'Thêm thiết bị',
                  icon: LucideIcons.plus,
                  onPressed: _connect,
                ),
                const SizedBox(height: 20),
                if (loading && devices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(color: SampleA.primary),
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
                  const SizedBox(height: 32),
                  const Text(
                    'Chào người bạn mới!',
                    style: SampleA.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thêm nút bấm đầu tiên.',
                    style: SampleA.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  for (final d in devices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DeviceCard(
                        id: d.id,
                        name: d.name,
                        room: d.room,
                        storeName: d.storeName,
                        product: d.product,
                        price: d.price,
                        batteryLevel: d.battery,
                        imageUrl: d.imageUrl,
                        badgeText: d.badgeText,
                        signal: d.signal,
                        isOnline: d.isOnline,
                        onTap: () => _detail(d),
                        onSettings: () => _detail(d),
                        onSelectProduct: () => ProductSelectionSheet.show(
                          context: context,
                          buttonName: d.name,
                          currentProductName: d.product,
                          deviceId: d.id,
                          onSave: (product, quantity) => context
                              .read<DeviceProvider>()
                              .updateDeviceProduct(
                                d.id,
                                product,
                                quantity: quantity,
                              ),
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
}
