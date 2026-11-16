import '../../../widgets/sample_a.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../models/device_model.dart';
import '../../../widgets/devices/smart_button_card.dart';

/// Section displaying the user's smart buttons, loading indicators, empty states, and management shortcuts.
class HomeSmartButtonsGrid extends StatelessWidget {
  final List<DeviceModel> devices;
  final bool isLoading;
  final Map<String, String> buttonStateMap;
  final VoidCallback onManage;
  final VoidCallback onAddDevice;
  final void Function(DeviceModel device) onDeviceOrder;
  final void Function(DeviceModel device) onDeviceSettings;

  const HomeSmartButtonsGrid({
    super.key,
    required this.devices,
    this.isLoading = false,
    this.buttonStateMap = const {},
    required this.onManage,
    required this.onAddDevice,
    required this.onDeviceOrder,
    required this.onDeviceSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ASectionHeader(
          title: 'Nút của tôi',
          action: TextButton.icon(
            onPressed: onAddDevice,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm nút'),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading && devices.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(SampleA.primary),
              ),
            ),
          )
        else if (devices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SampleA.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: SampleA.pale,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.radio,
                      color: SampleA.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có thiết bị',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: SampleA.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kết nối Smart Button để đặt hàng bằng một chạm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onAddDevice,
                  style: FilledButton.styleFrom(
                    backgroundColor: SampleA.primary,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Thêm thiết bị'),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final singleColumn =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21;
              final width = singleColumn
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: devices
                    .take(2)
                    .map(
                      (device) => SizedBox(
                        width: width,
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
                          state: buttonStateMap[device.id] ?? 'idle',
                          onOrder: () => onDeviceOrder(device),
                          onSettings: () => onDeviceSettings(device),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        if (devices.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onManage,
              label: const Text('Xem tất cả nút'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              iconAlignment: IconAlignment.end,
              style: TextButton.styleFrom(foregroundColor: SampleA.primary),
            ),
          ),
      ],
    );
  }
}
