import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/api_client.dart';
import '../../services/system_staff_api_service.dart';
import '../../widgets/sample_a.dart';

/// Màn hình Bảo hành kỹ thuật cho SYSTEM_STAFF:
/// - Xem danh sách & chi tiết phiếu bảo hành (có ảnh chụp rentalId/khách/cửa hàng)
/// - Duyệt đổi 1-1 (approveSwap), Khóa nút lỗi (lockDevice -> tạo yêu cầu hoàn cọc PENDING_APPROVAL)
/// - Đóng (resolve) hoặc Từ chối (reject) phiếu, hiển thị rõ lỗi 409 nếu snapshot thay đổi
class SystemStaffWarrantyScreen extends StatefulWidget {
  const SystemStaffWarrantyScreen({super.key});

  @override
  State<SystemStaffWarrantyScreen> createState() =>
      _SystemStaffWarrantyScreenState();
}

class _SystemStaffWarrantyScreenState extends State<SystemStaffWarrantyScreen> {
  final _api = SystemStaffApiService();

  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String _statusFilter = '';
  String _groupFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _api.listWarrantyTickets(
        status: _statusFilter.isEmpty ? null : _statusFilter,
        faultGroup: _groupFilter.isEmpty ? null : _groupFilter,
        page: 1,
        pageSize: 30,
      );
      if (!mounted) return;
      setState(() {
        _tickets = res.items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e is ApiException ? e.message : 'Không tải được phiếu bảo hành.', error: true);
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

  String _errText(Object e, String fallback) {
    if (e is ApiException) {
      if (e.statusCode == 409) {
        return 'Xung đột (409): ${e.message}';
      }
      return e.message;
    }
    return fallback;
  }

  Future<void> _showDetail(Map<String, dynamic> rawTicket) async {
    final id = (rawTicket['ticketId'] ?? rawTicket['id']).toString();
    Map<String, dynamic> detail = rawTicket;
    try {
      detail = await _api.getWarrantyTicket(id);
    } catch (_) {}
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Phiếu ${detail['ticketCode'] ?? '#$id'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _row('Mã nút lỗi', (detail['deviceId'] ?? detail['button']?['deviceId'] ?? '—').toString()),
              _row('Nút đổi 1-1', (detail['replacementDeviceId'] ?? detail['replacementButton']?['deviceId'] ?? '—').toString()),
              _row('Nhóm / Mã lỗi', '${detail['faultGroup']} · ${detail['faultCode']}'),
              _row('Trạng thái', (detail['status'] ?? '—').toString()),
              _row('Rental Snapshot', (detail['rentalId'] ?? detail['snapshotRentalId'] ?? '—').toString()),
              _row('Ghi chú kiểm tra', (detail['inspectionNote'] ?? '—').toString()),
              if (detail['adminNote'] != null)
                _row('Ghi chú xử lý', detail['adminNote'].toString()),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
        children: [
          TextSpan(text: '$k: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: v),
        ],
      ),
    ),
  );

  Future<void> _showCreateTicketDialog() async {
    final devCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String group = 'GROUP_A';
    String fault = 'HARDWARE_FAULT';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Lập phiếu bảo hành', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: devCtrl, decoration: const InputDecoration(labelText: 'Mã nút bấm * (VD: SOB-000003)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: group,
                  decoration: const InputDecoration(labelText: 'Nhóm lỗi'),
                  items: const [
                    DropdownMenuItem(value: 'GROUP_A', child: Text('Nhóm A · Lỗi kỹ thuật (0%)')),
                    DropdownMenuItem(value: 'GROUP_B', child: Text('Nhóm B · Mạng / Trẻ em')),
                    DropdownMenuItem(value: 'GROUP_C', child: Text('Nhóm C · Vỡ vỏ nhẹ (30%)')),
                    DropdownMenuItem(value: 'GROUP_D', child: Text('Nhóm D · Hỏng nặng/Mất (70-100%)')),
                  ],
                  onChanged: (v) => setLocal(() {
                    group = v ?? 'GROUP_A';
                    fault = group == 'GROUP_A'
                        ? 'HARDWARE_FAULT'
                        : group == 'GROUP_B'
                            ? 'WIFI_CHANGED'
                            : group == 'GROUP_C'
                                ? 'TIER_C_SHELL_CRACK_30%'
                                : 'WATER_DAMAGE';
                  }),
                ),
                const SizedBox(height: 8),
                TextField(controller: noteCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Ghi chú ngoại quan')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo phiếu')),
          ],
        ),
      ),
    );
    if (ok != true || devCtrl.text.trim().isEmpty) return;
    try {
      await _api.createWarrantyTicket({
        'deviceId': devCtrl.text.trim().toUpperCase(),
        'faultGroup': group,
        'faultCode': fault,
        'inspectionNote': noteCtrl.text.trim().isEmpty ? 'Kiểm tra từ Mobile Staff' : noteCtrl.text.trim(),
      });
      _snack('Đã tạo phiếu bảo hành thành công!');
      _load();
    } catch (e) {
      _snack(_errText(e, 'Không thể tạo phiếu bảo hành.'), error: true);
    }
  }

  Future<void> _showSwapDialog(Map<String, dynamic> ticket) async {
    final id = (ticket['ticketId'] ?? ticket['id']).toString();
    final replaceCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Đã duyệt đổi mới 1-1 từ kho.');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duyệt đổi nút 1-1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nút thay thế tự động kế thừa hợp đồng thuê, khách hàng và cấu hình.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            TextField(controller: replaceCtrl, decoration: const InputDecoration(labelText: 'Mã nút thay thế (để trống = tự chọn)')),
            const SizedBox(height: 8),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú kỹ thuật')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận đổi')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.approveSwap(
        id,
        replacementDeviceId: replaceCtrl.text.trim(),
        adminNote: noteCtrl.text.trim(),
      );
      _snack('Duyệt đổi 1-1 thành công!');
      _load();
    } catch (e) {
      _snack(_errText(e, 'Không thể duyệt đổi 1-1.'), error: true);
    }
  }

  Future<void> _lockDevice(Map<String, dynamic> ticket) async {
    final id = (ticket['ticketId'] ?? ticket['id']).toString();
    try {
      await _api.lockWarrantyDevice(
        id,
        adminNote: 'Đã khóa nút lỗi, tạo yêu cầu hoàn cọc PENDING_APPROVAL chờ Admin duyệt.',
      );
      _snack('Đã khóa nút lỗi! Yêu cầu hoàn cọc chuyển PENDING_APPROVAL chờ Admin duyệt.');
      _load();
    } catch (e) {
      _snack(_errText(e, 'Không thể khóa nút lỗi.'), error: true);
    }
  }

  Future<void> _resolve(Map<String, dynamic> ticket) async {
    final id = (ticket['ticketId'] ?? ticket['id']).toString();
    try {
      await _api.resolveWarrantyTicket(id, adminNote: 'Hoàn tất xử lý bảo hành kỹ thuật.');
      _snack('Đã đóng phiếu bảo hành.');
      _load();
    } catch (e) {
      _snack(_errText(e, 'Không thể đóng phiếu.'), error: true);
    }
  }

  Future<void> _reject(Map<String, dynamic> ticket) async {
    final id = (ticket['ticketId'] ?? ticket['id']).toString();
    try {
      await _api.rejectWarrantyTicket(id, adminNote: 'Từ chối phiếu bảo hành.');
      _snack('Đã từ chối phiếu bảo hành.');
      _load();
    } catch (e) {
      _snack(_errText(e, 'Không thể từ chối phiếu.'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: AContent(
        maxWidth: SampleA.listWidth,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  children: [
                    if (Navigator.of(context).canPop()) ...[
                      IconButton(
                        tooltip: 'Quay lại',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bảo hành kỹ thuật', style: SampleA.title),
                          SizedBox(height: 2),
                          Text(
                            'Đổi 1-1, khóa nút lỗi (hoàn cọc chờ Admin duyệt), đóng/từ chối',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(onPressed: _load, icon: const Icon(LucideIcons.refreshCw, size: 19)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _showCreateTicketDialog,
                      icon: const Icon(LucideIcons.plus, size: 15),
                      label: const Text('Lập phiếu'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Mọi trạng thái')),
                          DropdownMenuItem(value: 'PENDING', child: Text('Chờ xử lý')),
                          DropdownMenuItem(value: 'APPROVED_SWAP', child: Text('Đã đổi 1-1')),
                          DropdownMenuItem(value: 'RESOLVED', child: Text('Hoàn tất')),
                          DropdownMenuItem(value: 'REJECTED', child: Text('Từ chối')),
                        ],
                        onChanged: (v) {
                          setState(() => _statusFilter = v ?? '');
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (_tickets.isEmpty)
                  const ACard(child: Text('Chưa có phiếu bảo hành nào.', textAlign: TextAlign.center))
                else
                  ..._tickets.map((t) {
                    final code = (t['ticketCode'] ?? '#${t['ticketId'] ?? t['id']}').toString();
                    final devId = (t['deviceId'] ?? t['button']?['deviceId'] ?? '—').toString();
                    final group = (t['faultGroup'] ?? 'GROUP_A').toString();
                    final status = (t['status'] ?? 'PENDING').toString();
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
                                child: Text('$devId · $code', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: status == 'PENDING'
                                      ? const Color(0xFFFFFBEB)
                                      : status == 'RESOLVED'
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('$group · ${t['faultCode'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0E6BA8))),
                          if ((t['inspectionNote'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(t['inspectionNote'].toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showDetail(t),
                                icon: const Icon(LucideIcons.eye, size: 13),
                                label: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                              ),
                              if (status == 'PENDING' && group == 'GROUP_A')
                                FilledButton.icon(
                                  onPressed: () => _showSwapDialog(t),
                                  icon: const Icon(LucideIcons.refreshCw, size: 13),
                                  label: const Text('Đổi 1-1', style: TextStyle(fontSize: 12)),
                                ),
                              if (status == 'PENDING' && (group == 'GROUP_C' || group == 'GROUP_D'))
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                  onPressed: () => _lockDevice(t),
                                  icon: const Icon(LucideIcons.lock, size: 13),
                                  label: const Text('Khóa nút', style: TextStyle(fontSize: 12)),
                                ),
                              if (status == 'PENDING' || status == 'APPROVED_SWAP')
                                OutlinedButton(
                                  onPressed: () => _resolve(t),
                                  child: const Text('Hoàn tất', style: TextStyle(fontSize: 12)),
                                ),
                              if (status == 'PENDING')
                                TextButton(
                                  onPressed: () => _reject(t),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                                  child: const Text('Từ chối', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
