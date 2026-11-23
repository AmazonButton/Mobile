import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_client.dart';
import '../services/stores_api_service.dart';
import '../widgets/app_motion.dart';
import '../widgets/sample_a.dart';

/// Màn hình Giám sát Cửa hàng đối tác dành riêng cho ADMIN / SUPER_ADMIN.
class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  final _storesApi = StoresApiService();
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _statusFilter = 'ALL';
  int _filterDirection = 1;
  static const _filterOrder = ['ALL', 'ACTIVE', 'OTHER'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _storesApi.getAdminStores();
      if (!mounted) return;
      final list = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        _stores = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException
            ? e.message
            : 'Không thể tải danh sách cửa hàng đối tác.';
        _loading = false;
      });
    }
  }

  void _showStoreDetail(Map<String, dynamic> store) {
    HapticFeedback.selectionClick();
    final name = (store['name'] ?? 'Cửa hàng').toString();
    final code = (store['code'] ?? '—').toString();
    final status = (store['status'] ?? 'ACTIVE').toString().toUpperCase();
    final phone = (store['phone'] ?? 'Chưa cập nhật').toString();
    final email = (store['email'] ?? 'Chưa cập nhật').toString();
    final address = (store['address'] ?? 'Chưa cập nhật địa chỉ').toString();
    final commission = store['commissionRate']?.toString();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.store,
                      color: Color(0xFF4338CA),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Mã đại lý: $code · $status',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),
              _detailRow(LucideIcons.mapPin, 'Địa chỉ', address),
              _detailRow(LucideIcons.phone, 'Số điện thoại', phone),
              _detailRow(LucideIcons.mail, 'Email', email),
              if (commission != null && commission.isNotEmpty)
                _detailRow(
                  LucideIcons.percent,
                  'Chiết khấu sàn',
                  '$commission%',
                ),
              const SizedBox(height: 14),
              AButton(
                label: 'Đóng',
                kind: AButtonKind.secondary,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _stores
        .where((s) => (s['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE')
        .length;
    final inactiveCount = _stores.length - activeCount;

    final filtered = _stores.where((s) {
      final st = (s['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (_statusFilter == 'ACTIVE' && st != 'ACTIVE') return false;
      if (_statusFilter == 'OTHER' && st == 'ACTIVE') return false;
      if (_search.trim().isNotEmpty) {
        final q = _search.trim().toLowerCase();
        final name = (s['name'] ?? '').toString().toLowerCase();
        final code = (s['code'] ?? '').toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        final addr = (s['address'] ?? '').toString().toLowerCase();
        return name.contains(q) ||
            code.contains(q) ||
            email.contains(q) ||
            addr.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: AContent(
        maxWidth: SampleA.listWidth,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _load,
            color: const Color(0xFF4338CA),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cửa hàng đối tác', style: SampleA.title),
                          SizedBox(height: 3),
                          Text(
                            'Giám sát mạng lưới đại lý hoạt động trên toàn hệ thống',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _load,
                      tooltip: 'Làm mới',
                      icon: const Icon(LucideIcons.refreshCw, size: 19),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Compact live summary strip
                Row(
                  children: [
                    _kpiBox('Tổng đại lý', _stores.length, const Color(0xFF4338CA)),
                    const SizedBox(width: 10),
                    _kpiBox('Hoạt động', activeCount, const Color(0xFF059669)),
                    const SizedBox(width: 10),
                    _kpiBox('Khác', inactiveCount, const Color(0xFFD97706)),
                  ],
                ),
                const SizedBox(height: 14),

                // Search bar
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm tên cửa hàng, mã đại lý, email...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Tất cả', 'ALL'),
                      const SizedBox(width: 8),
                      _filterChip('Hoạt động', 'ACTIVE'),
                      const SizedBox(width: 8),
                      _filterChip('Chờ / Tạm dừng', 'OTHER'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (_loading)
                  AppMotion.allowAmbient(context)
                      ? Shimmer.fromColors(
                          baseColor: const Color(0xFFE2E8F0),
                          highlightColor: Colors.white,
                          child: Column(
                            children: List.generate(
                              4,
                              (_) => Container(
                                height: 86,
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: List.generate(
                            4,
                            (_) => Container(
                              height: 86,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        )
                else if (_error != null)
                  ACard(
                    child: Column(
                      children: [
                        Text(_error!, style: SampleA.body),
                        const SizedBox(height: 12),
                        AButton(label: 'Thử lại', onPressed: _load),
                      ],
                    ),
                  )
                else
                  AppSlideSwitcher(
                    direction: _filterDirection,
                    child: Column(
                      key: ValueKey('admin_stores_$_statusFilter'),
                      children: [
                        if (filtered.isEmpty)
                          const ACard(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(
                                    LucideIcons.store,
                                    size: 36,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Không tìm thấy cửa hàng phù hợp',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filtered.map((s) {
                    final name = (s['name'] ?? 'Cửa hàng').toString();
                    final code = (s['code'] ?? '').toString();
                    final status = (s['status'] ?? 'ACTIVE').toString().toUpperCase();
                    final active = status == 'ACTIVE';
                    final address = (s['address'] ?? 'Chưa cập nhật địa chỉ').toString();
                    final email = (s['email'] ?? '').toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TactilePress(
                        scaleDown: 0.985,
                        haptic: true,
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showStoreDetail(s),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: AppMotion.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  LucideIcons.store,
                                  size: 20,
                                  color: Color(0xFF4338CA),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: active
                                                ? const Color(0xFFECFDF5)
                                                : const Color(0xFFFFFBEB),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            active ? 'Hoạt động' : status,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: active
                                                  ? const Color(0xFF047857)
                                                  : const Color(0xFFB45309),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      [
                                        if (code.isNotEmpty) code,
                                        if (email.isNotEmpty) email,
                                      ].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4338CA),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                LucideIcons.chevronRight,
                                size: 17,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kpiBox(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppMotion.cardShadow,
        ),
        child: Column(
          children: [
            AnimatedCountText(
              value: value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _statusFilter == value;
    return TactilePress(
      scaleDown: 0.95,
      haptic: true,
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (_statusFilter == value) return;
        final oldIdx = _filterOrder.indexOf(_statusFilter);
        final newIdx = _filterOrder.indexOf(value);
        setState(() {
          _filterDirection = newIdx >= oldIdx ? 1 : -1;
          _statusFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: AppMotion.fastDuration,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4338CA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
