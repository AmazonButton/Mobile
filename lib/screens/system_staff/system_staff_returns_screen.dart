import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/api_client.dart';
import '../../services/system_staff_api_service.dart';
import '../../widgets/sample_a.dart';

/// Màn hình Thu hồi nút thuê cho SYSTEM_STAFF:
/// - GET /rentals/returns (lọc PENDING_RECEIPT / RECEIVED / ALL)
/// - POST /rentals/returns/:returnId/confirm-receipt kèm biên bản kiểm tra ngoại quan
class SystemStaffReturnsScreen extends StatefulWidget {
  const SystemStaffReturnsScreen({super.key});

  @override
  State<SystemStaffReturnsScreen> createState() =>
      _SystemStaffReturnsScreenState();
}

class _SystemStaffReturnsScreenState extends State<SystemStaffReturnsScreen> {
  final _api = SystemStaffApiService();

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _status = 'PENDING_RECEIPT';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _api.listReturnRequests(
        status: _status,
        search: _search,
        page: 1,
        pageSize: 30,
      );
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e is ApiException ? e.message : 'Không tải được phiếu thu hồi.', error: true);
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

  Future<void> _confirmReceipt(Map<String, dynamic> row) async {
    final returnId = (row['returnId'] ?? row['id']).toString();
    final noteCtrl = TextEditingController(
      text: 'Ngoại quan bình thường, đã nhận lại thiết bị về kho.',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận nhận nút ${row['deviceId'] ?? row['returnCode']}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phiếu: ${row['returnCode']} • HĐ: ${row['rentalCode'] ?? '#${row['rentalId']}'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú kiểm tra nút',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Yêu cầu hoàn cọc sau khi nhận kho sẽ chuyển PENDING_APPROVAL để Admin phê duyệt tài chính.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFFB45309)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await _api.confirmReturnReceipt(
        returnId,
        inspectionNote: noteCtrl.text.trim(),
      );
      _snack(res['message']?.toString() ?? 'Đã xác nhận tiếp nhận nút trả kho!');
      _load();
    } catch (e) {
      _snack(e is ApiException ? e.message : 'Xác nhận thất bại.', error: true);
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
                          Text('Thu hồi nút thuê', style: SampleA.title),
                          SizedBox(height: 2),
                          Text(
                            'Kiểm tra nút khách trả về kho & xác nhận tiếp nhận',
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
                    Expanded(
                      child: TextField(
                        onChanged: (v) {
                          _search = v;
                          _load();
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm mã trả, mã nút...',
                          prefixIcon: const Icon(LucideIcons.search, size: 16),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _status,
                      items: const [
                        DropdownMenuItem(value: 'PENDING_RECEIPT', child: Text('Chờ nhận')),
                        DropdownMenuItem(value: 'RECEIVED', child: Text('Đã nhận')),
                        DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                      ],
                      onChanged: (v) {
                        setState(() => _status = v ?? 'PENDING_RECEIPT');
                        _load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (_items.isEmpty)
                  const ACard(child: Text('Không có yêu cầu thu hồi nút nào.', textAlign: TextAlign.center))
                else
                  ..._items.map((r) {
                    final st = (r['status'] ?? 'PENDING_RECEIPT').toString();
                    final isPending = st == 'PENDING_RECEIPT' || st == 'PENDING' || st == 'IN_TRANSIT';
                    final refund = r['depositRefund'];
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
                                child: Text(
                                  '${r['deviceId'] ?? '#${r['buttonId']}'} · ${r['returnCode'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPending ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isPending ? 'Chờ nhận kho' : 'Đã nhận kho',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isPending ? const Color(0xFFB45309) : const Color(0xFF047857),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Khách: ${r['customerName'] ?? '—'} • HĐ: ${r['rentalCode'] ?? '#${r['rentalId']}'}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          ),
                          if (refund is Map) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Hoàn cọc: ${refund['refundAmount']}₫ (${refund['status']})',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0E6BA8)),
                            ),
                          ],
                          if ((r['inspectionNote'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(r['inspectionNote'].toString(), style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                          if (isPending) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _confirmReceipt(r),
                                icon: const Icon(LucideIcons.checkCircle2, size: 15),
                                label: const Text('Kiểm tra & Xác nhận nhận nút'),
                              ),
                            ),
                          ],
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
