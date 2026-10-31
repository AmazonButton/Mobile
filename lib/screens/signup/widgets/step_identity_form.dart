import '../../../widgets/auth_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/utils.dart';
import 'signup_theme.dart';
import 'signup_ui_components.dart';

/// Step 1: Resident Identity form collecting Full Name and Vietnamese Mobile Phone.
class StepIdentityForm extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final void Function(String name, String phone) onContinue;
  final bool isLoading;

  const StepIdentityForm({
    super.key,
    this.initialName = 'Minh',
    this.initialPhone = '0912345123',
    required this.onContinue,
    this.isLoading = false,
  });

  @override
  State<StepIdentityForm> createState() => _StepIdentityFormState();
}

class _StepIdentityFormState extends State<StepIdentityForm> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);

    _fullNameController.addListener(_validateInputs);
    _phoneController.addListener(_validateInputs);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _validateInputs() {
    final name = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isNotEmpty && name.length < 2) {
      _nameError = 'Họ và tên tối thiểu 2 ký tự';
    } else {
      _nameError = null;
    }

    if (phone.isNotEmpty) {
      _phoneError = PhoneValidator.validate(phone);
    } else {
      _phoneError = null;
    }
    setState(() {});
  }

  bool get _isFormValid {
    final name = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    return name.length >= 2 && PhoneValidator.isValid(phone);
  }

  void _handleSubmit() {
    if (!_isFormValid || widget.isLoading) return;
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    widget.onContinue(
      _fullNameController.text.trim(),
      _phoneController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Mascot
          AuthGuide(
            message: 'Cho mình biết tên và số điện thoại của bạn nhé!',
            mood: widget.isLoading ? GuideMood.waiting : GuideMood.guiding,
          ),
          const SizedBox(height: 24),

          const Text(
            'Bạn tên là gì?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chúng mình sẽ dùng tên này để chào bạn.',
            style: TextStyle(
              fontSize: 15,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 24),

          // Field: Full Name
          const Text(
            'Họ và tên',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fullNameController,
            focusNode: _fullNameFocus,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: SignupTheme.figmaDark,
              fontFamily: SignupTheme.fontFamily,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập họ và tên',
              hintStyle: const TextStyle(
                color: SignupTheme.figmaMuted,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: SignupTheme.figmaInputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: SignupTheme.figmaBorder,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _nameError != null
                      ? SignupTheme.figmaDanger
                      : SignupTheme.figmaBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: SignupTheme.figmaBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          if (_nameError != null) ...[
            const SizedBox(height: 6),
            Text(
              _nameError!,
              style: const TextStyle(
                color: SignupTheme.figmaDanger,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Field: Phone
          const Text(
            'Số điện thoại',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SignupTheme.figmaMuted,
              fontFamily: SignupTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: SignupTheme.figmaDark,
              letterSpacing: 1.1,
              fontFamily: SignupTheme.fontFamily,
            ),
            decoration: InputDecoration(
              hintText: '0912 345 123',
              hintStyle: const TextStyle(
                color: SignupTheme.figmaMuted,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: SignupTheme.figmaInputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: SignupTheme.figmaBorder,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _phoneError != null
                      ? SignupTheme.figmaDanger
                      : SignupTheme.figmaBorder,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: SignupTheme.figmaBlue,
                  width: 2,
                ),
              ),
            ),
          ),
          if (_phoneError != null) ...[
            const SizedBox(height: 6),
            Text(
              _phoneError!,
              style: const TextStyle(
                color: SignupTheme.figmaDanger,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Primary Button
          SignupPrimaryButton(
            label: widget.isLoading ? 'Đang gửi mã...' : 'Gửi mã xác nhận',
            isEnabled: _isFormValid && !widget.isLoading,
            isLoading: widget.isLoading,
            onTap: _handleSubmit,
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Bằng việc tiếp tục, bạn đồng ý với Điều khoản và Chính sách bảo mật.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: SignupTheme.figmaMuted,
                fontFamily: SignupTheme.fontFamily,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
