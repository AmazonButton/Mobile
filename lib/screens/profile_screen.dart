import '../widgets/app_motion.dart';
import '../widgets/sample_a.dart';
import '../widgets/user_avatar.dart';
import 'customer_bank_accounts_screen.dart';
import 'customer_buttons_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/smart_order_tour.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/address_provider.dart';
import '../providers/device_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/order_provider.dart';
import '../services/services.dart';
import 'address/address_list_screen.dart';
import 'login_screen.dart';
import 'main_layout.dart';
import 'store_wallet_screen.dart';
import 'system_staff/system_staff_returns_screen.dart';
import 'system_staff/system_staff_warranty_screen.dart';
import 'change_password_screen.dart';
import 'identity_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({super.key, this.showBackButton = true, this.tour});
  final SmartOrderTour? tour;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfileService _userService = UserProfileService();
  String? get _avatarUrl => _userProvider?.avatarUrl ?? _userService.avatarUrl;

  UserProvider? get _userProvider {
    try {
      return Provider.of<UserProvider>(context);
    } catch (_) {
      return null;
    }
  }

  String get userName => _userProvider?.name ?? _userService.name;
  String get userPhone => _userProvider?.phone ?? _userService.phone;
  String get userEmail => _userProvider?.email ?? _userService.email;
  String get userAddress => _userProvider?.address ?? _userService.address;
  File? get _avatarFile => _userProvider?.avatarFile ?? _userService.avatarFile;
  String get userInitials => _userProvider?.initials ?? _userService.initials;

  @override
  void initState() {
    super.initState();
    _userService.addListener(_onProfileChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final userProv = Provider.of<UserProvider>(context, listen: false);
        if (!userProv.isLoading) {
          userProv.loadProfile();
        }
        if (userProv.isCustomer) {
          Provider.of<AddressProvider>(context, listen: false).loadAddresses();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _userService.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  void _showFloatingToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 10,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.checkCircle2,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditNameModal() => _openProfileEditor(isPhone: false);

  void _openEditPhoneModal() => _openProfileEditor(isPhone: true);

  Future<void> _openProfileEditor({required bool isPhone}) async {
    final provider = context.read<UserProvider>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProfileEditSheet(
        isPhone: isPhone,
        initialValue: isPhone ? userPhone : userName,
        onSave: (value) =>
            isPhone ? provider.updatePhone(value) : provider.updateName(value),
      ),
    );
    if (saved == true && mounted) {
      _showFloatingToast('Cập nhật hồ sơ thành công');
    }
  }

  void _openEditAddressModal() async {
    HapticFeedback.lightImpact();
    final tour = widget.tour;
    tour?.openAddresses();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddressListScreen(tour: tour)),
    );
    tour?.addressesClosed();
    if (mounted) setState(() {});
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              UserProvider? userProv;
              DeviceProvider? deviceProv;
              OrderProvider? orderProv;
              AddressProvider? addrProv;
              NotificationProvider? notifProv;
              try {
                userProv = Provider.of<UserProvider>(context, listen: false);
                deviceProv = Provider.of<DeviceProvider>(context, listen: false);
                orderProv = Provider.of<OrderProvider>(context, listen: false);
                addrProv = Provider.of<AddressProvider>(context, listen: false);
                notifProv = Provider.of<NotificationProvider>(context, listen: false);
              } catch (_) {}
              Navigator.pop(ctx);
              try {
                await NotificationService().unregisterTokenOnLogout();
              } catch (_) {}
              try {
                await AuthApiService().logout();
              } catch (_) {}
              userProv?.reset();
              deviceProv?.reset();
              orderProv?.reset();
              addrProv?.reset();
              await notifProv?.clearAll();
              _userService.reset();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPolicyDialog(String title, List<String> paragraphs, {VoidCallback? onReplayTour}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: paragraphs
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          if (onReplayTour != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onReplayTour();
              },
              child: const Text('Xem hướng dẫn tương tác'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0E6BA8),
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Widget _menuRow({
    Key? key,
    required IconData icon,
    required String title,
    Color iconColor = const Color(0xFF2563EB),
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return TactilePress(
      key: key,
      scaleDown: 0.985,
      haptic: true,
      borderRadius: BorderRadius.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: titleColor ?? const Color(0xFF1E293B),
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: titleColor != null
                  ? titleColor.withValues(alpha: 0.5)
                  : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider?>();
    final isAdmin = userProv?.isAdmin ?? false;
    final isSystemStaff = userProv?.isSystemStaff ?? false;
    final isStoreOwner = userProv?.isStoreOwner ?? false;
    final isCustomer = !isAdmin && !isStoreOwner && !isSystemStaff;
    final roleLabel = userProv?.roleLabel ?? 'Khách hàng';
    final badgeBg = isAdmin
        ? const Color(0xFFEEF2FF)
        : isSystemStaff
            ? const Color(0xFFECFEFF)
            : isStoreOwner
                ? const Color(0xFFECFDF5)
                : const Color(0xFFE0F2FE);
    final badgeFg = isAdmin
        ? const Color(0xFF4338CA)
        : isSystemStaff
            ? const Color(0xFF0E7490)
            : isStoreOwner
                ? const Color(0xFF047857)
                : const Color(0xFF0369A1);

    const rowDivider = Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        automaticallyImplyLeading: widget.showBackButton,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: AContent(
        maxWidth: SampleA.detailWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Compact Clean Account Identity Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: AppMotion.cardShadow,
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      size: 58,
                      initials: userInitials,
                      file: _avatarFile,
                      url: _avatarUrl,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            userEmail.isNotEmpty ? userEmail : userPhone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  roleLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: badgeFg,
                                  ),
                                ),
                              ),
                              if (isStoreOwner &&
                                  (userProv?.storeName?.isNotEmpty == true))
                                Text(
                                  userProv!.storeName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Unified Flat Clean Account Menu List (All Roles)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: AppMotion.cardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _menuRow(
                      icon: LucideIcons.circleUserRound,
                      title: 'Thông tin tài khoản',
                      onTap: _editProfile,
                    ),
                    rowDivider,
                    _menuRow(
                      icon: LucideIcons.keyRound,
                      title: 'Thay đổi mật khẩu',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      ),
                    ),
                    if (isCustomer) ...[
                      rowDivider,
                      _menuRow(
                        key: widget.tour?.key(TourStep.addresses),
                        icon: LucideIcons.mapPin,
                        title: 'Địa chỉ giao hàng',
                        onTap: _openEditAddressModal,
                      ),
                      rowDivider,
                      _menuRow(
                        key: widget.tour?.key(TourStep.identity),
                        icon: LucideIcons.shieldCheck,
                        title: 'Xác minh danh tính (eKYC)',
                        onTap: () async {
                          final tour = widget.tour;
                          tour?.openIdentity();
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  IdentityVerificationScreen(tour: tour),
                            ),
                          );
                          tour?.identityClosed();
                        },
                      ),
                      rowDivider,
                      _menuRow(
                        key: widget.tour?.key(TourStep.deposit),
                        icon: LucideIcons.package,
                        title: 'Nút và tiền cọc',
                        onTap: () async {
                          final tour = widget.tour;
                          tour?.openDeposit();
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CustomerButtonsScreen(tour: tour),
                            ),
                          );
                          tour?.depositClosed();
                        },
                      ),
                      rowDivider,
                      _menuRow(
                        key: widget.tour?.key(TourStep.bank),
                        icon: LucideIcons.landmark,
                        title: 'Tài khoản hoàn cọc',
                        onTap: () async {
                          final tour = widget.tour;
                          tour?.openBank();
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CustomerBankAccountsScreen(tour: tour),
                            ),
                          );
                          tour?.bankClosed();
                        },
                      ),
                    ] else if (isStoreOwner) ...[
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.wallet,
                        iconColor: const Color(0xFF047857),
                        title: 'Ví doanh thu & Rút tiền',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const StoreWalletScreen(),
                          ),
                        ),
                      ),
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.package,
                        iconColor: const Color(0xFF047857),
                        title: 'Sản phẩm & tồn kho',
                        onTap: () => MainLayout.switchToTab(context, 1),
                      ),
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.cpu,
                        iconColor: const Color(0xFF0E6BA8),
                        title: 'Danh sách nút bấm IoT',
                        onTap: () => MainLayout.switchToTab(context, 2),
                      ),
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.receiptText,
                        iconColor: const Color(0xFFD97706),
                        title: 'Đơn hàng đại lý',
                        onTap: () => MainLayout.switchToTab(context, 3),
                      ),
                    ] else if (isSystemStaff) ...[
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.cpu,
                        iconColor: const Color(0xFF0E7490),
                        title: 'Kho & cấp phát nút',
                        onTap: () => MainLayout.switchToTab(context, 1),
                      ),
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.shieldCheck,
                        iconColor: const Color(0xFF0E7490),
                        title: 'Bảo hành thiết bị',
                        onTap: () => MainLayout.switchToTab(context, 2),
                      ),
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.rotateCcw,
                        iconColor: const Color(0xFFD97706),
                        title: 'Nhận nút trả',
                        onTap: () => MainLayout.switchToTab(context, 3),
                      ),
                    ] else if (isAdmin) ...[
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.store,
                        iconColor: const Color(0xFF4338CA),
                        title: 'Danh sách cửa hàng đối tác',
                        onTap: () => MainLayout.switchToTab(context, 1),
                      ),
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.cpu,
                        iconColor: const Color(0xFF0E6BA8),
                        title: 'Kho nút bấm toàn hệ thống',
                        onTap: () => MainLayout.switchToTab(context, 2),
                      ),
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.receiptText,
                        iconColor: const Color(0xFFD97706),
                        title: 'Đơn hàng toàn hệ thống',
                        onTap: () => MainLayout.switchToTab(context, 3),
                      ),
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.shieldCheck,
                        iconColor: const Color(0xFF0E7490),
                        title: 'Phiếu bảo hành thiết bị',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SystemStaffWarrantyScreen(),
                          ),
                        ),
                      ),
                      rowDivider,
                      _menuRow(
                        icon: LucideIcons.rotateCcw,
                        iconColor: const Color(0xFF7C3AED),
                        title: 'Thu hồi nút & Hoàn cọc',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SystemStaffReturnsScreen(),
                          ),
                        ),
                      ),
                    ],
                    rowDivider,
                    _menuRow(
                      icon: LucideIcons.bookOpen,
                      title: 'Hướng dẫn sử dụng',
                      onTap: () => _showPolicyDialog(
                        'Hướng dẫn sử dụng',
                        isSystemStaff
                            ? const [
                                '1. Kho & cấp phát nút: đăng ký mới, sinh lô, nhập CSV, cấp phát về custodyStoreId của đại lý và quản lý mẫu nút.',
                                '2. Bảo hành thiết bị: lập phiếu, duyệt đổi 1-1 kế thừa hợp đồng thuê hoặc khóa nút lỗi chuyển hoàn cọc chờ Admin duyệt.',
                                '3. Nhận nút trả: kiểm tra ngoại quan thiết bị khách hoàn trả và xác nhận nhập lại kho.',
                              ]
                            : isStoreOwner
                                ? const [
                                    '1. Sản phẩm & tồn kho: theo dõi danh mục sản phẩm, giá bán và tồn kho đại lý.',
                                    '2. Nút IoT: giám sát tình trạng kết nối, pin và sản phẩm gắn trên từng nút bấm.',
                                    '3. Đơn hàng: tiếp nhận đơn một chạm, xác nhận giao hàng và đối soát.',
                                  ]
                                : isAdmin
                                    ? const [
                                        '1. Giám sát cửa hàng đối tác, kho thiết bị IoT và đơn hàng toàn hệ thống.',
                                        '2. Các nghiệp vụ duyệt rút tiền PayOS, hoàn cọc và phân quyền RBAC được thực hiện trên cổng Web Admin.',
                                      ]
                                    : const [
                                        '1. Chọn cửa hàng và sản phẩm quen dùng hoặc ghép nối nút bấm qua Bluetooth (BLE).',
                                        '2. Nhấn 1 chạm trên nút vật lý hoặc trong mục Nút của tôi để đặt hàng tự động.',
                                        '3. Theo dõi trạng thái giao hàng, xác minh danh tính và hoàn tiền cọc trong mục Tài khoản.',
                                      ],
                        onReplayTour: isCustomer ? widget.tour?.replay : null,
                      ),
                    ),
                    rowDivider,
                    _menuRow(
                      icon: LucideIcons.fileText,
                      title: 'Chính sách bảo mật',
                      onTap: () => _showPolicyDialog(
                        'Chính sách bảo mật',
                        const [
                          'SmartOrder Button chỉ thu thập thông tin cần thiết để xác thực tài khoản, xử lý đơn hàng, bàn giao thiết bị IoT và bảo hành.',
                          'Mật khẩu được mã hóa một chiều bằng bcrypt; phiên đăng nhập sử dụng JWT và tự động thu hồi khi thay đổi quyền hoặc đổi mật khẩu.',
                          'Thông tin ngân hàng và định danh eKYC được bảo vệ và chỉ dùng cho mục đích xác minh chính chủ và hoàn cọc theo quy định.',
                        ],
                      ),
                    ),
                    rowDivider,
                    _menuRow(
                      icon: LucideIcons.fileText,
                      title: 'Điều khoản dịch vụ',
                      onTap: () => _showPolicyDialog(
                        'Điều khoản dịch vụ',
                        const [
                          'Người dùng chịu trách nhiệm bảo mật thông tin đăng nhập, mã ghép nối thiết bị và kiểm tra chính xác sản phẩm gắn trên nút bấm.',
                          'Mọi thao tác thuê nút, bảo hành đổi 1-1 và hoàn cọc tuân thủ đúng quy trình đối soát giữa khách hàng, cửa hàng và nền tảng.',
                          'Tổng đài hỗ trợ kỹ thuật SmartOrder: 1900 6868.',
                        ],
                      ),
                    ),
                    rowDivider,
                    _menuRow(
                      icon: LucideIcons.logOut,
                      iconColor: const Color(0xFFDC2626),
                      titleColor: const Color(0xFFDC2626),
                      title: 'Đăng xuất',
                      onTap: _confirmLogout,
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

  void _editProfile() {
    final userProv = context.read<UserProvider?>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Thông tin tài khoản',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoTile(
                icon: LucideIcons.user,
                title: 'Họ và tên',
                value: userName,
                isEditable: true,
                onTap: () {
                  Navigator.pop(dialogContext);
                  _openEditNameModal();
                },
              ),
              InfoTile(
                icon: LucideIcons.phone,
                title: 'Số điện thoại',
                value: userPhone.isNotEmpty ? userPhone : 'Chưa cập nhật',
                isEditable: true,
                onTap: () {
                  Navigator.pop(dialogContext);
                  _openEditPhoneModal();
                },
              ),
              InfoTile(
                icon: LucideIcons.mail,
                title: 'Email',
                value: userEmail,
              ),
              InfoTile(
                icon: LucideIcons.shieldCheck,
                title: 'Vai trò',
                value: userProv?.roleLabel ?? 'Khách hàng',
              ),
              if (userProv?.isStoreOwner == true &&
                  (userProv?.storeName?.isNotEmpty == true))
                InfoTile(
                  icon: LucideIcons.store,
                  title: 'Đại lý quản lý',
                  value: userProv!.storeName!,
                ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0E6BA8),
            ),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

/// Reusable InfoTile Widget for Contact Info & Attributes
class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isEditable;
  final VoidCallback? onTap;

  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.isEditable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileTap(
      onTap: isEditable ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditable)
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Color(0xFFCBD5E1),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable ActionTile Widget for Settings, Support, and Actions
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.titleColor,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TactileTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? const Color(0xFF1E293B),
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Color(0xFFCBD5E1),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tactile Tap Wrapper simulating iOS scale down (0.98) on tap down
class TactileTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TactileTap({super.key, required this.child, this.onTap});

  @override
  State<TactileTap> createState() => _TactileTapState();
}

class _TactileTapState extends State<TactileTap> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _ProfileEditSheet extends StatefulWidget {
  final bool isPhone;
  final String initialValue;
  final Future<void> Function(String) onSave;
  const _ProfileEditSheet({
    required this.isPhone,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final value = _controller.text.trim();
      await widget.onSave(
        widget.isPhone ? value.replaceAll(RegExp(r'\s+'), '') : value,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể lưu hồ sơ. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isPhone
                    ? 'Chỉnh sửa số điện thoại'
                    : 'Chỉnh sửa họ và tên',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                enabled: !_saving,
                keyboardType: widget.isPhone
                    ? TextInputType.phone
                    : TextInputType.name,
                decoration: InputDecoration(
                  labelText: widget.isPhone ? 'Số điện thoại' : 'Họ và tên',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (widget.isPhone) {
                    return RegExp(
                          r'^[0-9+]{8,15}$',
                        ).hasMatch(text.replaceAll(RegExp(r'\s+'), ''))
                        ? null
                        : 'Số điện thoại không hợp lệ';
                  }
                  return text.isEmpty || text.length > 100
                      ? 'Họ tên phải từ 1 đến 100 ký tự'
                      : null;
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
