import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/api_client.dart';
import '../utils/validators.dart';

class ForgotInfoScreen extends StatefulWidget {
  const ForgotInfoScreen({super.key});
  @override
  State<ForgotInfoScreen> createState() => _ForgotInfoScreenState();
}

class _ForgotInfoScreenState extends State<ForgotInfoScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _auth = AuthApiService();
  Timer? _resendTimer;
  int _resendSeconds = 0;
  bool _sent = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (_busy || (resend && _resendSeconds > 0)) return;
    if (!resend && !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.forgotPassword(_email.text.trim().toLowerCase());
      if (!mounted) return;
      _otp.clear();
      setState(() {
        _sent = true;
        _startResendCooldown();
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể gửi yêu cầu. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.length < 8 ||
        !RegExp(r'[a-z]').hasMatch(text) ||
        !RegExp(r'[A-Z]').hasMatch(text) ||
        !RegExp(r'\d').hasMatch(text) ||
        !RegExp(r'[@$!%*?&#^()_+\-=\[\]{}|;:,.<>~`]').hasMatch(text)) {
      return 'Cần ít nhất 8 ký tự, chữ hoa, chữ thường, số và ký tự đặc biệt';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.resetPassword(
        email: _email.text,
        token: _otp.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã đặt lại mật khẩu. Vui lòng đăng nhập bằng mật khẩu mới.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể đặt lại mật khẩu. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(title: const Text('Khôi phục mật khẩu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset_rounded,
                  size: 72,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 24),
                Text(
                  _sent ? 'Đặt mật khẩu mới' : 'Quên mật khẩu?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  _sent
                      ? 'Nếu email tồn tại trong hệ thống, hướng dẫn và mã xác thực đã được gửi. Kiểm tra cả thư rác. Mã có hiệu lực 15 phút.'
                      : 'Nhập email đã đăng ký để nhận mã đặt lại mật khẩu. Nếu đăng nhập bằng số điện thoại, hãy dùng đăng nhập OTP ở màn đăng nhập.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('recovery-email'),
                  controller: _email,
                  readOnly: _sent || _busy,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email đã đăng ký',
                  ),
                  validator: (value) =>
                      EmailValidator.validate(value, allowUsername: false),
                ),
                if (_sent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('recovery-otp'),
                    controller: _otp,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    decoration: const InputDecoration(
                      labelText: 'Mã xác thực 6 số',
                    ),
                    validator: (value) =>
                        RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                        ? null
                        : 'Vui lòng nhập mã xác thực gồm 6 số',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('recovery-password'),
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _hidePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      errorMaxLines: 3,
                      suffixIcon: IconButton(
                        tooltip: _hidePassword
                            ? 'Hiện mật khẩu'
                            : 'Ẩn mật khẩu',
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('recovery-confirmation'),
                    controller: _confirmation,
                    enabled: !_busy,
                    obscureText: _hidePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu mới',
                    ),
                    validator: (value) => value == _password.text
                        ? null
                        : 'Mật khẩu nhập lại không khớp',
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : (_sent ? _resetPassword : () => _sendCode()),
                  child: Text(
                    _busy
                        ? 'Đang xử lý...'
                        : (_sent ? 'Đặt lại mật khẩu' : 'Gửi mã xác thực'),
                  ),
                ),
                if (_sent) ...[
                  TextButton(
                    onPressed: _busy || _resendSeconds > 0
                        ? null
                        : () => _sendCode(resend: true),
                    child: Text(
                      _resendSeconds > 0
                          ? 'Gửi lại sau ${_resendSeconds}s'
                          : 'Gửi lại mã',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            _resendTimer?.cancel();
                            _otp.clear();
                            _password.clear();
                            _confirmation.clear();
                            setState(() {
                              _sent = false;
                              _error = null;
                            });
                          },
                    child: const Text('Dùng email khác'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
