import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/device_model.dart';
import '../providers/device_provider.dart';
import '../widgets/devices/device_card.dart';
import '../widgets/modals/product_selection_sheet.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<DeviceModel> _fallbackDevices = List.from(DeviceModel.sampleDevices);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final provider = Provider.of<DeviceProvider>(context, listen: false);
        provider.loadDevices();
      } catch (_) {}
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
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
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showConfigureModal(DeviceModel device) {
    HapticFeedback.lightImpact();
    ProductSelectionSheet.show(
      context: context,
      buttonName: device.name,
      currentProductName: device.product,
      onSave: (selectedProduct) {
        try {
          context.read<DeviceProvider>().updateDeviceProduct(device.id, selectedProduct);
        } catch (_) {
          final badge = selectedProduct.shortName.contains('Gas')
              ? '12kg'
              : selectedProduct.shortName.contains('500ml')
                  ? '24 chai'
                  : '20L';

          final updated = device.copyWith(
            product: selectedProduct.shortName,
            price: selectedProduct.priceFormatted,
            badgeText: badge,
          );

          setState(() {
            final index = _fallbackDevices.indexWhere((d) => d.id == device.id);
            if (index != -1) {
              _fallbackDevices[index] = updated;
            }
          });
        }

        _showToast(
          'Đã gắn ${selectedProduct.shortName} cho ${device.name}',
        );
      },
    );
  }

  void _navigateToDetail(DeviceModel device) {
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
      setState(() {});
    });
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 90,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.radio,
                size: 30,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Chưa có nút bấm nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn chưa kết nối nút bấm thông minh nào cho căn hộ. Nhấn nút bên dưới để quét và kết nối thiết bị mới.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showToast('Đang quét Bluetooth tìm Smart Button mới...');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Thêm nút nhấn mới',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626), size: 28),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải danh sách nút bấm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DeviceModel> devices = _fallbackDevices;
    bool isLoading = false;
    String? errorMessage;
    DeviceProvider? provider;

    try {
      provider = Provider.of<DeviceProvider>(context);
      devices = provider.devices;
      isLoading = provider.isLoading;
      errorMessage = provider.errorMessage;
    } catch (_) {
      // Fallback for standalone tests without Provider
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            try {
              if (provider != null) {
                await provider.refreshDevices();
              } else {
                await Future.delayed(const Duration(milliseconds: 500));
              }
            } catch (_) {}
          },
          color: const Color(0xFF2563EB),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // ── Header Row ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thiết bị',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoading && devices.isEmpty
                              ? 'Đang tải danh sách...'
                              : '${devices.length} nút bấm đang kết nối',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showToast('Đang quét Bluetooth tìm Smart Button mới...');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB), // Vibrant blue button
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Thêm nút',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Devices Content (Loading, Error, Empty or List) ──
              if (isLoading && devices.isEmpty)
                _buildLoadingSkeleton()
              else if (errorMessage != null && devices.isEmpty)
                _buildErrorState(errorMessage, () {
                  provider?.loadDevices();
                })
              else if (devices.isEmpty)
                _buildEmptyState()
              else
                ...devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: DeviceCard(
                      id: device.id,
                      name: device.name,
                      room: device.room,
                      product: device.product,
                      price: device.price,
                      batteryLevel: device.battery,
                      badgeText: device.badgeText,
                      signal: device.signal,
                      isOnline: device.isOnline,
                      onTap: () => _navigateToDetail(device),
                      onSettings: () => _showConfigureModal(device),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
