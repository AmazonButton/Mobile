import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'button_product_selection_screen.dart';
import 'signup_screen.dart';
import '../services/services.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  String _formatCurrency(num amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join()}đ';
  }

  Map<String, dynamic> _parseDeviceItem(Map<String, dynamic> raw) {
    final deviceId = raw['deviceId']?.toString() ??
        raw['id']?.toString() ??
        raw['buttonId']?.toString() ??
        '';
    final dbId = raw['id']?.toString() ?? raw['buttonId']?.toString() ?? deviceId;
    final name = raw['buttonName']?.toString() ??
        raw['name']?.toString() ??
        raw['customName']?.toString() ??
        'Nút thông minh';
    final room = raw['roomLocation']?.toString() ??
        raw['address']?['addressDetail']?.toString() ??
        raw['addressDetail']?.toString() ??
        'Căn hộ';

    String productName = 'Chưa gán sản phẩm';
    String price = '0đ';
    if (raw['buttonProducts'] is List && (raw['buttonProducts'] as List).isNotEmpty) {
      final bp = (raw['buttonProducts'] as List).first;
      final prod = bp['product'];
      if (prod != null) {
        productName = prod['productName']?.toString() ?? prod['name']?.toString() ?? productName;
        final rawPrice = prod['basePrice'] ?? prod['price'];
        if (rawPrice != null) {
          final p = num.tryParse(rawPrice.toString()) ?? 0;
          price = _formatCurrency(p);
        }
      }
    } else if (raw['products'] is List && (raw['products'] as List).isNotEmpty) {
      final prod = (raw['products'] as List).first;
      productName = prod['productName']?.toString() ?? prod['name']?.toString() ?? productName;
      final rawPrice = prod['price'] ?? prod['basePrice'];
      if (rawPrice != null) {
        final p = num.tryParse(rawPrice.toString()) ?? 0;
        price = _formatCurrency(p);
      }
    }

    IconData icon = LucideIcons.package;
    final lower = productName.toLowerCase();
    if (lower.contains('nước') || lower.contains('water') || lower.contains('lavie') || lower.contains('aquafina')) {
      icon = LucideIcons.droplets;
    } else if (lower.contains('gas') || lower.contains('petrolimex')) {
      icon = LucideIcons.flame;
    } else if (lower.contains('gạo') || lower.contains('rice') || lower.contains('st25')) {
      icon = LucideIcons.shoppingBag;
    } else if (lower.contains('giấy') || lower.contains('pulppy')) {
      icon = LucideIcons.archive;
    }

    final rawBattery = raw['batteryLevel'] ?? raw['battery'] ?? 100;
    final battery = rawBattery is int ? rawBattery : (int.tryParse(rawBattery.toString()) ?? 100);
    final status = (raw['status'] ?? 'ACTIVE').toString().toUpperCase();
    final isOnline = status == 'ACTIVE';

    final wifiRSSI = raw['wifiRSSI'];
    String signal = 'Rất tốt';
    if (wifiRSSI is num) {
      if (wifiRSSI > -60) {
        signal = 'Rất tốt';
      } else if (wifiRSSI > -75) {
        signal = 'Khá';
      } else {
        signal = 'Yếu';
      }
    }

    return {
      'id': deviceId,
      'dbId': dbId,
      'name': name,
      'room': room,
      'product': productName,
      'price': price,
      'icon': icon,
      'battery': battery,
      'status': status,
      'isOnline': isOnline,
      'signal': signal,
      'raw': raw,
    };
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final rawDevices = await DevicesApiService().getDevices();
      final parsed = rawDevices
          .map((d) => _parseDeviceItem(Map<String, dynamic>.from(d as Map)))
          .toList();

      if (mounted) {
        setState(() {
          _devices = parsed;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
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
    ButtonProductSelectionScreen.open(
      context: context,
      buttonName: device['name'] as String,
      room: device['room'] as String,
      currentProductName: device['product'] as String,
      onSave: (selectedProduct, updatedRoom) async {
        final dbId = device['dbId']?.toString() ?? device['id']?.toString() ?? '';
        try {
          if (dbId.isNotEmpty) {
            await DevicesApiService().updateCustomerConfig(
              dbId,
              buttonName: device['name'],
              roomLocation: updatedRoom,
              productId: selectedProduct.id,
            );
            _showToast('Đã liên kết ${selectedProduct.shortName} cho ${device['name']}');
            _loadDevices();
          }
        } catch (e) {
          _showToast('Lỗi cập nhật: ${e is ApiException ? e.message : e.toString()}');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.35, 1.0],
            colors: [
              Color(0xFFEBF4FE),
              Color(0xFFF7FAFD),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadDevices,
            color: const Color(0xFF1E293B),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // Header
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLoading
                                ? 'Đang tải dữ liệu...'
                                : '${_devices.length} nút sẵn sàng kết nối',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      _TactileTap(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpScreen(initialStep: 3)),
                          ).then((_) => _loadDevices());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

                // Devices List or Empty State
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else if (_devices.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.radio, size: 36, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có thiết bị nào',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bạn chưa liên kết nút bấm nào với tài khoản. Nhấn "Thêm nút" để bắt đầu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ),
                  )
                else
                  ..._devices.map((device) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDeviceCard(device: device),
                      )),

                const SizedBox(height: 4),

                // Pairing Banner
                _buildPairingGuideCard(),
              ]
                  .animate(interval: 50.ms)
                  .fade(duration: 250.ms)
                  .slideY(begin: 0.05, curve: Curves.easeOutQuad),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard({
    required Map<String, dynamic> device,
  }) {
    final name = device['name'] as String;
    final room = device['room'] as String;
    final product = device['product'] as String;
    final price = device['price'] as String;
    final icon = device['icon'] as IconData;
    final battery = device['battery'] as int;
    final signal = device['signal'] as String? ?? 'Rất tốt';
    final isOnline = device['isOnline'] as bool? ?? true;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      room,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _TactileTap(
                onTap: () => _showConfigureModal(device),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: const Icon(
                    LucideIcons.settings2,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Metadata row: Product & Battery & WiFi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SẢN PHẨM CỐ ĐỊNH',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$product ($price)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(LucideIcons.batteryMedium, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    '$battery%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.wifi, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    signal,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPairingGuideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF).withValues(alpha: 0.6),
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
