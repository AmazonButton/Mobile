import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'login_screen.dart';
import 'main_layout.dart';
import '../models/user_profile_service.dart';
import 'button_product_selection_screen.dart';
import 'signup_screen.dart';
import '../services/services.dart';

typedef HomePage = HomeScreen;

class HomeScreen extends StatefulWidget {
  final bool showBottomNav;

  const HomeScreen({super.key, this.showBottomNav = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final UserProfileService _userService = UserProfileService();

  // API Data States
  bool _isLoading = true;
  bool _hasActiveOrder = false;
  Map<String, dynamic>? _activeOrder;
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _recentOrders = [];
  List<String> _userAddresses = [];

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
  final Map<String, String> _buttonStateMap = {};

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

    _loadDashboardData();
  }

  @override
  void dispose() {
    _userService.removeListener(_onProfileChanged);
    _ledBreathController.dispose();
    _toastController.dispose();
    _toastTimer?.cancel();
    super.dispose();
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

  Map<String, dynamic> _parseOrderItem(Map<String, dynamic> ord) {
    String title = 'Đơn hàng SmartOrder';
    if (ord['items'] is List && (ord['items'] as List).isNotEmpty) {
      final first = (ord['items'] as List).first;
      final qty = first['quantity'] ?? 1;
      final name = first['productNameSnapshot'] ?? first['product']?['productName'] ?? 'Sản phẩm';
      title = '${qty}x $name';
    } else if (ord['orderItems'] is List && (ord['orderItems'] as List).isNotEmpty) {
      final first = (ord['orderItems'] as List).first;
      final qty = first['quantity'] ?? 1;
      final name = first['product']?['name'] ?? first['productName'] ?? 'Sản phẩm';
      title = '${qty}x $name';
    }

    final buttonName = ord['button']?['buttonName'] ?? ord['buttonName'] ?? 'Nút bấm SmartOrder';

    String timeStr = 'Gần đây';
    if (ord['createdAt'] != null) {
      try {
        final dt = DateTime.parse(ord['createdAt'].toString()).toLocal();
        final now = DateTime.now();
        if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
          timeStr = 'Hôm nay, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else {
          timeStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }
      } catch (_) {
        timeStr = ord['createdAt'].toString();
      }
    }

    final rawAmount = ord['totalAmount'] ?? ord['subtotalAmount'] ?? 0;
    final num amt = num.tryParse(rawAmount.toString()) ?? 0;
    final priceStr = _formatCurrency(amt);

    final rawStatus = (ord['orderStatus'] ?? ord['status'] ?? 'PENDING').toString().toUpperCase();
    String statusText = 'Chờ xử lý';
    Color statusBg = const Color(0xFFFEF3C7);
    Color statusBorder = const Color(0xFFFDE68A);
    Color statusColor = const Color(0xFFD97706);

    if (rawStatus == 'COMPLETED' || rawStatus == 'DELIVERED') {
      statusText = 'Đã nhận hàng';
      statusBg = const Color(0xFFECFDF5);
      statusBorder = const Color(0xFFA7F3D0);
      statusColor = const Color(0xFF047857);
    } else if (rawStatus == 'SHIPPING') {
      statusText = 'Đang giao hàng';
      statusBg = const Color(0xFFEFF6FF);
      statusBorder = const Color(0xFFBFDBFE);
      statusColor = const Color(0xFF2563EB);
    } else if (rawStatus == 'CONFIRMED' || rawStatus == 'PROCESSING') {
      statusText = 'Đang chuẩn bị';
      statusBg = const Color(0xFFF0FDF4);
      statusBorder = const Color(0xFFBBF7D0);
      statusColor = const Color(0xFF16A34A);
    } else if (rawStatus == 'CANCELLED') {
      statusText = 'Đã hủy';
      statusBg = const Color(0xFFFEF2F2);
      statusBorder = const Color(0xFFFECACA);
      statusColor = const Color(0xFFDC2626);
    }

    return {
      'id': ord['orderId']?.toString() ?? ord['id']?.toString() ?? '',
      'orderNumber': ord['orderNumber'] ?? ord['orderCode'] ?? '',
      'title': title,
      'room': buttonName,
      'time': timeStr,
      'price': priceStr,
      'status': statusText,
      'statusBg': statusBg,
      'statusBorder': statusBorder,
      'statusColor': statusColor,
    };
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch current profile
      try {
        final profile = await AuthApiService().getProfile();
        final user = profile['user'] ?? profile;
        if (user['fullName'] != null) {
          _userService.updateName(user['fullName'].toString());
        }
        if (user['email'] != null) {
          _userService.updateEmail(user['email'].toString());
        }
        if (user['phone'] != null) {
          _userService.updatePhone(user['phone'].toString());
        }

        final addrs = <String>[];
        if (profile['customerProfile']?['addresses'] is List) {
          for (final a in profile['customerProfile']['addresses'] as List) {
            final detail = a['addressDetail']?.toString();
            if (detail != null && detail.isNotEmpty) {
              addrs.add(detail);
            }
          }
        }
        if (addrs.isNotEmpty) {
          _userAddresses = addrs;
          _userService.updateAddress(addrs.first);
        } else if (user['address'] != null) {
          _userAddresses = [user['address'].toString()];
          _userService.updateAddress(user['address'].toString());
        }
      } catch (_) {}

      // 2. Fetch devices from API
      List<Map<String, dynamic>> parsedDevices = [];
      try {
        final rawDevices = await DevicesApiService().getDevices();
        parsedDevices = rawDevices
            .map((d) => _parseDeviceItem(Map<String, dynamic>.from(d as Map)))
            .toList();
      } catch (_) {}

      // 3. Fetch orders from API
      Map<String, dynamic>? activeOrder;
      final recentList = <Map<String, dynamic>>[];
      try {
        final rawOrders = await OrdersApiService().getOrders();
        for (final rawOrd in rawOrders) {
          final ord = Map<String, dynamic>.from(rawOrd as Map);
          final status = (ord['orderStatus'] ?? ord['status'] ?? '').toString().toUpperCase();

          if (activeOrder == null &&
              (status == 'PENDING' || status == 'CONFIRMED' || status == 'PROCESSING' || status == 'SHIPPING')) {
            activeOrder = ord;
          }

          if (recentList.length < 5) {
            recentList.add(_parseOrderItem(ord));
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _devices = parsedDevices;
          _activeOrder = activeOrder;
          _hasActiveOrder = activeOrder != null;
          _recentOrders = recentList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _handleButtonPress(String id, String name, String product) async {
    HapticFeedback.lightImpact();
    setState(() {
      _buttonStateMap[id] = 'ordering';
    });

    try {
      final res = await OrdersApiService().quickReorder(deviceId: id);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _buttonStateMap[id] = 'ordered';
      });

      final orderData = res['data'] ?? res;
      final orderId = orderData['id']?.toString() ?? orderData['orderId']?.toString();

      _showFloatingToast(
        message: 'Đã gửi lệnh đặt: $product ($name)',
        onUndo: orderId != null
            ? () async {
                HapticFeedback.lightImpact();
                try {
                  await OrdersApiService().cancelOrder(orderId, reason: 'Khách hàng hoàn tác');
                  if (!mounted) return;
                  _showFloatingToast(
                    message: 'Đã hoàn tác đơn hàng $product',
                    duration: const Duration(seconds: 2),
                  );
                  _loadDashboardData();
                } catch (e) {
                  if (!mounted) return;
                  _showFloatingToast(
                    message: 'Không thể hoàn tác: ${e is ApiException ? e.message : e.toString()}',
                  );
                }
                setState(() {
                  _buttonStateMap[id] = 'idle';
                });
              }
            : null,
      );

      _loadDashboardData();

      Timer(const Duration(milliseconds: 3200), () {
        if (!mounted) return;
        setState(() {
          _buttonStateMap[id] = 'idle';
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buttonStateMap[id] = 'idle';
      });
      _showFloatingToast(
        message: 'Lỗi đặt hàng: ${e is ApiException ? e.message : e.toString()}',
      );
    }
  }

  Future<void> _handleCancelActiveOrder(String orderId) async {
    HapticFeedback.lightImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hủy đơn hàng', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await OrdersApiService().cancelOrder(orderId, reason: 'Người dùng hủy từ bảng điều khiển');
      _showToast('Đã hủy đơn hàng');
      _loadDashboardData();
    } catch (e) {
      _showToast('Không thể hủy: ${e is ApiException ? e.message : e.toString()}');
    }
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
              ApiClient().clearTokens();
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
    final locations = _userAddresses.isNotEmpty
        ? _userAddresses
        : [
            _userService.address,
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
                          Expanded(
                            child: Text(
                              loc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  void _showSettingsDialog(Map<String, dynamic> device) {
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
            _showFloatingToast(
              message: 'Đã cập nhật cấu hình cho ${device['name']}',
            );
            _loadDashboardData();
          }
        } catch (e) {
          _showFloatingToast(
            message: 'Không thể lưu: ${e is ApiException ? e.message : e.toString()}',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = DateTime.now().hour < 12
        ? 'Chào buổi sáng,'
        : DateTime.now().hour < 18
            ? 'Chào buổi chiều,'
            : 'Chào buổi tối,';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Container(
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
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: const Color(0xFF1E293B),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= 1. HEADER =================
                      _buildHeader(greeting),
                      const SizedBox(height: 24),

                      // ================= 2. ACTIVE ORDER BANNER =================
                      if (_hasActiveOrder && _activeOrder != null) ...[
                        _buildActiveOrderBanner(),
                        const SizedBox(height: 24),
                      ],

                      // ================= 3. LOW BATTERY ALERTS (IF ANY) =================
                      _buildBatteryAlerts(),

                      // ================= 4. NÚT BẤM CỦA TÔI =================
                      _buildSectionHeader(
                        title: 'Nút bấm của tôi',
                        actionText: _isLoading
                            ? 'Đang tải...'
                            : '${_devices.length} nút sẵn sàng',
                      ),
                      const SizedBox(height: 16),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      else if (_devices.isEmpty)
                        _buildEmptyDevicesCard()
                      else
                        ..._devices.map((device) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildDeviceCard(device: device),
                            )),

                      const SizedBox(height: 20),

                      // ================= 5. HOẠT ĐỘNG GẦN ĐÂY =================
                      _buildSectionHeader(
                        title: 'Hoạt động gần đây',
                        actionText: 'Xem tất cả',
                        onAction: () => MainLayout.switchToTab(context, 2),
                      ),
                      const SizedBox(height: 12),

                      if (_isLoading)
                        const SizedBox.shrink()
                      else if (_recentOrders.isEmpty)
                        _buildEmptyActivities()
                      else
                        _buildRecentActivities(),
                    ],
                  ),
                ),
              ),
            ),

            // Animated Floating Bottom Notification (Toast/Snackbar)
            _buildFloatingToast(),
          ],
        ),
      ),
      bottomNavigationBar:
          (widget.showBottomNav as dynamic) == true ? _buildBottomNav() : null,
    );
  }

  // --- Sub-widgets ---

  Widget _buildHeader(String greeting) {
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
                    Text(
                      greeting,
                      style: const TextStyle(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen(initialStep: 3)),
                    ).then((_) => _loadDashboardData());
                  },
                ),
                const SizedBox(width: 8),
                _buildCircleIconButton(
                  icon: Icons.notifications_none_outlined,
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
    if (!_hasActiveOrder || _activeOrder == null) return const SizedBox.shrink();

    String itemTitle = 'Đơn hàng SmartOrder';
    if (_activeOrder!['items'] is List && (_activeOrder!['items'] as List).isNotEmpty) {
      final first = (_activeOrder!['items'] as List).first;
      final qty = first['quantity'] ?? 1;
      final name = first['productNameSnapshot'] ?? first['product']?['productName'] ?? 'Sản phẩm';
      itemTitle = '${qty}x $name';
    } else if (_activeOrder!['orderItems'] is List && (_activeOrder!['orderItems'] as List).isNotEmpty) {
      final first = (_activeOrder!['orderItems'] as List).first;
      final qty = first['quantity'] ?? 1;
      final name = first['product']?['name'] ?? first['productName'] ?? 'Sản phẩm';
      itemTitle = '${qty}x $name';
    }

    final rawStatus = (_activeOrder!['orderStatus'] ?? _activeOrder!['status'] ?? 'PENDING').toString().toUpperCase();
    String statusDesc = 'Đã gửi lệnh • Chờ xác nhận';
    if (rawStatus == 'CONFIRMED' || rawStatus == 'PROCESSING') {
      statusDesc = 'Cửa hàng đang chuẩn bị';
    } else if (rawStatus == 'SHIPPING') {
      statusDesc = 'Tài xế đang giao đến';
    }

    final orderId = _activeOrder!['orderId']?.toString() ?? _activeOrder!['id']?.toString() ?? '';

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
                children: [
                  Text(
                    itemTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusDesc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (orderId.isNotEmpty)
              OutlinedButton(
                onPressed: () => _handleCancelActiveOrder(orderId),
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

  Widget _buildBatteryAlerts() {
    final lowBatteryDevices = _devices.where((d) => (d['battery'] as int) <= 20).toList();
    if (lowBatteryDevices.isEmpty) return const SizedBox.shrink();

    final low = lowBatteryDevices.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nút "${low['name']}" đang ở mức pin thấp (${low['battery']}%). Vui lòng sạc hoặc thay pin.',
              style: const TextStyle(
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

  Widget _buildEmptyDevicesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.radio, size: 26, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa có nút bấm nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bạn chưa liên kết nút bấm thông minh nào. Nhấn nút bên dưới để thêm nút mới.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUpScreen(initialStep: 3)),
              ).then((_) => _loadDashboardData());
            },
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Thêm nút mới',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required Map<String, dynamic> device,
  }) {
    final id = device['id'] as String;
    final name = device['name'] as String;
    final room = device['room'] as String;
    final product = device['product'] as String;
    final price = device['price'] as String;
    final icon = device['icon'] as IconData;
    final battery = device['battery'] as int;
    final isOnline = device['isOnline'] as bool? ?? true;
    final signal = device['signal'] as String? ?? 'Rất tốt';

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
                  onPressed: () => _showSettingsDialog(device),
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
                  children: [
                    Icon(Icons.circle,
                        size: 6,
                        color: isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8)),
                    const SizedBox(width: 5),
                    Text(isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
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
                  children: [
                    const Icon(Icons.wifi, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(signal,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // The Primary Action Button
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
                          : const Color(0xFF64748B),
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

  Widget _buildEmptyActivities() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Chưa có hoạt động gần đây',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      children: _recentOrders.asMap().entries.map((entry) {
        final item = entry.value;
        final isLast = entry.key == _recentOrders.length - 1;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item['time']} • ${item['room']}',
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
                  const SizedBox(width: 12),
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
                          color: item['statusBg'] as Color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: item['statusBorder'] as Color),
                        ),
                        child: Text(
                          item['status']!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item['statusColor'] as Color,
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
