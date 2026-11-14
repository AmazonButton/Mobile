import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/device_provider.dart';
import '../../services/devices_api_service.dart';
import '../../services/api_client.dart';
import '../sample_a.dart';
import '../smart_order_tour.dart';

class ConnectDeviceSheet extends StatefulWidget {
  const ConnectDeviceSheet({super.key, this.tour});
  final SmartOrderTour? tour;

  static Future<bool?> showAndRefresh(
    BuildContext context, {
    SmartOrderTour? tour,
  }) async {
    final provider = context.read<DeviceProvider?>();
    final saved = await show(context, tour: tour);
    if (saved == true && context.mounted) {
      await provider?.refreshDevices();
    }
    return saved;
  }

  static Future<bool?> show(BuildContext context, {SmartOrderTour? tour}) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => ConnectDeviceSheet(tour: tour),
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
    widget.tour?.setBusy(true);
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
      widget.tour?.setBusy(false);
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
    child: ASheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: ABuddy()),
          const SizedBox(height: 16),
          const Text('Kết nối thiết bị', style: SampleA.title),
          const SizedBox(height: 16),
          TextField(
            key: widget.tour?.key(TourStep.code),
            controller: _code,
            onChanged: (value) => widget.tour?.codeChanged(value),
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
          AButton(
            key: widget.tour?.key(TourStep.connect),
            label: 'Kết nối',
            onPressed: _connect,
            busy: _busy,
          ),
        ],
      ),
    ),
  );
}
