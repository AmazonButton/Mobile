import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/modals/product_selection_sheet.dart';
import '../widgets/modals/wifi_provisioning_sheet.dart';

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

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late String _deviceName;
  late String _room;
  late String _productName;
  late String _productPrice;
  late String _productImageUrl;
  late int _battery;
  late String _wifiSsid;
  bool _doubleConfirm = true;

  @override
  void initState() {
    super.initState();
    _deviceName = widget.deviceName;
    _room = widget.room;
    _productName = widget.productName;
    _productPrice = widget.productPrice;
    _productImageUrl = widget.productImageUrl ?? _resolveInitialImage(_productName);
    _battery = widget.battery;
    _wifiSsid = widget.wifiSsid;
  }

  String _resolveInitialImage(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gas') || lower.contains('petrolimex')) {
      return 'https://images.unsplash.com/photo-1584281722572-881585869106?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('gạo') || lower.contains('st25')) {
      return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=200&auto=format&fit=crop&q=80';
    }
    return 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=200&auto=format&fit=crop&q=80';
  }

  void _handleChangeProduct() {
    HapticFeedback.lightImpact();
    ProductSelectionSheet.show(
      context: context,
      buttonName: _deviceName,
      currentProductName: _productName,
      onSave: (selectedProduct) {
        setState(() {
          _productName = selectedProduct.shortName;
          _productPrice = selectedProduct.priceFormatted;

          final lower =
              '${selectedProduct.shortName} ${selectedProduct.name}'.toLowerCase();
          if (lower.contains('petrolimex')) {
            _productImageUrl =
                'https://images.unsplash.com/photo-1584281722572-881585869106?w=200&auto=format&fit=crop&q=80';
          } else if (lower.contains('gas') || lower.contains('saigon')) {
            _productImageUrl =
                'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=200&auto=format&fit=crop&q=80';
          } else if (lower.contains('gạo') || lower.contains('st25')) {
            _productImageUrl =
                'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=200&auto=format&fit=crop&q=80';
          } else if (lower.contains('aquafina')) {
            _productImageUrl =
                'https://images.unsplash.com/photo-1560023907-5f339617ea30?w=200&auto=format&fit=crop&q=80';
          } else if (lower.contains('omo')) {
            _productImageUrl =
                'https://images.unsplash.com/photo-1585338107529-13afc5f02586?w=200&auto=format&fit=crop&q=80';
          } else if (lower.contains('pulppy')) {
            _productImageUrl =
                'https://images.unsplash.com/photo-1584556812952-905ffd0c611a?w=200&auto=format&fit=crop&q=80';
          } else {
            _productImageUrl =
                'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=200&auto=format&fit=crop&q=80';
          }
        });
        _showToast('Đã gán $_productName vào $_deviceName');
      },
    );
  }

  void _handleResetWifi() {
    HapticFeedback.lightImpact();
    WifiProvisioningSheet.show(
      context: context,
      initialSsid: _wifiSsid,
      onConnected: (newSsid) {
        setState(() {
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "$_deviceName"? Nút bấm sẽ được ngắt kết nối và chuyển về trạng thái ban đầu.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.maybePop(context);
            },
            child: Text(
              'Xóa',
              style: TextStyle(
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
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: _TactileBounce(
          onTap: () => Navigator.maybePop(context),
          child: const Center(
            child: Icon(
              LucideIcons.chevronLeft,
              color: Color(0xFF1E293B),
              size: 22,
            ),
          ),
        ),
        title: const Text(
          'Cài đặt thiết bị',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        child: Column(
          children: [
            // ================= 1. HERO SECTION =================
            _buildHeroSection(),
            const SizedBox(height: 28),

            // ================= GROUP 1: ASSIGNED PRODUCT =================
            _buildActionBindingGroup(),
            const SizedBox(height: 24),

            // ================= GROUP 2: NETWORK & TRIGGERS =================
            _buildNetworkGroup(),
            const SizedBox(height: 32),

            // ================= GROUP 3: DANGER ZONE =================
            _buildDangerZoneGroup(),
          ]
              .animate(interval: 50.ms)
              .fade(duration: 300.ms)
              .slideY(begin: 0.05, curve: Curves.easeOut),
        ),
      ),
    );
  }

  // --- Sub-widgets ---

  Widget _buildHeroSection() {
    final isLowBattery = _battery <= 20;

    return Column(
      children: [
        // Large Circular Avatar (Radius 40 => 80x80)
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1558002038-1055907df827?w=200&auto=format&fit=crop&q=80',
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: const Color(0xFFE2E8F0),
                highlightColor: const Color(0xFFF8FAFC),
                child: Container(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFF1F5F9),
                child: const Center(
                  child: Icon(
                    LucideIcons.radio,
                    size: 36,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Device Name
        Text(
          _deviceName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.4,
          ),
        ),
        if (_room.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _room,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 6),

        // Status Row (Pulsing green/red dot + text)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isLowBattery
                    ? Colors.red.shade600
                    : const Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.3, 1.3),
                  duration: 1000.ms,
                  curve: Curves.easeInOut,
                )
                .fade(begin: 0.5, end: 1.0, duration: 1000.ms),
            const SizedBox(width: 8),
            Text(
              isLowBattery
                  ? 'Pin yếu: $_battery% • Cần sạc'
                  : 'Đang hoạt động • Pin $_battery%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isLowBattery ? Colors.red.shade600 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBindingGroup() {
    return _SettingsGroup(
      title: 'SẢN PHẨM ĐƯỢC GẮN',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // 48x48 Rounded Container with CachedNetworkImage
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: CachedNetworkImage(
                    imageUrl: _productImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: const Color(0xFFE2E8F0),
                      highlightColor: const Color(0xFFF8FAFC),
                      child: Container(color: const Color(0xFFE2E8F0)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(
                          LucideIcons.package,
                          size: 22,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _productPrice,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Custom premium text button "Thay đổi" with tactile bounce
              _TactileBounce(
                onTap: _handleChangeProduct,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFDBEAFE),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Thay đổi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8), // Primary Blue
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkGroup() {
    return _SettingsGroup(
      title: 'KẾT NỐI & TÙY CHỈNH',
      children: [
        // Tile 1: Wi-Fi hiện tại
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(LucideIcons.wifi, size: 20, color: Color(0xFF64748B)),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Wi-Fi hiện tại',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                _wifiSsid,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B), // Strict text color Color(0xFF64748B)
                ),
              ),
            ],
          ),
        ),

        // Tile 2: Thiết lập lại mạng
        _TactileBounce(
          onTap: _handleResetWifi,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(LucideIcons.refreshCw, size: 20, color: Color(0xFF64748B)),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Thiết lập lại mạng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),

        // Tile 3: Xác nhận kép (Safety Toggle)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 20,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xác nhận kép',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hỏi trên điện thoại trước khi chốt đơn',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _doubleConfirm,
                activeTrackColor: const Color(0xFF1D4ED8), // Primary Blue
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _doubleConfirm = val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZoneGroup() {
    return _SettingsGroup(
      title: 'VÙNG NGUY HIỂM',
      children: [
        _TactileBounce(
          onTap: _handleDeleteDevice,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  LucideIcons.trash2,
                  size: 20,
                  color: Colors.red.shade600,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Xóa thiết bị',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Colors.red.shade300,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// REUSABLE SETTINGS GROUP (APPLE HOME / MIHOME STYLE)
// =========================================================================

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B), // Slate 500
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0), // Thin slate border
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// TACTILE BOUNCE HELPER (0.96 SCALE ON TAP)
// =========================================================================

class _TactileBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TactileBounce({
    required this.child,
    this.onTap,
  });

  @override
  State<_TactileBounce> createState() => _TactileBounceState();
}

class _TactileBounceState extends State<_TactileBounce> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
