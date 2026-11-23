import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/api_client.dart';
import '../../services/system_staff_api_service.dart';
import '../../widgets/sample_a.dart';

/// Màn hình Kho nút bấm, Cấp phát cửa hàng & Mẫu thiết bị dành riêng cho SYSTEM_STAFF.
class SystemStaffDevicesScreen extends StatefulWidget {
  final int initialSubTab;

  const SystemStaffDevicesScreen({super.key, this.initialSubTab = 0});

  @override
  State<SystemStaffDevicesScreen> createState() =>
      _SystemStaffDevicesScreenState();
}

class _SystemStaffDevicesScreenState extends State<SystemStaffDevicesScreen> {
  final _api = SystemStaffApiService();

  late int _subTab = widget.initialSubTab; // 0: Kho nút, 1: Cấp phát, 2: Mẫu nút
  List<Map<String, dynamic>> _stores = [];
  Map<String, dynamic> _fleetStats = {};

  // Sub-tab 0: Devices
  List<Map<String, dynamic>> _devices = [];
  bool _loadingDevices = true;
  String _search = '';
  String _custodyStoreFilter = '';
  String _inventoryStateFilter = '';
  bool _allocatedOnly = false;
  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  // Sub-tab 1: Unassigned & Store Inventory
  List<Map<String, dynamic>> _unassigned = [];
  bool _loadingUnassigned = false;
  String _unassignedSearch = '';
  final Set<String> _selectedAllocateIds = {};
  String _inspectStoreId = '';
  Map<String, dynamic>? _storeInventory;

  // Sub-tab 2: Templates
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _products = [];
  bool _loadingTemplates = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadStores(),
      _loadFleetStats(),
      _loadDevices(),
    ]);
  }

  Future<void> _loadStores() async {
    try {
      final list = await _api.listStores();
      if (!mounted) return;
      setState(() {
        _stores = list;
        if (_inspectStoreId.isEmpty && list.isNotEmpty) {
          _inspectStoreId = (list.first['storeId'] ?? list.first['id'] ?? '').toString();
        }
      });
    } catch (_) {}
  }

  Future<void> _loadFleetStats() async {
    try {
      final stats = await _api.getFleetStats();
      if (mounted) setState(() => _fleetStats = stats);
    } catch (_) {}
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;
    setState(() => _loadingDevices = true);
    try {
      final res = await _api.listDevices(
        page: _page,
        pageSize: 20,
        search: _search,
        custodyStoreId: _custodyStoreFilter,
        inventoryState: _inventoryStateFilter,
        allocatedOnly: _allocatedOnly,
      );
      if (!mounted) return;
      setState(() {
        _devices = res.items;
        _totalItems = int.tryParse((res.pagination['totalItems'] ?? res.pagination['total'] ?? res.items.length).toString()) ?? res.items.length;
        _totalPages = (int.tryParse((res.pagination['totalPages'] ?? 1).toString()) ?? 1).clamp(1, 999);
        _loadingDevices = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDevices = false);
        _snack(e is ApiException ? e.message : 'Không tải được kho nút.', error: true);
      }
    }
  }

  Future<void> _loadUnassigned() async {
    if (!mounted) return;
    setState(() => _loadingUnassigned = true);
    try {
      final res = await _api.listUnassignedDevices(
        page: 1,
        pageSize: 40,
        search: _unassignedSearch,
      );
      if (!mounted) return;
      setState(() {
        _unassigned = res.items;
        _loadingUnassigned = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingUnassigned = false);
        _snack(e is ApiException ? e.message : 'Không tải được nút chưa cấp phát.', error: true);
      }
    }
    if (_inspectStoreId.isNotEmpty) {
      await _loadStoreInventory(_inspectStoreId);
    }
  }

  Future<void> _loadStoreInventory(String storeId) async {
    try {
      final inv = await _api.getStoreInventory(storeId);
      if (mounted) setState(() => _storeInventory = inv);
    } catch (_) {}
  }

  Future<void> _loadTemplates() async {
    if (!mounted) return;
    setState(() => _loadingTemplates = true);
    try {
      final results = await Future.wait([
        _api.listTemplates(),
        _api.listProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        _templates = results[0];
        _products = results[1];
        _loadingTemplates = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTemplates = false);
        _snack(e is ApiException ? e.message : 'Không tải được mẫu cấu hình.', error: true);
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFF0E6BA8),
        content: Text(msg),
      ),
    );
  }

  String _storeName(dynamic id, [dynamic embedded]) {
    if (embedded is Map) {
      final n = embedded['name'] ?? embedded['storeName'];
      if (n != null && n.toString().isNotEmpty) return n.toString();
    }
    if (id == null || id.toString().isEmpty) return 'Kho tổng';
    final s = _stores.where((x) => (x['storeId'] ?? x['id']).toString() == id.toString()).firstOrNull;
    return (s?['name'] ?? s?['storeName'] ?? 'CH #$id').toString();
  }

  Future<void> _switchSubTab(int tab) async {
    setState(() => _subTab = tab);
    if (tab == 0) await _loadDevices();
    if (tab == 1) await _loadUnassigned();
    if (tab == 2) await _loadTemplates();
  }

  // ==================== DIALOGS ====================

  Future<void> _showBatchGenerateDialog() async {
    final prefixCtrl = TextEditingController(text: 'SOB');
    final countCtrl = TextEditingController(text: '10');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sinh mã nút theo lô', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: prefixCtrl, decoration: const InputDecoration(labelText: 'Tiền tố (Prefix)')),
            const SizedBox(height: 10),
            TextField(
              controller: countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số lượng (1–100)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sinh lô')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final count = (int.tryParse(countCtrl.text) ?? 10).clamp(1, 100);
      final res = await _api.batchGenerateDevices(prefix: prefixCtrl.text, count: count);
      _snack(res['message']?.toString() ?? 'Sinh lô nút thành công!');
      _loadFleetStats();
      _subTab == 1 ? _loadUnassigned() : _loadDevices();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Sinh lô thất bại.', error: true);
    }
  }

  Future<void> _showRegisterDialog() async {
    final devIdCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final macCtrl = TextEditingController();
    String selectedStore = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Đăng ký nút mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: devIdCtrl, decoration: const InputDecoration(labelText: 'Device ID (tuỳ chọn)')),
                const SizedBox(height: 8),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên gợi nhớ')),
                const SizedBox(height: 8),
                TextField(controller: macCtrl, decoration: const InputDecoration(labelText: 'MAC Address (tuỳ chọn)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedStore,
                  decoration: const InputDecoration(labelText: 'Cửa hàng (tuỳ chọn)'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Giữ tại kho tổng')),
                    ..._stores.map((s) {
                      final id = (s['storeId'] ?? s['id']).toString();
                      return DropdownMenuItem(value: id, child: Text((s['name'] ?? 'CH #$id').toString(), overflow: TextOverflow.ellipsis));
                    }),
                  ],
                  onChanged: (v) => setLocal(() => selectedStore = v ?? ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng ký')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final res = await _api.registerDevice({
        if (devIdCtrl.text.trim().isNotEmpty) 'deviceId': devIdCtrl.text.trim(),
        if (nameCtrl.text.trim().isNotEmpty) 'customName': nameCtrl.text.trim(),
        if (macCtrl.text.trim().isNotEmpty) 'macAddress': macCtrl.text.trim(),
        if (selectedStore.isNotEmpty) 'storeId': selectedStore,
      });
      _snack(res['message']?.toString() ?? 'Đăng ký nút thành công!');
      _loadFleetStats();
      _loadDevices();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Đăng ký thất bại.', error: true);
    }
  }

  Future<void> _showBulkImportDialog() async {
    final textCtrl = TextEditingController(text: 'SOB-M-001,SN-M-001,Nút mẫu 1\nSOB-M-002,SN-M-002,Nút mẫu 2');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập hàng loạt (CSV)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mỗi dòng: deviceId,serialNumber,customName', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            TextField(controller: textCtrl, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Nhập ngay')),
        ],
      ),
    );
    if (ok != true) return;
    final rows = textCtrl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) {
          final p = l.split(',').map((e) => e.trim()).toList();
          return <String, dynamic>{
            if (p.isNotEmpty && p[0].isNotEmpty) 'deviceId': p[0],
            if (p.length > 1 && p[1].isNotEmpty) 'serialNumber': p[1],
            if (p.length > 2 && p[2].isNotEmpty) 'customName': p[2],
          };
        })
        .toList();
    if (rows.isEmpty) return;
    try {
      final res = await _api.bulkImportDevices(rows: rows);
      _snack(res['message']?.toString() ?? 'Đã nhập ${rows.length} nút!');
      _loadFleetStats();
      _loadDevices();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Nhập hàng loạt thất bại.', error: true);
    }
  }

  Future<void> _showLookupDialog() async {
    final codeCtrl = TextEditingController();
    Map<String, dynamic>? result;
    String? err;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tra mã nút', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Device ID / PIN 6 số / QR')),
              const SizedBox(height: 10),
              if (err != null) Text(err!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
              if (result != null) ...[
                Text('Device ID: ${result!['deviceId']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Trạng thái: ${result!['status']}'),
                Text('Đã gắn khách: ${result!['isClaimed'] == true ? 'Có' : 'Chưa'}'),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            FilledButton(
              onPressed: () async {
                try {
                  final r = await _api.lookupCode(codeCtrl.text);
                  setLocal(() {
                    result = r;
                    err = null;
                  });
                } catch (e) {
                  setLocal(() {
                    result = null;
                    err = e is ApiException ? e.message : 'Không tìm thấy thiết bị.';
                  });
                }
              },
              child: const Text('Tra cứu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAllocateDialog() async {
    if (_selectedAllocateIds.isEmpty) return;
    String targetStore = _stores.isNotEmpty ? (_stores.first['storeId'] ?? _stores.first['id']).toString() : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Cấp phát ${_selectedAllocateIds.length} nút', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chuyển nút về kho cửa hàng (custodyStoreId); giữ riêng storeId định tuyến đơn.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: targetStore.isEmpty ? null : targetStore,
                decoration: const InputDecoration(labelText: 'Cửa hàng nhận nút'),
                items: _stores.map((s) {
                  final id = (s['storeId'] ?? s['id']).toString();
                  return DropdownMenuItem(value: id, child: Text((s['name'] ?? 'CH #$id').toString(), overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setLocal(() => targetStore = v ?? ''),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
          ],
        ),
      ),
    );
    if (ok != true || targetStore.isEmpty) return;
    try {
      final res = await _api.allocateToStore(
        storeId: targetStore,
        deviceIds: _selectedAllocateIds.toList(),
      );
      _snack(res['message']?.toString() ?? 'Cấp phát nút thành công!');
      _selectedAllocateIds.clear();
      await _loadUnassigned();
      await _loadDevices();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Cấp phát thất bại.', error: true);
    }
  }

  /// BottomSheet vận hành đầy đủ 1 thiết bị
  Future<void> _showDeviceOpsSheet(Map<String, dynamic> dev) async {
    final devId = (dev['deviceId'] ?? dev['id'] ?? '').toString();
    if (_products.isEmpty) {
      try {
        final list = await _api.listProducts();
        if (mounted) setState(() => _products = list);
      } catch (_) {}
    }
    if (!mounted) return;
    final batteryCtrl = TextEditingController(text: (dev['batteryLevel'] ?? 100).toString());
    final warrantyCtrl = TextEditingController(text: '12');
    final wifiSsidCtrl = TextEditingController();
    final wifiPassCtrl = TextEditingController();
    final holdCtrl = TextEditingController(text: (dev['holdDurationMs'] ?? 2000).toString());
    final pairCodeCtrl = TextEditingController(text: (dev['pairingCode'] ?? '').toString());
    final assignCustCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: (dev['quantity'] ?? 1).toString());
    String assignStoreVal = (dev['storeId'] ?? '').toString();
    if (assignStoreVal.isNotEmpty &&
        !_stores.any((s) => (s['storeId'] ?? s['id']).toString() == assignStoreVal)) {
      assignStoreVal = '';
    }
    String selectedProductVal = (dev['productId'] ?? '').toString();
    if (selectedProductVal.isNotEmpty &&
        !_products.any((p) => (p['productId'] ?? p['id']).toString() == selectedProductVal)) {
      selectedProductVal = '';
    }
    String behavior = (dev['clickBehavior'] ?? 'SINGLE').toString();
    String statusVal = (dev['status'] ?? 'ACTIVE').toString();
    if (!['ACTIVE', 'INACTIVE', 'LOCKED', 'SUSPENDED', 'UNASSIGNED', 'MAINTENANCE'].contains(statusVal)) {
      statusVal = 'ACTIVE';
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vận hành: $devId', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          'Kho giữ: ${_storeName(dev['custodyStoreId'], dev['custodyStore'])} • Định tuyến: ${_storeName(dev['storeId'], dev['store'])}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(LucideIcons.x)),
                ],
              ),
              const Divider(height: 20),

              // 1. Bật / tắt / trạng thái
              const Text('Trạng thái & Kích hoạt', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await _api.enableDevice(devId);
                        _snack('Đã bật nút $devId');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi bật nút', error: true);
                      }
                    },
                    icon: const Icon(LucideIcons.power, size: 15),
                    label: const Text('Bật nút'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await _api.disableDevice(devId);
                        _snack('Đã tắt nút $devId');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi tắt nút', error: true);
                      }
                    },
                    icon: const Icon(LucideIcons.powerOff, size: 15),
                    label: const Text('Tắt nút'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final res = await _api.repairDevice(devId);
                        final d = res['data'] ?? res;
                        _snack('Đã tạo lại QR/Code: ${d['pairingCode'] ?? 'OK'}');
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi re-pair', error: true);
                      }
                    },
                    icon: const Icon(LucideIcons.qrCode, size: 15),
                    label: const Text('Re-pair QR'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await _api.removeProduct(devId);
                        _snack('Đã gỡ sản phẩm khỏi $devId');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi gỡ sản phẩm', error: true);
                      }
                    },
                    icon: const Icon(LucideIcons.packageX, size: 15),
                    label: const Text('Gỡ SP'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final next = statusVal == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
                      try {
                        await _api.toggleActive(devId, next);
                        setLocal(() => statusVal = next);
                        _snack('Đã chuyển toggle-active → $next');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi toggle-active', error: true);
                      }
                    },
                    icon: const Icon(LucideIcons.toggleRight, size: 15),
                    label: const Text('Toggle Active'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Ghép nối (Pair / Claim) & Gán cửa hàng / Khách', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pairCodeCtrl,
                      decoration: const InputDecoration(labelText: 'Mã ghép / Claim code', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () async {
                      if (pairCodeCtrl.text.trim().isEmpty) return;
                      try {
                        await _api.pairDevice(devId, pairCodeCtrl.text);
                        _snack('Ghép nối (pair) thành công!');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi pair', error: true);
                      }
                    },
                    child: const Text('Pair'),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () async {
                      if (pairCodeCtrl.text.trim().isEmpty) return;
                      try {
                        await _api.claimDevice(devId, pairCodeCtrl.text);
                        _snack('Kích hoạt (claim) thành công!');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi claim', error: true);
                      }
                    },
                    child: const Text('Claim'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: assignStoreVal,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Store định tuyến (assign)', isDense: true),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('-- Giữ nguyên --')),
                        ..._stores.map((s) {
                          final sid = (s['storeId'] ?? s['id']).toString();
                          return DropdownMenuItem(value: sid, child: Text((s['name'] ?? 'CH #$sid').toString(), overflow: TextOverflow.ellipsis));
                        }),
                      ],
                      onChanged: (v) => setLocal(() => assignStoreVal = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: assignCustCtrl,
                      decoration: const InputDecoration(labelText: 'Cust ID', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () async {
                      if (assignStoreVal.isEmpty && assignCustCtrl.text.trim().isEmpty) return;
                      try {
                        await _api.assignDevice(
                          devId,
                          storeId: assignStoreVal.isEmpty ? null : assignStoreVal,
                          customerId: assignCustCtrl.text.trim().isEmpty ? null : assignCustCtrl.text.trim(),
                        );
                        _snack('Đã gán nút (assign) thành công!');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi assign', error: true);
                      }
                    },
                    child: const Text('Gán'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Gán sản phẩm cho nút (assign-product)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedProductVal,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Chọn sản phẩm', isDense: true),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('-- Chọn SP --')),
                        ..._products.map((p) {
                          final pid = (p['productId'] ?? p['id']).toString();
                          return DropdownMenuItem(
                            value: pid,
                            child: Text((p['name'] ?? p['productName'] ?? 'SP #$pid').toString(), overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (v) => setLocal(() => selectedProductVal = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 58,
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'SL', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () async {
                      if (selectedProductVal.isEmpty) return;
                      try {
                        final q = (int.tryParse(qtyCtrl.text) ?? 1).clamp(1, 100);
                        await _api.assignProduct(devId, productId: selectedProductVal, quantity: q);
                        _snack('Đã gán sản phẩm cho $devId');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi gán sản phẩm', error: true);
                      }
                    },
                    child: const Text('Gán SP'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: statusVal,
                      decoration: const InputDecoration(labelText: 'PATCH trạng thái', isDense: true),
                      items: const ['ACTIVE', 'INACTIVE', 'LOCKED', 'SUSPENDED', 'UNASSIGNED', 'MAINTENANCE']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setLocal(() => statusVal = v ?? 'ACTIVE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await _api.updateDeviceStatus(devId, statusVal);
                        _snack('Đã chuyển trạng thái → $statusVal');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi cập nhật trạng thái', error: true);
                      }
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text('Cập nhật Pin & Gia hạn bảo hành', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: batteryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pin (0–100%)', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      try {
                        final lvl = (int.tryParse(batteryCtrl.text) ?? 100).clamp(0, 100);
                        await _api.updateBattery(devId, lvl);
                        _snack('Đã cập nhật pin $lvl%');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi cập nhật pin', error: true);
                      }
                    },
                    child: const Text('Lưu pin'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: warrantyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Gia hạn bảo hành (tháng)', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      try {
                        final m = (int.tryParse(warrantyCtrl.text) ?? 12).clamp(1, 120);
                        await _api.extendWarranty(devId, m);
                        _snack('Đã gia hạn bảo hành +$m tháng');
                        _loadDevices();
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi gia hạn', error: true);
                      }
                    },
                    child: const Text('Gia hạn'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text('Cấu hình hành vi nút (PUT :id/behavior)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: ['SINGLE', 'DOUBLE', 'HOLD'].contains(behavior) ? behavior : 'SINGLE',
                      decoration: const InputDecoration(labelText: 'Kiểu bấm', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'SINGLE', child: Text('SINGLE')),
                        DropdownMenuItem(value: 'DOUBLE', child: Text('DOUBLE')),
                        DropdownMenuItem(value: 'HOLD', child: Text('HOLD')),
                      ],
                      onChanged: (v) => setLocal(() => behavior = v ?? 'SINGLE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: holdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Hold (ms)', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await _api.updateBehavior(
                          devId,
                          clickBehavior: behavior,
                          holdDurationMs: (int.tryParse(holdCtrl.text) ?? 2000).clamp(500, 10000),
                        );
                        _snack('Đã lưu hành vi nút $devId');
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi lưu hành vi', error: true);
                      }
                    },
                    child: const Text('Lưu'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text('Đổi Wi-Fi thiết bị (change-wifi)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: wifiSsidCtrl, decoration: const InputDecoration(labelText: 'SSID', isDense: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: wifiPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu', isDense: true))),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      if (wifiSsidCtrl.text.trim().isEmpty) return;
                      try {
                        await _api.changeWifi(devId, ssid: wifiSsidCtrl.text, password: wifiPassCtrl.text);
                        _snack('Đã gửi đổi Wi-Fi cho $devId');
                      } catch (e) {
                        _snack(e is ApiException ? e.message : 'Lỗi đổi Wi-Fi', error: true);
                      }
                    },
                    child: const Text('Đổi'),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFD97706)),
                      onPressed: () async {
                        try {
                          final tel = await _api.getTelemetry(devId);
                          if (!mounted) return;
                          final latest = tel.isNotEmpty ? tel.first : null;
                          _snack(
                            latest == null
                                ? 'Chưa có bản ghi telemetry.'
                                : 'Telemetry: Pin ${latest['batteryLevel'] ?? '--'}% · RSSI ${latest['wifiRSSI'] ?? '--'} dBm · FW ${latest['firmwareVersion'] ?? '--'}',
                          );
                        } catch (e) {
                          _snack(e is ApiException ? e.message : 'Không tải được telemetry', error: true);
                        }
                      },
                      icon: const Icon(LucideIcons.activity, size: 15),
                      label: const Text('Telemetry'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                      onPressed: () async {
                        try {
                          await _api.factoryReset(devId);
                          if (ctx.mounted) Navigator.pop(ctx);
                          _snack('Đã khôi phục cài đặt gốc $devId');
                          _loadDevices();
                        } catch (e) {
                          _snack(e is ApiException ? e.message : 'Lỗi factory reset', error: true);
                        }
                      },
                      icon: const Icon(LucideIcons.rotateCcw, size: 15),
                      label: const Text('Factory Reset'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                ),
                onPressed: () async {
                  try {
                    await _api.deleteDevice(devId);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _snack('Đã xóa nút $devId');
                    _loadDevices();
                  } catch (e) {
                    _snack(e is ApiException ? e.message : 'Không thể xóa nút', error: true);
                  }
                },
                icon: const Icon(LucideIcons.trash2, size: 15),
                label: const Text('Xóa nút bấm (DELETE :id)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTemplateFormDialog({Map<String, dynamic>? editing}) async {
    final isEdit = editing != null;
    final tmplId = editing != null ? (editing['id'] ?? editing['templateId']).toString() : '';
    final nameCtrl = TextEditingController(text: editing?['name']?.toString() ?? '');
    final descCtrl = TextEditingController(text: editing?['description']?.toString() ?? '');
    String storeId = editing?['storeId']?.toString() ?? '';
    if (storeId.isNotEmpty &&
        !_stores.any((s) => (s['storeId'] ?? s['id']).toString() == storeId)) {
      storeId = '';
    }
    String productId = editing?['defaultProductId']?.toString() ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final storeProducts = _products
              .where((p) => storeId.isNotEmpty && p['storeId']?.toString() == storeId)
              .toList();
          if (productId.isNotEmpty &&
              !storeProducts.any((p) => (p['productId'] ?? p['id']).toString() == productId)) {
            productId = '';
          }
          return AlertDialog(
            title: Text(isEdit ? 'Sửa mẫu thiết bị' : 'Tạo mẫu thiết bị', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên mẫu *')),
                  const SizedBox(height: 8),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: storeId,
                    decoration: const InputDecoration(labelText: 'Phạm vi mẫu'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Dùng chung toàn hệ thống')),
                      ..._stores.map((s) {
                        final id = (s['storeId'] ?? s['id']).toString();
                        return DropdownMenuItem(value: id, child: Text((s['name'] ?? 'CH #$id').toString(), overflow: TextOverflow.ellipsis));
                      }),
                    ],
                    onChanged: isEdit
                        ? null
                        : (v) => setLocal(() {
                            storeId = v ?? '';
                            productId = '';
                          }),
                  ),
                  if (storeId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: productId,
                      decoration: const InputDecoration(labelText: 'Sản phẩm mặc định'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('-- Không gắn cố định --')),
                        ...storeProducts.map((p) {
                          final id = (p['productId'] ?? p['id']).toString();
                          return DropdownMenuItem(value: id, child: Text((p['name'] ?? p['productName'] ?? id).toString(), overflow: TextOverflow.ellipsis));
                        }),
                      ],
                      onChanged: (v) => setLocal(() => productId = v ?? ''),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEdit ? 'Lưu thay đổi' : 'Tạo mẫu')),
            ],
          );
        },
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    try {
      final payload = <String, dynamic>{
        'name': nameCtrl.text.trim(),
        if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
        if (!isEdit && storeId.isNotEmpty) 'storeId': storeId,
        if (storeId.isNotEmpty) 'defaultProductId': productId.isEmpty ? null : productId,
        if (!isEdit) ...{
          'singlePressAction': 'CREATE_ORDER',
          'doublePressAction': 'CANCEL_ORDER',
          'longPressAction': 'WIFI_CONFIGURATION',
          'defaultQuantity': 1,
          'cancelWindowSeconds': 60,
        },
      };
      if (isEdit) {
        await _api.updateTemplate(tmplId, payload);
        _snack('Đã cập nhật mẫu thiết bị!');
      } else {
        await _api.createTemplate(payload);
        _snack('Đã tạo mẫu thiết bị thành công!');
      }
      _loadTemplates();
    } catch (e) {
      _snack(e is ApiException ? e.message : (isEdit ? 'Cập nhật mẫu thất bại.' : 'Tạo mẫu thất bại.'), error: true);
    }
  }

  Future<void> _showDeployTemplateDialog(Map<String, dynamic> tmpl) async {
    final tmplId = (tmpl['id'] ?? tmpl['templateId']).toString();
    final idsCtrl = TextEditingController();
    final prefixCtrl = TextEditingController(text: 'SOB-');
    final startCtrl = TextEditingController(text: '1');
    final endCtrl = TextEditingController(text: '10');
    final padCtrl = TextEditingController(text: '6');
    bool useRange = false;
    Map<String, dynamic>? deployRes;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final rawResults = deployRes?['results'];
          final detailList = rawResults is List ? rawResults.whereType<Map>().toList() : const <Map>[];
          return AlertDialog(
            title: Text('Triển khai: ${tmpl['name']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tối đa 100 nút/lần. BE kiểm tra SP mặc định theo storeId định tuyến (không xét custodyStoreId).',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Danh sách mã', style: TextStyle(fontSize: 11.5)),
                        selected: !useRange,
                        onSelected: (_) => setLocal(() => useRange = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Dải mã', style: TextStyle(fontSize: 11.5)),
                        selected: useRange,
                        onSelected: (_) => setLocal(() => useRange = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!useRange)
                    TextField(
                      controller: idsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'SOB-000001, SOB-000002',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else ...[
                    TextField(controller: prefixCtrl, decoration: const InputDecoration(labelText: 'Tiền tố (Prefix)', isDense: true)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: startCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Từ số', isDense: true))),
                        const SizedBox(width: 6),
                        Expanded(child: TextField(controller: endCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Đến số', isDense: true))),
                        const SizedBox(width: 6),
                        Expanded(child: TextField(controller: padCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Đệm 0', isDense: true))),
                      ],
                    ),
                  ],
                  if (deployRes != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${deployRes!['message'] ?? ''}\nThành công: ${deployRes!['succeeded'] ?? 0} · Thất bại: ${deployRes!['failed'] ?? 0}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    if (detailList.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 160),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: detailList.map((r) {
                              final ok = r['success'] == true;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${ok ? "✓" : "✕"} ${r['deviceId'] ?? ''}: ${r['message'] ?? r['reason'] ?? (ok ? "Thành công" : "Thất bại")}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: ok ? const Color(0xFF047857) : const Color(0xFFDC2626),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
              FilledButton(
                onPressed: () async {
                  final Map<String, dynamic> body;
                  if (!useRange) {
                    final ids = idsCtrl.text
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toList();
                    if (ids.isEmpty || ids.length > 100) {
                      _snack('Cần từ 1 đến 100 mã thiết bị.', error: true);
                      return;
                    }
                    body = {'deviceIds': ids};
                  } else {
                    final start = int.tryParse(startCtrl.text) ?? 1;
                    final end = int.tryParse(endCtrl.text) ?? start;
                    final pad = (int.tryParse(padCtrl.text) ?? 6).clamp(1, 12);
                    if (end < start || (end - start + 1) > 100) {
                      _snack('Dải mã hợp lệ tối đa 100 thiết bị.', error: true);
                      return;
                    }
                    body = {
                      'prefix': prefixCtrl.text.trim(),
                      'startRange': start,
                      'endRange': end,
                      'padLength': pad,
                    };
                  }
                  try {
                    final res = await _api.deployTemplate(tmplId, body);
                    setLocal(() => deployRes = res);
                  } catch (e) {
                    _snack(e is ApiException ? e.message : 'Triển khai thất bại.', error: true);
                  }
                },
                child: const Text('Triển khai'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: AContent(
        maxWidth: SampleA.listWidth,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kho nút hệ thống', style: SampleA.title),
                          SizedBox(height: 2),
                          Text(
                            'Vận hành, cấp phát & mẫu thiết bị (SYSTEM_STAFF)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _switchSubTab(_subTab),
                      icon: const Icon(LucideIcons.refreshCw, size: 19),
                      tooltip: 'Làm mới',
                    ),
                  ],
                ),
              ),

              // 3 Sub-tab Pills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    _pill(0, 'Kho nút', LucideIcons.cpu),
                    const SizedBox(width: 8),
                    _pill(1, 'Cấp phát', LucideIcons.send),
                    const SizedBox(width: 8),
                    _pill(2, 'Mẫu nút', LucideIcons.layers),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              Expanded(
                child: _subTab == 0
                    ? _buildDevicesTab()
                    : _subTab == 1
                        ? _buildAllocateTab()
                        : _buildTemplatesTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(int idx, String label, IconData icon) {
    final active = _subTab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => _switchSubTab(idx),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0E6BA8) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? const Color(0xFF0E6BA8) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? Colors.white : const Color(0xFF475569)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevicesTab() {
    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          if (_fleetStats.isNotEmpty) ...[
            Row(
              children: [
                _kpi('Tổng', '${_fleetStats['total'] ?? _totalItems}', const Color(0xFF0E6BA8)),
                const SizedBox(width: 8),
                _kpi('Online', '${_fleetStats['online'] ?? 0}', const Color(0xFF059669)),
                const SizedBox(width: 8),
                _kpi('Pin yếu', '${_fleetStats['lowBattery'] ?? 0}', const Color(0xFFD97706)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _showRegisterDialog,
                icon: const Icon(LucideIcons.plus, size: 15),
                label: const Text('Đăng ký'),
              ),
              OutlinedButton.icon(
                onPressed: _showBatchGenerateDialog,
                icon: const Icon(LucideIcons.boxes, size: 15),
                label: const Text('Sinh lô'),
              ),
              OutlinedButton.icon(
                onPressed: _showBulkImportDialog,
                icon: const Icon(LucideIcons.fileSpreadsheet, size: 15),
                label: const Text('Nhập CSV'),
              ),
              OutlinedButton.icon(
                onPressed: _showLookupDialog,
                icon: const Icon(LucideIcons.qrCode, size: 15),
                label: const Text('Tra mã'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) {
              _search = v;
              _page = 1;
              _loadDevices();
            },
            decoration: InputDecoration(
              hintText: 'Tìm mã nút, serial, tên...',
              prefixIcon: const Icon(LucideIcons.search, size: 17),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _custodyStoreFilter,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Lọc theo cửa hàng giữ nút (custodyStoreId)',
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Tất cả cửa hàng giữ nút')),
              ..._stores.map((s) {
                final id = (s['storeId'] ?? s['id']).toString();
                return DropdownMenuItem(value: id, child: Text((s['name'] ?? 'CH #$id').toString(), overflow: TextOverflow.ellipsis));
              }),
            ],
            onChanged: (v) {
              setState(() {
                _custodyStoreFilter = v ?? '';
                _page = 1;
              });
              _loadDevices();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _inventoryStateFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tất cả kho')),
                    DropdownMenuItem(value: 'IN_PLATFORM_WAREHOUSE', child: Text('Kho tổng')),
                    DropdownMenuItem(value: 'ALLOCATED_TO_STORE', child: Text('Kho cửa hàng')),
                    DropdownMenuItem(value: 'IN_CUSTOMER_CUSTODY', child: Text('Khách thuê')),
                    DropdownMenuItem(value: 'LOCKED', child: Text('Đã khóa')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _inventoryStateFilter = v ?? '';
                      _page = 1;
                    });
                    _loadDevices();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Đã cấp phát', style: TextStyle(fontSize: 11.5)),
                selected: _allocatedOnly,
                onSelected: (v) {
                  setState(() {
                    _allocatedOnly = v;
                    _page = 1;
                  });
                  _loadDevices();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingDevices)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_devices.isEmpty)
            const ACard(child: Text('Không tìm thấy thiết bị phù hợp.', textAlign: TextAlign.center))
          else
            ..._devices.map((dev) {
              final id = (dev['deviceId'] ?? dev['id'] ?? '').toString();
              final status = (dev['status'] ?? '—').toString();
              final invState = (dev['inventoryState'] ?? '—').toString();
              final bat = dev['batteryLevel'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(id, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: status == 'ACTIVE' ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: status == 'ACTIVE' ? const Color(0xFF047857) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kho giữ: ${_storeName(dev['custodyStoreId'], dev['custodyStore'])} • Định tuyến: ${_storeName(dev['storeId'], dev['store'])}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('$invState • Pin ${bat ?? '--'}%', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showDeviceOpsSheet(dev),
                          icon: const Icon(LucideIcons.wrench, size: 14),
                          label: const Text('Vận hành'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          if (_totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _page > 1
                      ? () {
                          setState(() => _page--);
                          _loadDevices();
                        }
                      : null,
                  child: const Text('← Trang trước'),
                ),
                Text('Trang $_page/$_totalPages', style: const TextStyle(fontSize: 12)),
                TextButton(
                  onPressed: _page < _totalPages
                      ? () {
                          setState(() => _page++);
                          _loadDevices();
                        }
                      : null,
                  child: const Text('Trang sau →'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAllocateTab() {
    return RefreshIndicator(
      onRefresh: _loadUnassigned,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          // Store Inventory Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tồn kho nút theo cửa hàng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _inspectStoreId.isEmpty ? null : _inspectStoreId,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  items: _stores.map((s) {
                    final id = (s['storeId'] ?? s['id']).toString();
                    return DropdownMenuItem(value: id, child: Text((s['name'] ?? 'CH #$id').toString(), overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) {
                    setState(() => _inspectStoreId = v ?? '');
                    if (_inspectStoreId.isNotEmpty) _loadStoreInventory(_inspectStoreId);
                  },
                ),
                if (_storeInventory != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _kpi('Kho CH', '${_storeInventory!['inStockInStore'] ?? 0}', const Color(0xFF0E6BA8)),
                      const SizedBox(width: 8),
                      _kpi('Khách thuê', '${_storeInventory!['rentedByCustomers'] ?? 0}', const Color(0xFF059669)),
                      const SizedBox(width: 8),
                      _kpi('Tổng giữ', '${_storeInventory!['totalCustody'] ?? 0}', const Color(0xFF334155)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text('Kho tổng chưa cấp phát (${_unassigned.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              FilledButton.icon(
                onPressed: _selectedAllocateIds.isEmpty ? null : _showAllocateDialog,
                icon: const Icon(LucideIcons.send, size: 14),
                label: Text('Cấp phát (${_selectedAllocateIds.length})'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) {
              _unassignedSearch = v;
              _loadUnassigned();
            },
            decoration: InputDecoration(
              hintText: 'Tìm nút chưa cấp phát (deviceId, serial)...',
              prefixIcon: const Icon(LucideIcons.search, size: 16),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingUnassigned)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_unassigned.isEmpty)
            const ACard(child: Text('Kho tổng chưa cấp phát đang trống.', textAlign: TextAlign.center))
          else
            ..._unassigned.map((dev) {
              final id = (dev['deviceId'] ?? dev['id'] ?? '').toString();
              final checked = _selectedAllocateIds.contains(id);
              return CheckboxListTile(
                value: checked,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedAllocateIds.add(id);
                  } else {
                    _selectedAllocateIds.remove(id);
                  }
                }),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: Text('Mã ghép: ${dev['pairingCode'] ?? '—'} • Serial: ${dev['serialNumber'] ?? '—'}', style: const TextStyle(fontSize: 11.5)),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          FilledButton.icon(
            onPressed: () => _showTemplateFormDialog(),
            icon: const Icon(LucideIcons.plus, size: 15),
            label: const Text('Tạo mẫu cấu hình thiết bị'),
          ),
          const SizedBox(height: 12),
          if (_loadingTemplates)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_templates.isEmpty)
            const ACard(child: Text('Chưa có mẫu cấu hình nào.', textAlign: TextAlign.center))
          else
            ..._templates.map((t) {
              final tmplId = (t['id'] ?? t['templateId']).toString();
              final isGlobal = t['storeId'] == null;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text((t['name'] ?? 'Mẫu').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isGlobal ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isGlobal ? 'Toàn hệ thống' : _storeName(t['storeId']),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isGlobal ? const Color(0xFF4338CA) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((t['description'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(t['description'].toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () => _showDeployTemplateDialog(t),
                          icon: const Icon(LucideIcons.rocket, size: 14),
                          label: const Text('Triển khai'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: () => _showTemplateFormDialog(editing: t),
                          icon: const Icon(LucideIcons.pencil, size: 13),
                          label: const Text('Sửa'),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            try {
                              await _api.deleteTemplate(tmplId);
                              _snack('Đã xóa mẫu thiết bị.');
                              _loadTemplates();
                            } catch (e) {
                              _snack(e is ApiException ? e.message : 'Không thể xóa mẫu.', error: true);
                            }
                          },
                          icon: const Icon(LucideIcons.trash2, size: 17, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _kpi(String label, String val, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    ),
  );
}
