import 'package:flutter/material.dart';
import '../../services/devices_api_service.dart';
import '../../services/api_client.dart';
import '../sample_a.dart';

class ConnectDeviceSheet extends StatefulWidget {
  const ConnectDeviceSheet({super.key});
  static Future<bool?> show(BuildContext context) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const ConnectDeviceSheet(),
  );
  @override
  State<ConnectDeviceSheet> createState() => _ConnectDeviceSheetState();
}

class _ConnectDeviceSheetState extends State<ConnectDeviceSheet> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Nhập mã kết nối trên thiết bị.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final lookup = await DevicesApiService().lookupCode(code);
      if (lookup['isClaimed'] != true) {
        throw StateError(
          'Thiết bị chưa được gán cho tài khoản. Vui lòng liên hệ cửa hàng để kích hoạt.',
        );
      }
      final id = lookup['deviceId']?.toString();
      if (id == null || id.isEmpty) {
        throw StateError('Mã thiết bị không hợp lệ.');
      }
      await DevicesApiService().getDeviceModelById(id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is ApiException
              ? e.message
              : e is StateError
              ? e.message.toString()
              : 'Không thể kết nối thiết bị. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: ABuddy()),
            const SizedBox(height: 16),
            const Text('Kết nối thiết bị', style: SampleA.title),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _connect(),
              decoration: InputDecoration(
                labelText: 'Mã kết nối / mã QR',
                errorText: _error,
                errorMaxLines: 3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AButton(label: 'Kết nối', onPressed: _connect, busy: _busy),
          ],
        ),
      ),
    ),
  );
}
