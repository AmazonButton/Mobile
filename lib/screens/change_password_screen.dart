import 'package:flutter/material.dart';
import '../widgets/resident_ui.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_api_service.dart';
import '../services/api_client.dart';
import '../services/user_profile_service.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _saveErrorKey = GlobalKey();
  final _current = TextEditingController(),
      _next = TextEditingController(),
      _confirm = TextEditingController();
  final _hidden = [true, true, true];
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Map<String, bool> _passwordRules(String text) => {
    'Ít nhất 8 ký tự': text.length >= 8,
    'Chữ hoa và chữ thường':
        RegExp(r'[a-z]').hasMatch(text) && RegExp(r'[A-Z]').hasMatch(text),
    'Một chữ số': RegExp(r'\d').hasMatch(text),
    'Một ký tự đặc biệt': RegExp(
      r'[@$!%*?&#^()_+\-=\[\]{}|;:,.<>~`]',
    ).hasMatch(text),
  };

  String? _validateNew(String? value) {
    final text = value ?? '';
    if (_passwordRules(text).containsValue(false)) {
      return 'Cần ít nhất 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt.';
    }
    if (text == _current.text) {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final invalidFields = _form.currentState!.validateGranularly();
    if (invalidFields.isNotEmpty) {
      _reveal(
        () => invalidFields.first.mounted ? invalidFields.first.context : null,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthApiService().changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      _current.clear();
      _next.clear();
      _confirm.clear();
      if (!mounted) return;
      try {
        context.read<UserProvider>().reset();
      } on ProviderNotFoundException {
        /* Standalone screen. */
      }
      UserProfileService().reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.'),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể đổi mật khẩu. Vui lòng thử lại.',
        );
        _reveal(() => _saveErrorKey.currentContext);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reveal(BuildContext? Function() target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final field = target();
      if (field != null) {
        Scrollable.ensureVisible(
          field,
          duration: const Duration(milliseconds: 220),
        );
      }
    });
  }

  Widget _field(
    String label,
    TextEditingController controller,
    int index,
    String? Function(String?) validator,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('password$index'),
      controller: controller,
      obscureText: _hidden[index],
      enabled: !_busy,
      autocorrect: false,
      enableSuggestions: false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        errorMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: _hidden[index] ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          onPressed: () => setState(() => _hidden[index] = !_hidden[index]),
          icon: Icon(
            _hidden[index]
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: ResidentScaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      actions: [
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Đang lưu…' : 'Lưu mật khẩu mới'),
        ),
      ],
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ResidentHero(
                icon: Icons.lock_outline,
                eyebrow: 'Bảo mật tài khoản',
                title: 'Đổi mật khẩu',
                description: 'Bạn sẽ cần đăng nhập lại sau khi đổi mật khẩu.',
              ),
              _field(
                'Mật khẩu hiện tại',
                _current,
                0,
                (v) => v == null || v.isEmpty
                    ? 'Vui lòng nhập mật khẩu hiện tại.'
                    : null,
              ),
              _field('Mật khẩu mới', _next, 1, _validateNew),
              ValueListenableBuilder(
                valueListenable: _next,
                builder: (context, value, _) => ResidentPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yêu cầu mật khẩu',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      for (final rule in _passwordRules(value.text).entries)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                rule.value
                                    ? Icons.check_circle_outline
                                    : Icons.radio_button_unchecked,
                                size: 17,
                                color: rule.value
                                    ? const Color(0xFF166534)
                                    : residentMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(rule.key)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _field(
                'Nhập lại mật khẩu mới',
                _confirm,
                2,
                (v) => v != _next.text ? 'Mật khẩu nhập lại chưa khớp.' : null,
              ),
              if (_error != null)
                ResidentNotice(_error!, key: _saveErrorKey, error: true),
              const ResidentNotice(
                'Nếu chưa có mật khẩu, hãy dùng Google hoặc OTP. Bạn có thể chọn Quên mật khẩu nếu tài khoản đã có email.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
