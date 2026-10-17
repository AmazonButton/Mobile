import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'login_screen.dart';
import 'main_layout.dart';
import 'device_detail_screen.dart';
import '../models/user_profile_service.dart';
import '../widgets/modals/product_selection_sheet.dart';
import '../widgets/devices/smart_button_card.dart';

typedef HomePage = HomeScreen;

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;

  const HomeScreen({super.key, this.showBottomNav = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _hasActiveOrder = true;
  final UserProfileService _userService = UserProfileService();

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  // Controllers for Animated Floating Bottom Toast
  late AnimationController _toastController;
  late Animation<Offset> _toastSlideAnimation;
  late Animation<double> _toastFadeAnimation;
  late Animation<double> _toastScaleAnimation;
  String? _toastMessage;
  VoidCallback? _toastOnUndo;
  Timer? _toastTimer;

  // Button pressed feedback states
  final Map<String, String> _buttonStateMap = {
    'btn-1': 'idle', // idle, ordering, ordered
    'btn-2': 'idle',
    'btn-3': 'idle',
  };

  late final List<Map<String, dynamic>> _devices = [
    {
      'id': 'btn-1',
      'name': 'Nút Bếp',
      'room': 'Khu vực Bếp ăn',
      'product': 'Nước Lavie 20L',
      'price': '65.000đ',
      'battery': 85,
      'badgeText': '20L',
    },
    {
      'id': 'btn-2',
      'name': 'Nút Phòng Khách',
      'room': 'Bàn trà sofa',
      'product': 'Aquafina 500ml · 24 chai',
      'price': '98.000đ',
      'battery': 15,
      'badgeText': '24 chai',
    },
    {
      'id': 'btn-3',
      'name': 'Nút Ban Công',
      'room': 'Khu vực Ban công',
      'product': 'Gas Petrolimex 12kg',
      'price': '[Giá]',
      'battery': 90,
      'badgeText': '12kg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onProfileChanged);

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
    _toastController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1300));
    if (mounted) {
      setState(() => _isLoading = false);
      _showToast('Đã làm mới dữ liệu nút bấm');
    }
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
                            const Icon(LucideIcons.check,
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

  void _showSettingsDialog(Map<String, dynamic> device) {
    HapticFeedback.lightImpact();
    ProductSelectionSheet.show(
      context: context,
      buttonName: device['name'] as String,
      currentProductName: device['product'] as String,
      onSave: (selectedProduct) {
        setState(() {
          device['product'] = selectedProduct.shortName;
          device['price'] = selectedProduct.priceFormatted;
          device['badgeText'] =
              selectedProduct.shortName.toLowerCase().contains('gas')
                  ? '12kg'
                  : '20L';
        });
        _showFloatingToast(
          message:
              'Đã gắn ${selectedProduct.shortName} cho ${device['name']}',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: Stack(
          children: [
            RefreshIndicator(
              color: const Color(0xFF60A5FA), // Pastel blue loading spinner
              backgroundColor: Colors.white,
              displacement: 40,
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverSafeArea(
                    bottom: false,
                    sliver: SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      sliver: SliverToBoxAdapter(
                        child: _isLoading
                            ? const _HomeScreenSkeleton()
                            : _buildMainContent(),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= 1. SEAMLESS HEADER =================
        _buildHeader(),
        const SizedBox(height: 20),

        // ================= 2. ACTIVE ORDER BANNER =================
        if (_hasActiveOrder) ...[
          _buildActiveOrderBanner(),
          const SizedBox(height: 22),
        ],

        // ================= 3. NÚT BẤM CỦA TÔI =================
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
                MainLayout.switchToTab(context, 1);
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
        const SizedBox(height: 14),
        ..._devices.map((device) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeviceDetailScreen(
                        deviceId: device['id'] as String?,
                        deviceName: device['name'] as String,
                        room: device['room'] as String? ?? 'Khu vực Bếp ăn',
                        productName: device['product'] as String,
                        productPrice: device['price'] as String,
                        battery: device['battery'] as int,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                child: SmartButtonCard(
                  id: device['id'] as String,
                  name: device['name'] as String,
                  room: device['room'] as String?,
                  product: device['product'] as String,
                  price: device['price'] as String,
                  battery: device['battery'] as int,
                  badgeText: device['badgeText'] as String? ?? '20L',
                  state: _buttonStateMap[device['id']] ?? 'idle',
                  onOrder: () => _handleButtonPress(
                    device['id'] as String,
                    device['name'] as String,
                    device['product'] as String,
                  ),
                  onSettings: () => _showSettingsDialog(device),
                ),
              ),
            )),
        const SizedBox(height: 16),

        // ================= 4. GỢI Ý CHO BẠN (QUICK SHOP) =================
        _QuickShopShelf(
          onAddProduct: (product) {
            _showToast('Đã thêm ${product['name']} vào danh sách chờ ghép nút');
          },
          onSeeAll: () {
            _showToast('Xem danh mục sản phẩm gợi ý');
          },
        )
            .animate()
            .fade(duration: 400.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutQuad),
        const SizedBox(height: 24),

        // ================= 5. HOẠT ĐỘNG GẦN ĐÂY =================
        _buildSectionHeader(
          title: 'Hoạt động gần đây',
          actionText: 'Xem tất cả',
          onAction: () => MainLayout.switchToTab(context, 2),
        ),
        const SizedBox(height: 12),
        _buildRecentActivities(),
      ],
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDBEAFE)),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _userService.shortName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Minimalist Notification bell icon button with red badge dot
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showToast('Không có thông báo mới');
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      LucideIcons.bell,
                      size: 18,
                      color: Color(0xFF475569),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Location Selector Pill
        GestureDetector(
          onTap: _showLocationPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _userService.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildActiveOrderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.droplets,
                    size: 20,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ĐANG GIAO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '1× Nước Lavie 20L',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  setState(() => _hasActiveOrder = false);
                  _showToast('Đã hủy đơn hàng');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECDD3)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Hủy đơn',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFF43F5E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.45,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
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
                  color: const Color(0xFF1E293B),
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
                              color: Color(0xFF60A5FA),
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
              icon: Icon(LucideIcons.home, color: Color(0xFF64748B), size: 20),
              selectedIcon:
                  Icon(LucideIcons.home, color: Color(0xFF1E293B), size: 20),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon:
                  Icon(LucideIcons.sliders, color: Color(0xFF64748B), size: 20),
              selectedIcon:
                  Icon(LucideIcons.sliders, color: Color(0xFF1E293B), size: 20),
              label: 'Thiết bị',
            ),
            NavigationDestination(
              icon:
                  Icon(LucideIcons.receipt, color: Color(0xFF64748B), size: 20),
              selectedIcon:
                  Icon(LucideIcons.receipt, color: Color(0xFF1E293B), size: 20),
              label: 'Đơn hàng',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.user, color: Color(0xFF64748B), size: 20),
              selectedIcon:
                  Icon(LucideIcons.user, color: Color(0xFF1E293B), size: 20),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    );
  }
}



// =========================================================================
// 2. QUICK SHOP / DISCOVER SHELF
// =========================================================================

class _QuickShopShelf extends StatelessWidget {
  final ValueChanged<Map<String, String>> onAddProduct;
  final VoidCallback onSeeAll;

  const _QuickShopShelf({
    required this.onAddProduct,
    required this.onSeeAll,
  });

  static const List<Map<String, String>> _products = [
    {
      'name': 'Gạo ST25 Ông Cua 5kg',
      'price': '180.000đ',
      'tag': 'Bán chạy',
    },
    {
      'name': 'Bia Heineken Silver 24 lon',
      'price': '435.000đ',
      'tag': 'Cuối tuần',
    },
    {
      'name': 'Nước giặt OMO Matic 3.6kg',
      'price': '175.000đ',
      'tag': 'Khuyên dùng',
    },
    {
      'name': 'Thùng Aquafina 500ml',
      'price': '98.000đ',
      'tag': 'Giao 2h',
    },
    {
      'name': 'Giấy Pulppy 10 cuộn',
      'price': '85.000đ',
      'tag': 'Nhu yếu phẩm',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gợi ý cho bạn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B), // slate-800
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _products[index];
              return Container(
                width: 136,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Thumbnail placeholder with pill badge
                    Container(
                      height: 72,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            item['name']!.contains('Gạo')
                                ? LucideIcons.wheat
                                : item['name']!.contains('Bia')
                                    ? LucideIcons.wine
                                    : item['name']!.contains('giặt')
                                        ? LucideIcons.sparkles
                                        : item['name']!.contains('Aquafina')
                                            ? LucideIcons.droplets
                                            : LucideIcons.package,
                            size: 26,
                            color: const Color(0xFF64748B),
                          ),
                          if (item['tag'] != null)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['tag']!,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Middle: Name & Price
                    Text(
                      item['name']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          item['price']!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onAddProduct(item);
                          },
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.plus,
                                size: 14,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// 3. SKELETON LOADING UI (PREMIUM SHIMMER)
// =========================================================================

class _HomeScreenSkeleton extends StatelessWidget {
  const _HomeScreenSkeleton();

  Widget _box({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _box(width: 42, height: 42, borderRadius: 21),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 90, height: 12, borderRadius: 6),
                    const SizedBox(height: 6),
                    _box(width: 140, height: 20, borderRadius: 6),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                _box(width: 38, height: 38, borderRadius: 19),
                const SizedBox(width: 8),
                _box(width: 38, height: 38, borderRadius: 19),
                const SizedBox(width: 8),
                _box(width: 38, height: 38, borderRadius: 19),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _box(width: 170, height: 30, borderRadius: 20),
        const SizedBox(height: 24),

        // 2. Active Order Skeleton
        _box(width: double.infinity, height: 56, borderRadius: 20),
        const SizedBox(height: 24),

        // 3. Promo Banner Carousel Skeleton
        _box(width: double.infinity, height: 130, borderRadius: 16),
        const SizedBox(height: 10),
        Center(child: _box(width: 40, height: 5, borderRadius: 4)),
        const SizedBox(height: 24),

        // 4. "Nút bấm của tôi" Skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _box(width: 140, height: 20, borderRadius: 6),
            _box(width: 90, height: 12, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 16),
        _buildDeviceCardSkeleton(),
        const SizedBox(height: 16),
        _buildDeviceCardSkeleton(),
        const SizedBox(height: 24),

        // 5. Predictive Insight Skeleton
        _box(width: double.infinity, height: 60, borderRadius: 20),
        const SizedBox(height: 24),

        // 6. Quick Shop Shelf Skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _box(width: 120, height: 18, borderRadius: 6),
            _box(width: 60, height: 12, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _box(
                    width: double.infinity, height: 190, borderRadius: 16)),
            const SizedBox(width: 12),
            Expanded(
                child: _box(
                    width: double.infinity, height: 190, borderRadius: 16)),
          ],
        ),
      ],
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.7));
  }

  Widget _buildDeviceCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(width: 56, height: 56, borderRadius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 130, height: 16, borderRadius: 6),
                    const SizedBox(height: 6),
                    _box(width: 180, height: 12, borderRadius: 6),
                  ],
                ),
              ),
              _box(width: 36, height: 36, borderRadius: 18),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _box(width: 60, height: 22, borderRadius: 20),
              const SizedBox(width: 8),
              _box(width: 50, height: 22, borderRadius: 20),
              const SizedBox(width: 8),
              _box(width: 60, height: 22, borderRadius: 20),
            ],
          ),
          const SizedBox(height: 16),
          _box(width: double.infinity, height: 46, borderRadius: 14),
        ],
      ),
    );
  }
}
