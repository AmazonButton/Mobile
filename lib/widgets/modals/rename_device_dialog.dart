import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class RenameDeviceDialog extends StatefulWidget {
  final String initialName;
  final Future<void> Function(String name) onSave;

  const RenameDeviceDialog({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  @override
  State<RenameDeviceDialog> createState() => _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends State<RenameDeviceDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final name = _controller.text.trim();
    if (name == widget.initialName) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(name);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is ApiException
            ? error.message
            : 'Không thể đổi tên nút. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Đổi tên nút'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: const ValueKey('deviceNameInput'),
                controller: _controller,
                autofocus: true,
                enabled: !_saving,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Tên nút',
                  hintText: 'Ví dụ: Nút nước phòng khách',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tên nút'
                    : value.trim().length > 100
                    ? 'Tên nút tối đa 100 ký tự'
                    : null,
                onFieldSubmitted: (_) => _save(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('saveDeviceName'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Đang lưu…' : 'Lưu'),
        ),
      ],
    ),
  );
}
