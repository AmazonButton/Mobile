import '../../../widgets/sample_a.dart';
import '../../../widgets/smart_order_tour.dart';
import '../../store_catalog_screen.dart';
import 'package:flutter/material.dart';
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
    final address = context.read<AddressProvider>().selectedAddress;
    final stores = (await StoresApiService().getStores())
        .whereType<Map>()
        .where((s) => s['status'] == 'ACTIVE')
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
    final goong = GoongService();
    final origin = address?.latitude != null && address?.longitude != null
        ? (address!.latitude!, address.longitude!)
        : await goong.geocode(address?.fullAddress ?? '');
    if (origin == null) return stores;
    for (final store in stores) {
      final point = await goong.geocode(store['address']?.toString() ?? '');
      if (point != null) {
        store['distanceKm'] = GoongService.distanceKm(origin, point);
      }
    }
    stores.sort(
      (a, b) => ((a['distanceKm'] as double?) ?? double.infinity).compareTo(
        (b['distanceKm'] as double?) ?? double.infinity,
      ),
    );
    return stores;
  }

  @override
  void initState() {
    super.initState();
    // Loading starts when the selected delivery address is available.
  }

  void _retry() => setState(() {
    _stores = _loadStores();
  });

  Future<void> _openStore(Map store) async {
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
        const Text(
          'Khám phá cửa hàng',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Chọn cửa hàng để xem sản phẩm',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: _stores,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  const Text('Không thể tải cửa hàng.'),
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
                    padding: const EdgeInsets.only(bottom: 12),
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
    final image =
        (store['coverImageUrl'] ?? store['imageUrl'] ?? store['logoUrl'])
            ?.toString();
    final fallback = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDBEAFE), SampleA.pale],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 72,
          color: Color(0xFF6093CF),
        ),
      ),
    );
    final description = store['description']?.toString().trim();
    final address = store['address']?.toString().trim();
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E8F5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 136,
              child: image == null || image.isEmpty
                  ? fallback
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['name']?.toString() ?? 'Cửa hàng',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: SampleA.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description?.isNotEmpty == true
                              ? description!
                              : address?.isNotEmpty == true
                              ? address!
                              : 'Khám phá sản phẩm của cửa hàng',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                        if (store['distanceKm'] is num) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${(store['distanceKm'] as num).toStringAsFixed(1)} km (đường thẳng)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Color(0xFF334155)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
