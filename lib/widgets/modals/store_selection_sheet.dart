import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/devices_api_service.dart';
import '../../services/stores_api_service.dart';
import '../../screens/login_screen.dart';

class StoreSelectionSheet extends StatefulWidget {
  final String deviceId;
  final Future<void> Function(String storeId) onSave;

  const StoreSelectionSheet({
    super.key,
    required this.deviceId,
    required this.onSave,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String deviceId,
    required Future<void> Function(String storeId) onSave,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => StoreSelectionSheet(deviceId: deviceId, onSave: onSave),
  );

  @override
  State<StoreSelectionSheet> createState() => _StoreSelectionSheetState();
}

class _StoreSelectionSheetState extends State<StoreSelectionSheet> {
  List<Map<String, dynamic>> _stores = [];
  String? _currentStoreId;
  String? _selectedStoreId;
  String _search = '';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _saveError;
  bool _needsLogin = false;

  static const _sessionMessage =
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để đổi cửa hàng.';

  void _openLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _needsLogin = false;
    });
    try {
      final results = await Future.wait<dynamic>([
        DevicesApiService().getDeviceById(widget.deviceId),
        StoresApiService().getStores(),
      ]);
      if (!mounted) return;
      final device = results[0] as Map<String, dynamic>;
      final stores = (results[1] as List)
          .whereType<Map>()
          .where((s) => s['status'] == 'ACTIVE')
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
      setState(() {
        _stores = stores;
        _currentStoreId = device['storeId']?.toString();
        _selectedStoreId = _currentStoreId;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _needsLogin = error is ApiException && error.statusCode == 401;
        _loadError = _needsLogin
            ? _sessionMessage
            : error is ApiException && error.statusCode == 403
            ? 'Bạn không có quyền cấu hình nút này.'
            : error is ApiException && error.statusCode == 404
            ? 'Không tìm thấy thiết bị. Vui lòng tải lại danh sách nút.'
            : 'Không thể tải cửa hàng. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _save() async {
    final storeId = _selectedStoreId;
    if (_saving || storeId == null || storeId == _currentStoreId) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(storeId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (error is ApiException && error.statusCode == 401) {
          _needsLogin = true;
          _loadError = _sessionMessage;
          return;
        }
        _saveError = error is ApiException
            ? error.message
            : 'Không thể đổi cửa hàng. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _stores.where(
      (s) => '${s['name']} ${s['address'] ?? ''} ${s['code'] ?? ''}'
          .toLowerCase()
          .contains(_search),
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Đổi cửa hàng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Đổi cửa hàng sẽ bỏ sản phẩm đang gán. Bạn cần chọn lại sản phẩm của cửa hàng mới.',
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: !_saving,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm cửa hàng, địa chỉ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    setState(() => _search = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_loadError!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: _needsLogin ? _openLogin : _load,
                              child: Text(
                                _needsLogin ? 'Đăng nhập lại' : 'Thử lại',
                              ),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                    ? const Center(
                        child: Text('Không tìm thấy cửa hàng đang hoạt động'),
                      )
                    : ListView(
                        children: filtered.map((store) {
                          final id = store['storeId'].toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.storefront_outlined),
                            title: Text(
                              store['name']?.toString() ?? 'Cửa hàng',
                            ),
                            subtitle: Text(
                              [
                                if (id == _currentStoreId) 'Cửa hàng hiện tại',
                                if (store['address'] != null)
                                  store['address'].toString(),
                              ].join(' • '),
                            ),
                            trailing: Icon(
                              id == _selectedStoreId
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                            ),
                            onTap: _saving
                                ? null
                                : () => setState(() {
                                    _selectedStoreId = id;
                                    _saveError = null;
                                  }),
                          );
                        }).toList(),
                      ),
              ),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _saveError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              FilledButton(
                onPressed:
                    _loading ||
                        _saving ||
                        _loadError != null ||
                        _selectedStoreId == null ||
                        _selectedStoreId == _currentStoreId
                    ? null
                    : _save,
                child: Text(_saving ? 'Đang đổi cửa hàng...' : 'Lưu cửa hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
