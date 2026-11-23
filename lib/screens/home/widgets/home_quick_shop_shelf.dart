import '../../../widgets/smart_order_tour.dart';
import '../../store_catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/stores_api_service.dart';
import '../../../services/goong_service.dart';
import '../../../providers/address_provider.dart';
import 'package:provider/provider.dart';

/// Stores loaded from the authenticated stores API.
class HomeQuickShopShelf extends StatefulWidget {
  const HomeQuickShopShelf({super.key, this.tour});
  final SmartOrderTour? tour;

  @override
  State<HomeQuickShopShelf> createState() => _HomeQuickShopShelfState();
}

class _HomeQuickShopShelfState extends State<HomeQuickShopShelf> {
  static List<Map<String, dynamic>>? _cachedStores;
  static DateTime? _lastFetchTime;
  static const Duration _cacheTtl = Duration(minutes: 3);

  late Future<List<dynamic>> _stores;
  String? _addressKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final address = context.watch<AddressProvider>().selectedAddress;
    final key =
        '${address?.fullAddress}|${address?.latitude}|${address?.longitude}';
    if (_addressKey == key) return;
    _addressKey = key;
    _stores = _loadStores();
  }

  Future<List<dynamic>> _loadStores() async {
    final now = DateTime.now();
    if (_cachedStores != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheTtl) {
      return _cachedStores!;
    }

    final address = context.read<AddressProvider>().selectedAddress;
    bool isTestStore(Map s) {
      final name = (s['name'] ?? '').toString().toUpperCase();
      final code = (s['code'] ?? s['storeCode'] ?? '').toString().toUpperCase();
      return name.contains('E2E ') ||
          name.contains('AUDIT STORE') ||
          name.contains('TEST STORE') ||
          code.startsWith('STR_E2E_') ||
          code.startsWith('STR_WDR_') ||
          code.startsWith('STR_BV_') ||
          code.startsWith('STORE-CAT-');
    }

    int storePriority(Map s) {
      final id = (s['storeId'] ?? s['id'] ?? '').toString();
      if (id == '1') return 0; // Đại lý Nước & Gas Gia Định
      if (id == '2') return 1; // Minh Khôi Mart Nhu Yếu Phẩm
      if (id == '67') return 2; // LêBảoStore
      if (id == '381') return 3; // PhatShop
      return 10;
    }

    final stores = (await StoresApiService().getStores())
        .whereType<Map>()
        .where((s) => s['status'] == 'ACTIVE' && !isTestStore(s))
        .map((s) => Map<String, dynamic>.from(s))
        .toList()
      ..sort((a, b) => storePriority(a).compareTo(storePriority(b)));

    final goong = GoongService();
    final origin = address?.latitude != null && address?.longitude != null
        ? (address!.latitude!, address.longitude!)
        : await goong
            .geocode(address?.fullAddress ?? '')
            .timeout(const Duration(milliseconds: 600), onTimeout: () => null);

    if (origin != null) {
      // Use existing store lat/lng immediately (0ms) and only geocode missing coords
      await Future.wait(
        stores.map((store) async {
          try {
            final lat = double.tryParse(store['latitude']?.toString() ?? '');
            final lng = double.tryParse(store['longitude']?.toString() ?? '');
            if (lat != null && lng != null) {
              store['distanceKm'] = GoongService.distanceKm(origin, (lat, lng));
              return;
            }
            final addr = store['address']?.toString() ?? '';
            if (addr.isNotEmpty) {
              final point = await goong
                  .geocode(addr)
                  .timeout(const Duration(milliseconds: 600), onTimeout: () => null);
              if (point != null) {
                store['distanceKm'] = GoongService.distanceKm(origin, point);
              }
            }
          } catch (_) {}
        }),
      );

      stores.sort(
        (a, b) => ((a['distanceKm'] as double?) ?? double.infinity).compareTo(
          (b['distanceKm'] as double?) ?? double.infinity,
        ),
      );
    }

    _cachedStores = stores;
    _lastFetchTime = now;
    return stores;
  }

  @override
  void initState() {
    super.initState();
  }

  void _retry() => setState(() {
    _stores = _loadStores();
  });

  Future<void> _openStore(Map store) async {
    HapticFeedback.lightImpact();
    widget.tour?.openCatalog();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoreCatalogScreen(
          store: Map<String, dynamic>.from(store),
          tour: widget.tour,
        ),
      ),
    );
    widget.tour?.catalogClosed();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Khám phá cửa hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chọn cửa hàng để xem sản phẩm',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.store, size: 12, color: Color(0xFF2563EB)),
                  SizedBox(width: 4),
                  Text(
                    'Đối tác uy tín',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: _stores,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Shimmer.fromColors(
                baseColor: const Color(0xFFF1F5F9),
                highlightColor: const Color(0xFFFFFFFF),
                child: Column(
                  children: List.generate(
                    2,
                    (index) => Container(
                      height: 86,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 140,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 100,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
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
            if (snapshot.hasError) {
              return Column(
                children: [
                  const Text('Không thể tải danh sách cửa hàng.'),
                  TextButton(onPressed: _retry, child: const Text('Thử lại')),
                ],
              );
            }
            final stores = (snapshot.data ?? [])
                .whereType<Map>()
                .where((s) => s['status'] == 'ACTIVE')
                .toList();
            if (stores.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Chưa có cửa hàng đang hoạt động.'),
              );
            }
            return Column(
              children: [
                for (final store in stores)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StoreCard(
                      key: identical(store, stores.first)
                          ? widget.tour?.key(TourStep.stores)
                          : null,
                      store: store,
                      onTap: () => _openStore(store),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Map store;
  final VoidCallback onTap;
  const _StoreCard({super.key, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final logo = (store['logoUrl'] ?? store['imageUrl'] ?? store['coverImageUrl'])?.toString().trim();
    final name = store['name']?.toString().trim() ?? 'Cửa hàng';
    final description = store['description']?.toString().trim();
    final address = store['address']?.toString().trim();
    final distanceKm = store['distanceKm'] is num ? (store['distanceKm'] as num).toDouble() : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── LOGO HÌNH CỬA HÀNG (Bấm dô mở cửa hàng) ──
                Stack(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: logo != null && logo.isNotEmpty
                            ? Image.network(
                                logo,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(
                                    LucideIcons.store,
                                    size: 28,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  LucideIcons.store,
                                  size: 28,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // ── THÔNG TIN CỬA HÀNG ──
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
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.badgeCheck,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              address?.isNotEmpty == true
                                  ? address!
                                  : description?.isNotEmpty == true
                                  ? description!
                                  : 'Địa chỉ đang cập nhật',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.zap, size: 10, color: Color(0xFF15803D)),
                                SizedBox(width: 3),
                                Text(
                                  '15-25p',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (distanceKm != null) ...[
                            const SizedBox(width: 5),
                            Text(
                              '• ${distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'Freeship 5km',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // ── MŨI TÊN CHỈ DẪN VÀO CỬA HÀNG ──
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 15,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
