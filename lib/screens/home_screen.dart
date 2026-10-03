import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'main_layout.dart';
import '../models/user_profile_service.dart';

typedef HomePage = HomeScreen;

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;

  const HomeScreen({super.key, this.showBottomNav = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  bool _hasActiveOrder = true;
  final UserProfileService _userService = UserProfileService();

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  // Controllers for breathing LED animation
  late AnimationController _ledBreathController;
  late Animation<double> _ledBreathAnimation;

  // Controllers for Animated Floating Bottom Toast
  late AnimationController _toastController;
  late Animation<Offset> _toastSlideAnimation;
  late Animation<double> _toastFadeAnimation;
  late Animation<double> _toastScaleAnimation;
  String? _toastMessage;
  VoidCallback? _toastOnUndo;
  Timer? _toastTimer;

  // Button pressed feedback states
  final Map<String, bool> _buttonPressedMap = {};
  final Map<String, String> _buttonStateMap = {
    'btn-1': 'idle', // idle, ordering, ordered
    'btn-2': 'idle',
  };

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onProfileChanged);
    _ledBreathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _ledBreathAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _ledBreathController,
        curve: Curves.easeInOut,
      ),
    );

    // Toast Animation Controller with spring physics
    _toastController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _toastSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _toastController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _toastFadeAnimation = CurvedAnimation(
      parent: _toastController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _toastScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _toastController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _userService.removeListener(_onProfileChanged);
    _ledBreathController.dispose();
    _toastController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showFloatingToast({
    required String message,
    VoidCallback? onUndo,
    Duration duration = const Duration(seconds: 4),
  }) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastOnUndo = onUndo;
    });

    _toastController.forward(from: 0.0);

    _toastTimer = Timer(duration, () {
      _dismissToast();
    });
  }

  void _dismissToast() {
    _toastTimer?.cancel();
    if (_toastController.isAnimating || _toastController.isCompleted) {
      _toastController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _toastMessage = null;
            _toastOnUndo = null;
          });
        }
      });
    }
  }

  void _showToast(String message) {
    _showFloatingToast(message: message);
  }

  void _handleButtonPress(String id, String name, String product) {
    HapticFeedback.lightImpact();
    setState(() {
      _buttonStateMap[id] = 'ordering';
    });

    Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _buttonStateMap[id] = 'ordered';
      });

      _showFloatingToast(
        message: 'Đã gửi lệnh đặt: $product ($name)',
        onUndo: () {
          HapticFeedback.lightImpact();
          setState(() {
            _buttonStateMap[id] = 'idle';
          });
          _dismissToast();
          _showFloatingToast(
            message: 'Đã hoàn tác đơn hàng $product',
            duration: const Duration(seconds: 2),
          );
        },
      );

      Timer(const Duration(milliseconds: 3200), () {
        if (!mounted) return;
        setState(() {
          _buttonStateMap[id] = 'idle';
        });
      });
    });
  }

  void _handleLogout() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy',
                style: TextStyle(
                    color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Đăng xuất',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tài khoản cá nhân',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      image: _userService.avatarFile != null
                          ? DecorationImage(
                              image: FileImage(_userService.avatarFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _userService.avatarFile == null
                        ? Center(
                            child: Text(
                              _userService.initials,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userService.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _userService.email,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _userService.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    MainLayout.switchToTab(context, 3);
                  },
                  icon: const Icon(CupertinoIcons.person_crop_circle,
                      size: 18, color: Colors.white),
                  label: const Text(
                    'Xem & chỉnh sửa hồ sơ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64748B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleLogout();
                  },
                  icon: const Icon(Icons.logout_rounded,
                      size: 18, color: Color(0xFFF43F5E)),
                  label: const Text(
                    'Đăng xuất tài khoản',
                    style: TextStyle(
                      color: Color(0xFFF43F5E),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationPicker() {
    final locations = [
      'P.1204 - Tòa S2.05',
      'P.0812 - Tòa S1.01',
      'P.0405 - Tòa Masteri M2',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn vị trí giao hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                ...locations.map((loc) {
                  final isSelected = loc == _userService.address;
                  return InkWell(
                    onTap: () {
                      _userService.updateAddress(loc);
                      Navigator.pop(ctx);
                      _showToast('Đã chuyển sang: $loc');
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF1F5F9)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF475569),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check,
                                size: 18, color: Color(0xFF1E293B)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsDialog(String name, String room, String product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cấu hình $name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Vị trí đặt nút',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(room,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF1E293B))),
              ),
              const SizedBox(height: 14),
              const Text('Sản phẩm liên kết cố định',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(product,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF64748B))),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showToast('Đã lưu cấu hình thiết bị');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA3B8CD),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Lưu thay đổi',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.35, 1.0],
            colors: [
              Color(0xFFEBF4FE), // Xanh nhạt sang trọng đồng bộ đăng nhập/đăng ký
              Color(0xFFF7FAFD), // Chuyển màu nhẹ nhàng
              Colors.white,      // Trắng sáng vùng dưới
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // ================= 1. SEAMLESS HEADER =================
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // ================= 2. ACTIVE ORDER BANNER =================
                  if (_hasActiveOrder) ...[
                    _buildActiveOrderBanner(),
                    const SizedBox(height: 24),
                  ],

                  // ================= 3. NÚT BẤM CỦA TÔI =================
                  _buildSectionHeader(
                    title: 'Nút bấm của tôi',
                    actionText: '2 nút sẵn sàng',
                  ),
                  const SizedBox(height: 16),
                  _buildDeviceCard(
                    id: 'btn-1',
                    name: 'Nút Bếp',
                    room: 'Khu vực Bếp',
                    product: 'Nước Lavie 20L',
                    price: '65.000đ',
                    icon: Icons.water_drop_outlined,
                    battery: 85,
                  ),
                  const SizedBox(height: 16),
                  _buildDeviceCard(
                    id: 'btn-2',
                    name: 'Nút Ban Công',
                    room: 'Lô gia',
                    product: 'Bình Gas Petrolimex 12kg',
                    price: '380.000đ',
                    icon: Icons.local_fire_department_outlined,
                    battery: 92,
                  ),
                  const SizedBox(height: 24),

                  // ================= 4. PREDICTIVE INSIGHT =================
                  _buildPredictiveInsight(),
                  const SizedBox(height: 28),

                  // ================= 5. HOẠT ĐỘNG GẦN ĐÂY =================
                  _buildSectionHeader(
                    title: 'Hoạt động gần đây',
                    actionText: 'Xem tất cả',
                    onAction: () => MainLayout.switchToTab(context, 2),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentActivities(),
                ],
              ),
            ),
          ),

          // Animated Floating Bottom Notification (Toast/Snackbar)
          _buildFloatingToast(),
        ],
      ),
    ),

      // ================= 6. BOTTOM NAVIGATION BAR =================
      bottomNavigationBar:
          (widget.showBottomNav as dynamic) == true ? _buildBottomNav() : null,
    );
  }

  // --- Sub-widgets ---

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _showAccountSheet,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      image: _userService.avatarFile != null
                          ? DecorationImage(
                              image: FileImage(_userService.avatarFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _userService.avatarFile == null
                        ? Center(
                            child: Text(
                              _userService.initials,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chào buổi sáng,',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _userService.shortName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                _buildCircleIconButton(
                  icon: Icons.add,
                  onTap: () => _showToast('Đang quét tìm Smart Button mới...'),
                ),
                const SizedBox(width: 8),
                _buildCircleIconButton(
                  icon: Icons.notifications_none_outlined,
                  hasBadge: true,
                  onTap: () => _showToast('Không có thông báo mới'),
                ),
                const SizedBox(width: 8),
                _buildCircleIconButton(
                  icon: Icons.logout_rounded,
                  onTap: _handleLogout,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Location Pill
        GestureDetector(
          onTap: _showLocationPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    _userService.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down,
                    size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF475569)),
            if (hasBadge)
              Positioned(
                top: 8,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderBanner() {
    return GestureDetector(
      onTap: () {
        MainLayout.switchToTab(context, 2);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '1x Nước Lavie 20L',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tài xế đang đến (~5 phút)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() => _hasActiveOrder = false);
              _showToast('Đã hủy đơn hàng');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFECDD3)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFF43F5E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.4,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceCard({
    required String id,
    required String name,
    required String room,
    required String product,
    required String price,
    required IconData icon,
    required int battery,
  }) {
    final state = _buttonStateMap[id] ?? 'idle';
    final isOrdering = state == 'ordering';
    final isOrdered = state == 'ordered';
    final isPressed = _buttonPressedMap[id] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Names + Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Icon(icon, size: 24, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '($room)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF64748B)),
                          children: [
                            TextSpan(text: '$product • '),
                            TextSpan(
                              text: price,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _showSettingsDialog(name, room, product),
                  icon: const Icon(Icons.settings_outlined,
                      size: 19, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Badges (iOS Style)
          Row(
            children: [
              _buildBadge(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                    SizedBox(width: 5),
                    Text('Online',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildBadge(
                child: Text('🔋 $battery%',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569))),
              ),
              const SizedBox(width: 8),
              _buildBadge(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.wifi, size: 12, color: Color(0xFF94A3B8)),
                    SizedBox(width: 4),
                    Text('Khỏe',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // The Primary Action Button (Pastel Blue-Gray bg-[#A3B8CD] + Tactile Spring)
          GestureDetector(
            onTapDown: (_) => setState(() => _buttonPressedMap[id] = true),
            onTapUp: (_) => setState(() => _buttonPressedMap[id] = false),
            onTapCancel: () => setState(() => _buttonPressedMap[id] = false),
            onTap: isOrdering
                ? null
                : () => _handleButtonPress(id, name, product),
            child: AnimatedScale(
              scale: isPressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isOrdered
                      ? const Color(0xFF059669)
                      : isOrdering
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B), // Slate 500 - Xanh Thép Đậm
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E293B)
                          .withValues(alpha: isPressed ? 0.08 : 0.22),
                      blurRadius: isPressed ? 4 : 10,
                      offset: Offset(0, isPressed ? 1 : 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hardware Breathing LED Dot
                    FadeTransition(
                      opacity: isOrdered
                          ? const AlwaysStoppedAnimation(1.0)
                          : _ledBreathAnimation,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOrdered
                              ? Colors.white
                              : isOrdering
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFF34D399),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isOrdered
                                      ? Colors.white
                                      : isOrdering
                                          ? const Color(0xFFFCD34D)
                                          : const Color(0xFF34D399))
                                  .withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOrdered
                          ? 'Đã đặt hàng thành công'
                          : isOrdering
                              ? 'Đang gửi tín hiệu...'
                              : 'Bấm đặt ngay',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: child,
    );
  }

  Widget _buildPredictiveInsight() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('💡', style: TextStyle(fontSize: 16)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bình Lavie của bạn dự kiến còn dùng được khoảng 3 ngày nữa.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {
        'title': '1x Nước Lavie 20L',
        'room': 'Nút Bếp',
        'time': 'Hôm nay, 10:30',
        'price': '65.000đ',
        'status': 'Đã nhận hàng',
      },
      {
        'title': '1x Bình Gas Petrolimex 12kg',
        'room': 'Nút Ban Công',
        'time': '28 Th09, 15:45',
        'price': '380.000đ',
        'status': 'Đã nhận hàng',
      },
    ];

    return Column(
      children: activities.asMap().entries.map((entry) {
        final item = entry.value;
        final isLast = entry.key == activities.length - 1;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item['time']} • ${item['room']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['price']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          item['status']!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isLast)
              const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFloatingToast() {
    if (_toastMessage == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 18,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _toastSlideAnimation,
        child: FadeTransition(
          opacity: _toastFadeAnimation,
          child: ScaleTransition(
            scale: _toastScaleAnimation,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.horizontal,
              onDismissed: (_) {
                _toastTimer?.cancel();
                _toastController.reset();
                setState(() {
                  _toastMessage = null;
                  _toastOnUndo = null;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Deep Slate/Navy (Apple-grade)
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left: Glowing Check Icon
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Middle: Message Text
                    Expanded(
                      child: Text(
                        _toastMessage!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),

                    // Right: Action Button "HOÀN TÁC"
                    if (_toastOnUndo != null) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _toastOnUndo?.call();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF60A5FA)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'HOÀN TÁC',
                            style: TextStyle(
                              color: Color(0xFF60A5FA), // Soft Blue Accent
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
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
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFE2E8F0),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: -0.2,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              letterSpacing: -0.2,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (int index) {
            HapticFeedback.selectionClick();
            MainLayout.switchToTab(context, index);
          },
          backgroundColor: Colors.white,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF1E293B)),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.tune_rounded, color: Color(0xFF1E293B)),
              label: 'Thiết bị',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF1E293B)),
              label: 'Đơn hàng',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1E293B)),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}
