import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final void Function(DeviceModel device) onDeviceTap;
  final void Function(DeviceModel device) onDeviceOrder;
  final void Function(DeviceModel device) onDeviceSettings;

  const HomeSmartButtonsGrid({
    super.key,
    required this.devices,
    this.isLoading = false,
    this.buttonStateMap = const {},
    required this.onManage,
    required this.onAddDevice,
    required this.onDeviceTap,
    required this.onDeviceOrder,
    required this.onDeviceSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nút bấm của tôi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onManage();
              },
              child: const Text(
                'Quản lý >',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading && devices.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
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
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.radio, color: Color(0xFF2563EB), size: 24),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có nút bấm nào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kết nối nút bấm để đặt hàng tức thì chỉ với một chạm',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onAddDevice();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Thêm nút nhấn mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: devices.take(3).map(
              (device) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => onDeviceTap(device),
                  child: SmartButtonCard(
                    id: device.id,
                    name: device.name,
                    room: device.room,
                    product: device.product,
                    price: device.price,
                    battery: device.battery,
                    badgeText: device.badgeText,
                    state: buttonStateMap[device.id] ?? 'idle',
                    onOrder: () => onDeviceOrder(device),
                    onSettings: () => onDeviceSettings(device),
                  ),
                ),
              ),
            ).toList(),
          ),
      ],
    );
  }
}
