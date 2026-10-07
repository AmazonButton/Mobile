import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/devices/device_card.dart';
import '../widgets/modals/product_selection_sheet.dart';
import 'device_detail_screen.dart';
import 'button_product_selection_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late final List<Map<String, dynamic>> _devices = [
    {
      'id': 'btn-1',
      'name': 'Nút Bếp',
      'room': 'Khu vực Bếp ăn',
      'product': 'Nước Lavie 20L',
      'price': '65.000đ',
      'battery': 85,
      'badgeText': '20L',
      'signal': 'Rất tốt',
    },
    {
      'id': 'btn-2',
      'name': 'Nút Phòng Khách',
      'room': 'Bàn trà sofa',
      'product': 'Aquafina 500ml (24 chai)',
      'price': '98.000đ',
      'battery': 15, // Demonstrates Low Battery Alert UI (<= 20)
      'badgeText': '24 chai',
      'signal': 'Ổn định',
    },
    {
      'id': 'btn-3',
      'name': 'Nút Ban Công',
      'room': 'Lô gia tầng 12',
      'product': 'Bình Gas Petrolimex 12kg',
      'price': '380.000đ',
      'battery': 92,
      'badgeText': '12kg',
      'signal': 'Rất tốt',
    },
  ];

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
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showConfigureModal(Map<String, dynamic> device) {
    HapticFeedback.lightImpact();
    ProductSelectionSheet.show(
      context: context,
      buttonName: device['name'] as String,
      currentProductName: device['product'] as String,
      onSave: (selectedProduct) {
        setState(() {
          device['product'] = selectedProduct.shortName;
          device['price'] = selectedProduct.priceFormatted;
          device['badgeText'] = selectedProduct.shortName.contains('Gas')
              ? '12kg'
              : selectedProduct.shortName.contains('500ml')
                  ? '24 chai'
                  : '20L';
        });
        _showToast(
          'Đã gắn ${selectedProduct.shortName} cho ${device['name']}',
        );
      },
    );
  }

  void _navigateToDetail(Map<String, dynamic> device) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(
          deviceId: device['id'] as String?,
          deviceName: device['name'] as String,
          room: device['room'] as String,
          productName: device['product'] as String,
          productPrice: device['price'] as String,
          battery: device['battery'] as int,
        ),
      ),
    ).then((_) {
      // Re-render when returning if state changed
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: SafeArea(
        bottom: false,
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
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thiết bị',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_devices.length} nút bấm sẵn sàng kết nối',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  _TactileTap(
                    onTap: () => _showToast(
                      'Đang quét Bluetooth tìm Smart Button mới...',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.plus, size: 15, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Thêm nút',
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
            ),

            const SizedBox(height: 16),

            // ── Devices List ──
            ..._devices.map(
              (device) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DeviceCard(
                  id: device['id'] as String,
                  name: device['name'] as String,
                  room: device['room'] as String,
                  product: device['product'] as String,
                  price: device['price'] as String,
                  batteryLevel: device['battery'] as int,
                  badgeText: device['badgeText'] as String? ?? '20L',
                  signal: device['signal'] as String? ?? 'Rất tốt',
                  onTap: () => _navigateToDetail(device),
                  onSettings: () => _showConfigureModal(device),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ── Pairing Guide Card ──
            _buildPairingGuideCard(),
          ]
              .animate(interval: 50.ms)
              .fade(duration: 300.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
        ),
      ),
    );
  }

  Widget _buildPairingGuideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.info, size: 20, color: Color(0xFF3B82F6)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Để kết nối nút bấm mới: Giữ nút vật lý trong 5 giây cho đến khi đèn LED nhấp nháy xanh dương.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E3A8A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TactileTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactileTap({required this.child, required this.onTap});

  @override
  State<_TactileTap> createState() => _TactileTapState();
}

class _TactileTapState extends State<_TactileTap> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
