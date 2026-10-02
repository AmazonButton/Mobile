import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/device_model.dart';

class IotDevicesCard extends StatefulWidget {
  final VoidCallback? onViewAll;

  const IotDevicesCard({super.key, this.onViewAll});

  @override
  State<IotDevicesCard> createState() => _IotDevicesCardState();
}

class _IotDevicesCardState extends State<IotDevicesCard> {
  final List<DeviceModel> _devices = DeviceModel.sampleDevices;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Thiết bị IoT cần chú ý',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onViewAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Device list ──
          for (int idx = 0; idx < _devices.length; idx++)
            _buildDeviceItem(_devices[idx], idx),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(DeviceModel device, int idx) {
    final bool isHovered = _hoveredIndex == idx;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = idx),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHovered ? AppColors.bgPage : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHovered ? AppColors.border : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Status Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: device.statusBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                device.isOffline
                    ? Icons.signal_cellular_connected_no_internet_0_bar_rounded
                    : Icons.sensors_rounded,
                size: 18,
                color: device.batteryColor,
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.id,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.location,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Battery bar & percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  device.batteryText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: device.batteryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (device.battery / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: device.batteryColor,
                          borderRadius: BorderRadius.circular(10),
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
    );
  }
}
