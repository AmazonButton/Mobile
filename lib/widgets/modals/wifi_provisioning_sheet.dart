import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Reusable tactile bounce helper: scales down to 0.96 on press.
class _TactileBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TactileBounce({required this.child, this.onTap});

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

/// Premium iOS-style Wi-Fi Provisioning modal bottom sheet.
///
/// Complies with:
/// - Anti-AI standards (flat design, Colors.white, thin border Color(0xFFE2E8F0), no heavy drop shadows)
/// - Strictly lucide_icons (no Material icons)
/// - IoT UX Best Practice: Auto-filled SSID, only asking for password, 2.4GHz warning banner
/// - Tactile button interactions (0.96 scale) and staggered flutter_animate transitions
class WifiProvisioningSheet extends StatefulWidget {
  final String initialSsid;
  final Function(String newSsid)? onConnected;

  const WifiProvisioningSheet({
    super.key,
    this.initialSsid = 'Home_Network_2.4G',
    this.onConnected,
  });

  /// Opens the Wi-Fi Provisioning bottom sheet with iOS styling.
  static Future<bool?> show({
    required BuildContext context,
    String initialSsid = 'Home_Network_2.4G',
    Function(String newSsid)? onConnected,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => WifiProvisioningSheet(
        initialSsid: initialSsid,
        onConnected: onConnected,
      ),
    );
  }

  @override
  State<WifiProvisioningSheet> createState() => _WifiProvisioningSheetState();
}

class _WifiProvisioningSheetState extends State<WifiProvisioningSheet> {
  late String _currentSsid;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isConnecting = false;

  final List<String> _availableNetworks = const [
    'Home_Network_2.4G',
    'LivingRoom_Mesh_2.4G',
    'Kitchen_IoT_Extender',
    'Office_Guest_2.4G',
  ];

  @override
  void initState() {
    super.initState();
    // Normalize SSID to 2.4G for IoT consistency if currently 5G
    final base = widget.initialSsid;
    if (base.contains('_5G')) {
      _currentSsid = base.replaceAll('_5G', '_2.4G');
    } else if (!base.contains('2.4G') && !base.contains('2.4')) {
      _currentSsid = '${base}_2.4G';
    } else {
      _currentSsid = base;
    }
    _detectCurrentWifiSsid();
  }

  Future<void> _detectCurrentWifiSsid() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        await Permission.locationWhenInUse.request();
      }
      final info = NetworkInfo();
      final wifiName = await info.getWifiName();
      if (wifiName != null && wifiName.isNotEmpty) {
        final cleaned = wifiName.replaceAll('"', '').trim();
        if (cleaned.isNotEmpty && cleaned != '<unknown ssid>') {
          if (mounted) {
            setState(() {
              _currentSsid = cleaned;
            });
          }
        }
      }
    } catch (_) {
      // Graceful fallback to initialSsid on simulators or when unsupported
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showChangeNetworkPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn mạng Wi-Fi (2.4GHz)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  _TactileBounce(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._availableNetworks.map((ssid) {
                final isSelected = ssid == _currentSsid;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _currentSsid = ssid);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.wifi,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ssid,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            LucideIcons.checkCircle2,
                            size: 18,
                            color: Color(0xFF1D4ED8),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _handleConnect() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Text(
            'Vui lòng nhập mật khẩu Wi-Fi để tiếp tục.',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isConnecting = true);

    // Simulate IoT BLE handshake & Wi-Fi provisioning
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;
    setState(() => _isConnecting = false);

    widget.onConnected?.call(_currentSsid);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Header (Drag Handle + Title + Close Button) ──
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 34), // Center balance
                    const Text(
                      'Cài đặt Wi-Fi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B), // Slate 800
                        letterSpacing: -0.3,
                      ),
                    ),
                    _TactileBounce(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── 2. 2.4GHz Warning Banner (IoT Standard) ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED), // Soft orange
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFED7AA), // Thin orange border
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 20,
                        color: Color(0xFFEA580C), // Orange icon
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Thiết bị chỉ hỗ trợ mạng Wi-Fi 2.4GHz. Vui lòng đảm bảo điện thoại của bạn không kết nối với mạng 5G.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFC2410C), // Orange text
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── 3. Network Form (Grouped List Style) ──
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
                        // SSID Field (Auto-filled)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.wifi,
                                size: 20,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentSsid,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Mạng tự động nhận diện',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _TactileBounce(
                                onTap: _showChangeNetworkPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Đổi mạng',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D4ED8), // Blue
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F5F9),
                        ),

                        // Password Field
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.lock,
                                size: 20,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  autofocus: true,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Mật khẩu Wi-Fi',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              _TactileBounce(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    _obscurePassword
                                        ? LucideIcons.eye
                                        : LucideIcons.eyeOff,
                                    size: 18,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── 4. Action Button ("Kết nối thiết bị") ──
                _TactileBounce(
                  onTap: _isConnecting ? null : _handleConnect,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isConnecting
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF1D4ED8), // Primary Blue
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _isConnecting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoActivityIndicator(
                                  color: Colors.white,
                                  radius: 9,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Đang kết nối thiết bị...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.wifi,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Kết nối thiết bị',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                SizedBox(height: bottomSafeArea > 0 ? 0 : 8),
              ]
                  .animate()
                  .fade(duration: 250.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutQuad),
            ),
          ),
        ),
      ),
    );
  }
}
