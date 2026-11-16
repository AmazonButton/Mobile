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
import '../services/services.dart';
import 'address/address_list_screen.dart';
import 'login_screen.dart';
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
      try {
        Provider.of<UserProvider>(context, listen: false).loadProfile();
      } catch (_) {}
      try {
        Provider.of<AddressProvider>(context, listen: false).loadAddresses();
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
              try {
                userProv = Provider.of<UserProvider>(context, listen: false);
              } catch (_) {}
              Navigator.pop(ctx);
              await NotificationService().unregisterTokenOnLogout();
              await AuthApiService().logout();
              userProv?.reset();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text('Tài khoản'),
      centerTitle: true,
      automaticallyImplyLeading: widget.showBackButton,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    body: AContent(
      maxWidth: SampleA.detailWidth,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                UserAvatar(
                  size: 72,
                  initials: userInitials,
                  file: _avatarFile,
                  url: _avatarUrl,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _openEditNameModal,
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userPhone,
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                      TextButton.icon(
                        onPressed: _editProfile,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Chỉnh sửa hồ sơ'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _groupTitle('Thông tin cá nhân'),
            ActionTile(
              key: widget.tour?.key(TourStep.addresses),
              icon: LucideIcons.mapPin,
              title: 'Địa chỉ giao hàng',
              onTap: _openEditAddressModal,
            ),
            const Divider(height: 1),
            ActionTile(
              key: widget.tour?.key(TourStep.identity),
              icon: LucideIcons.shieldCheck,
              title: 'Xác minh danh tính',
              onTap: () async {
                final tour = widget.tour;
                tour?.openIdentity();
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => IdentityVerificationScreen(tour: tour),
                  ),
                );
                tour?.identityClosed();
              },
            ),
            const SizedBox(height: 16),
            _groupTitle('Nút & hoàn cọc'),
            ActionTile(
              key: widget.tour?.key(TourStep.deposit),
              icon: LucideIcons.package,
              title: 'Nút và tiền cọc',
              onTap: () async {
                final tour = widget.tour;
                tour?.openDeposit();
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CustomerButtonsScreen(tour: tour),
                  ),
                );
                tour?.depositClosed();
              },
            ),
            const Divider(height: 1),
            ActionTile(
              key: widget.tour?.key(TourStep.bank),
              icon: LucideIcons.landmark,
              title: 'Tài khoản hoàn cọc',
              onTap: () async {
                final tour = widget.tour;
                tour?.openBank();
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => CustomerBankAccountsScreen(tour: tour),
                  ),
                );
                tour?.bankClosed();
              },
            ),
            const SizedBox(height: 16),
            _groupTitle('Hỗ trợ & bảo mật'),
            ActionTile(
              icon: LucideIcons.lock,
              title: 'Đổi mật khẩu',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              ),
            ),
            const Divider(height: 1),
            if (widget.tour != null)
              ActionTile(
                icon: LucideIcons.bookOpen,
                title: 'Xem lại hướng dẫn',
                onTap: widget.tour!.replay,
              ),
            const Divider(height: 1),
            ActionTile(
              icon: LucideIcons.headphones,
              title: 'Hỗ trợ',
              onTap: () => _showFloatingToast('Tổng đài hỗ trợ: 1900 6868'),
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _confirmLogout,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _groupTitle(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F3F6),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );

  void _editProfile() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoTile(
            icon: LucideIcons.user,
            title: 'Họ và tên',
            value: userName,
            isEditable: true,
            onTap: () {
              Navigator.pop(sheetContext);
              _openEditNameModal();
            },
          ),
          InfoTile(
            icon: LucideIcons.phone,
            title: 'Số điện thoại',
            value: userPhone,
            isEditable: true,
            onTap: () {
              Navigator.pop(sheetContext);
              _openEditPhoneModal();
            },
          ),
          InfoTile(icon: LucideIcons.mail, title: 'Email', value: userEmail),
        ],
      ),
    ),
  );
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
