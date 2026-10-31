import 'package:flutter/material.dart';
import '../../../services/stores_api_service.dart';
import '../../../services/goong_service.dart';
import '../../../providers/address_provider.dart';
import 'package:provider/provider.dart';

/// Stores loaded from the authenticated stores API.
class HomeQuickShopShelf extends StatefulWidget {
  const HomeQuickShopShelf({super.key});

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
      if (point != null)
        store['distanceKm'] = GoongService.distanceKm(origin, point);
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

  void _openStore(Map store) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store['name']?.toString() ?? 'Cửa hàng',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(store['address']?.toString() ?? 'Chưa có địa chỉ'),
              if (store['phone'] != null) ...[
                const SizedBox(height: 12),
                SelectableText('Điện thoại: ${store['phone']}'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Các cửa hàng gần đây',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
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
            if (stores.isEmpty)
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Chưa có cửa hàng đang hoạt động.'),
              );
            return SizedBox(
              height: 184,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stores.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return SizedBox(
                    width: 144,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openStore(store),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 94,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.storefront,
                              size: 52,
                              color: Color(0xFF4478BB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            store['name']?.toString() ?? 'Cửa hàng',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  store['distanceKm'] != null
                                      ? '${(store['distanceKm'] as double).toStringAsFixed(1)} km (đường thẳng)'
                                      : store['address']?.toString() ??
                                            'Chưa có địa chỉ',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
