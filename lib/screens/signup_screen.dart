import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  bool _isSubmitting = false;

  // Design Tokens (Màu sắc chuẩn SmartOrderButton)
  static const Color primaryBlue = Color(0xFF1D5B9F);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color textDark = Color(0xFF102A43);
  static const Color textMuted = Color(0xFF627D98);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputBg = Color(0xFFF9FAFB);

  static final RegExp _strictEmailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+([.-][a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _fullNameFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryLight,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: primaryBlue,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hoàn thành Bước 1!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thông tin cá nhân của ${_fullNameController.text.trim()} đã được ghi nhận. Vui lòng thiết lập mật khẩu ở Bước 2.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // đóng modal
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang khởi tạo Bước 2: Thiết lập bảo mật...'),
                        backgroundColor: primaryBlue,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Tiếp tục Bước 2 →',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Chạm ra ngoài để ẩn bàn phím
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true, // Tránh vỡ giao diện khi mở bàn phím
        body: SafeArea(
          child: Column(
            children: [
              // Khối trang trí màu xanh cực nhạt trên cùng
              Container(
                height: 4,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE3F2FD), primaryBlue, Color(0xFFF5862B)],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // ── Top Bar (Back Button & Nút Đăng nhập) ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderLight),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: textDark,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                tooltip: 'Quay lại',
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Đã có tài khoản? ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textMuted,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Header Area (Tiêu đề & Step Indicator 1/2) ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Tạo tài khoản',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Thông tin cơ bản',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Thẻ Step Indicator ("Bước 1/2")
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryBlue.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.layers_outlined,
                                    size: 15,
                                    color: primaryBlue,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Bước 1/2',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Section Vai trò (Chip nhỏ gọn: "Vai trò: Khách hàng") ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryBlue.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.badge_outlined,
                                size: 16,
                                color: primaryBlue,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Vai trò: Khách hàng',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Form Header Label ──
                        const Text(
                          'THÔNG TIN CÁ NHÂN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF829AB1),
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Input 1: Họ và tên ──
                        _buildInputField(
                          controller: _fullNameController,
                          focusNode: _fullNameFocus,
                          labelText: 'Họ và tên *',
                          hintText: 'Nhập họ và tên đầy đủ',
                          icon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập họ và tên';
                            }
                            if (value.trim().length < 2) {
                              return 'Họ và tên tối thiểu 2 ký tự';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // ── Input 2: Số điện thoại ──
                        _buildInputField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          labelText: 'Số điện thoại *',
                          hintText: 'VD: 0912 345 678',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            final raw = value.trim();
                            if (!raw.startsWith('0')) {
                              return 'Số điện thoại phải bắt đầu bằng số 0';
                            }
                            if (!RegExp(r'^0\d{9}$').hasMatch(raw)) {
                              return 'Số điện thoại phải gồm đúng 10 chữ số';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // ── Input 3: Email ──
                        _buildInputField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          labelText: 'Địa chỉ Email *',
                          hintText: 'VD: example@domain.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập địa chỉ email';
                            }
                            final raw = value.trim();
                            if (!_strictEmailRegex.hasMatch(raw) ||
                                raw.contains('@.') ||
                                raw.startsWith('@') ||
                                raw.contains('..')) {
                              return 'Email không hợp lệ (VD: name@domain.com)';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // ── Nút Submit "Tiếp theo →" (Chuẩn h-14 56px, bo góc 16) ──
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withValues(alpha: 0.28),
                                blurRadius: 18,
                                offset: const Offset(0, 7),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleNextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  primaryBlue.withValues(alpha: 0.4),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Tiếp theo',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Footer: "Đã có tài khoản? Đăng nhập" ──
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Đã có tài khoản? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textMuted,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),
                      ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final isFocused = focusNode.hasFocus;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          fontSize: 14,
          color: isFocused ? primaryBlue : textMuted,
          fontWeight: isFocused ? FontWeight.w600 : FontWeight.w400,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF9FB3C8),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          size: 22,
          color: isFocused ? primaryBlue : const Color(0xFF9FB3C8),
        ),
        filled: true,
        fillColor: isFocused ? Colors.white : inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18, // Đạt chiều cao chuẩn ~56px
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: borderLight,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.8,
          ),
        ),
      ),
    );
  }
}
