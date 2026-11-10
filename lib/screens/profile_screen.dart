import '../widgets/user_avatar.dart';
import 'customer_bank_accounts_screen.dart';
import 'customer_buttons_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  const ProfileScreen({super.key, this.showBackButton = true});

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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressListScreen()),
    );
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
            colors: [Color(0xFFEBF4FE), Color(0xFFF7FAFD), Colors.white],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Transparent App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                  child: Row(
                    children: [
                      if ((widget.showBackButton as dynamic) == true &&
                          Navigator.canPop(context))
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            LucideIcons.chevronLeft,
                            color: Color(0xFF1E293B),
                            size: 24,
                          ),
                          splashRadius: 22,
                        )
                      else
                        const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hồ sơ của tôi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      if (widget.showBackButton && Navigator.canPop(context))
                        const SizedBox(width: 40)
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),

              // Animated Grouped Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children:
                        [
                              // 1. Header Section (Avatar & Name)
                              _buildHeaderSection(),
                              const SizedBox(height: 28),

                              // 2. Contact Info Group (Card 1)
                              _buildContactInfoCard(),
                              const SizedBox(height: 18),

                              // 3. Settings & Support Group (Card 2)
                              _buildSettingsCard(),
                              const SizedBox(height: 18),

                              // 4. Danger Zone (Card 3)
                              _buildDangerZoneCard(),
                              const SizedBox(height: 28),

                              // 5. Footer
                              _buildFooter(),
                              const SizedBox(height: 40),
                            ]
                            .animate(interval: 50.ms)
                            .fade(duration: 300.ms)
                            .slideY(begin: 0.05, curve: Curves.easeOutQuad),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 1. HEADER SECTION =================
  Widget _buildHeaderSection() {
    return Center(
      child: Column(
        children: [
          UserAvatar(
            size: 90,
            initials: userInitials,
            file: _avatarFile,
            url: _avatarUrl,
          ),
          const SizedBox(height: 14),

          // Name with Edit Pencil
          TactileTap(
            onTap: _openEditNameModal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.pencil,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),

          const Text(
            'Thành viên từ Th08 2026',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. CONTACT INFO GROUP (Card 1) =================
  Widget _buildContactInfoCard() {
    return _buildGroupCard([
      InfoTile(
        icon: LucideIcons.phone,
        title: 'Số điện thoại',
        value: userPhone,
        isEditable: true,
        onTap: _openEditPhoneModal,
      ),
      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      InfoTile(
        icon: LucideIcons.mail,
        title: 'Email',
        value: userEmail,
        isEditable: false,
      ),
      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      InfoTile(
        icon: LucideIcons.mapPin,
        title: 'Địa chỉ giao hàng',
        value: userAddress.trim().isNotEmpty
            ? userAddress
            : 'Chưa thiết lập địa chỉ',
        isEditable: true,
        onTap: _openEditAddressModal,
      ),
    ]);
  }

  // ================= 3. SETTINGS & SUPPORT GROUP (Card 2) =================
  Widget _buildSettingsCard() {
    return _buildGroupCard([
      ActionTile(
        icon: LucideIcons.package,
        title: 'Nút và tiền cọc',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CustomerButtonsScreen(),
          ),
        ),
      ),
      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ActionTile(
        icon: LucideIcons.creditCard,
        title: 'Tài khoản hoàn cọc',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CustomerBankAccountsScreen(),
          ),
        ),
      ),
      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ActionTile(
        icon: LucideIcons.lock,
        title: 'Đổi mật khẩu',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
        ),
      ),
      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ActionTile(
        icon: LucideIcons.shieldCheck,
        title: 'Xác minh danh tính',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const IdentityVerificationScreen(),
          ),
        ),
      ),
      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ActionTile(
        icon: LucideIcons.headphones,
        title: 'Trung tâm hỗ trợ',
        onTap: () => _showFloatingToast('Tổng đài hỗ trợ: 1900 6868'),
      ),
    ]);
  }

  // ================= 4. DANGER ZONE GROUP (Card 3) =================
  Widget _buildDangerZoneCard() {
    return _buildGroupCard([
      ActionTile(
        icon: LucideIcons.logOut,
        iconColor: const Color(0xFF1E293B),
        title: 'Đăng xuất',
        titleColor: const Color(0xFF1E293B),
        showChevron: false,
        onTap: _confirmLogout,
      ),
    ]);
  }

  // ================= 5. FOOTER =================
  Widget _buildFooter() {
    return const Center(
      child: Text(
        'Phiên bản 1.0.0 (Build 12)',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8), // Slate 400
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // Card Container (iOS Grouped Style)
  Widget _buildGroupCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
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
