import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/device_model.dart';
import '../providers/device_provider.dart';
import '../widgets/sample_a.dart';
import '../widgets/devices/device_card.dart';
import '../widgets/devices/device_order_sheet.dart';
import '../widgets/modals/connect_device_sheet.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  int _filter = 0;
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
    final provider = context.read<DeviceProvider?>();
    final saved = await ConnectDeviceSheet.show(context);
    if (saved == true && mounted) await provider?.refreshDevices();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider?>();
    final devices = provider?.devices ?? DeviceModel.sampleDevices;
    final loading = provider?.isLoading ?? false;
    final attention = devices
        .where((d) => d.isOffline || d.battery <= 20)
        .length;
    final filtered = devices
        .where(
          (d) =>
              _filter == 0 ||
              (_filter == 1
                  ? d.isOnline && d.battery > 20
                  : d.isOffline || d.battery <= 20),
        )
        .toList();
    return Scaffold(
      backgroundColor: SampleA.background,
      body: SafeArea(
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
              Row(
                children: [
                  const Expanded(child: Text('Thiết bị', style: SampleA.title)),
                  AIconButton(
                    icon: LucideIcons.plus,
                    tooltip: 'Thêm thiết bị',
                    onPressed: _connect,
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                AButton(
                  label: 'Kết nối thiết bị đầu tiên',
                  onPressed: _connect,
                ),
              ] else ...[
                ACard(
                  color: SampleA.pale,
                  border: false,
                  child: Row(
                    children: [
                      const ABuddy(size: 48),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${devices.length} người bạn của nhà',
                              style: SampleA.body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${devices.length - attention} sẵn sàng · $attention cần chú ý',
                              style: SampleA.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (index, label) in [
                      'Tất cả · ${devices.length}',
                      'Sẵn sàng',
                      'Cần chú ý',
                    ].indexed)
                      ChoiceChip(
                        label: Text(label),
                        selected: _filter == index,
                        onSelected: (_) => setState(() => _filter = index),
                        showCheckmark: false,
                        selectedColor: SampleA.pale,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        labelStyle: const TextStyle(
                          fontFamily: 'SampleA Vietnam',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SampleA.primary,
                        ),
                        side: BorderSide(
                          color: _filter == index
                              ? SampleA.primary
                              : SampleA.border,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Không có thiết bị trong mục này.',
                      style: SampleA.body,
                    ),
                  ),
                for (final d in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DeviceCard(
                      id: d.id,
                      name: d.name,
                      room: d.room,
                      product: d.product,
                      price: d.price,
                      batteryLevel: d.battery,
                      imageUrl: d.imageUrl,
                      badgeText: d.badgeText,
                      signal: d.signal,
                      isOnline: d.isOnline,
                      onTap: () => _detail(d),
                      onSettings: () => _detail(d),
                      onOrder: () => showDeviceOrderSheet(context, d),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
