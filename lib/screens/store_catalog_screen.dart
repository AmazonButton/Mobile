import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'store_product_assignment.dart';
import '../widgets/smart_order_tour.dart';
import '../widgets/sample_a.dart';
import '../services/products_api_service.dart';
import '../models/button_product_model.dart';

class StoreCatalogScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  final SmartOrderTour? tour;
  const StoreCatalogScreen({super.key, required this.store, this.tour});
  @override
  State<StoreCatalogScreen> createState() => _StoreCatalogScreenState();
}

class _StoreCatalogScreenState extends State<StoreCatalogScreen> {
  late Future<List<Map<String, dynamic>>> _products;
  String _query = '';
  bool _assigning = false;
  String get _storeId =>
      (widget.store['storeId'] ?? widget.store['id']).toString();
  @override
  void initState() {
    super.initState();
    _products = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final id = (widget.store['storeId'] ?? widget.store['id'])?.toString();
    if (id == null || id.isEmpty) throw StateError('Thiếu mã cửa hàng');
    final rows = await ProductsApiService().getProducts(storeId: id);
    return rows
        .whereType<Map>()
        .where((p) => p['status'] == 'ACTIVE' && p['storeId']?.toString() == id)
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  String? _image(Map p) {
    final images = p['images'];
    final candidates = [
      p['imageUrl'],
      p['thumbnailUrl'],
      if (images is List) ...[
        ...images
            .whereType<Map>()
            .where((i) => i['isThumbnail'] == true)
            .map((i) => i['imageUrl'] ?? i['url']),
        ...images.map((i) => i is Map ? i['imageUrl'] ?? i['url'] : i),
      ],
    ];
    for (final value in candidates) {
      final uri = Uri.tryParse(value?.toString() ?? '');
      if (uri != null &&
          ['https', 'http'].contains(uri.scheme) &&
          uri.host.isNotEmpty) {
        return uri.toString();
      }
    }
    return null;
  }

  Future<void> _assign(Map<String, dynamic> raw) async {
    if (_assigning) return;
    setState(() => _assigning = true);
    try {
      final provider = context.read<DeviceProvider>();
      final product = ButtonProductModel.fromJson(raw);
      final saved = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        builder: (_) => StoreProductAssignment(
          provider: provider,
          storeId: _storeId,
          storeName: widget.store['name']?.toString() ?? 'Cửa hàng',
          product: product,
          imageUrl: _image(raw),
        ),
      );
      if (saved != true || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã gán ${product.name} vào nút')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thêm sản phẩm vào nút. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = widget.store['distanceKm'] as num?;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.store['name']?.toString() ?? 'Cửa hàng',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: AContent(
        maxWidth: SampleA.listWidth,
        child: RefreshIndicator(
          onRefresh: () async {
            final future = _load();
            setState(() => _products = future);
            await future;
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 140,
                  child:
                      (widget.store['coverImageUrl'] ??
                              widget.store['imageUrl']) !=
                          null
                      ? Image.network(
                          (widget.store['coverImageUrl'] ??
                                  widget.store['imageUrl'])
                              .toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _storePlaceholder(),
                        )
                      : _storePlaceholder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sản phẩm của cửa hàng',
                key: widget.tour?.key(TourStep.catalog),
                style: SampleA.section,
              ),
              if (distance != null)
                Text(
                  '${distance.toStringAsFixed(1)} km đường thẳng từ địa chỉ của bạn',
                  style: SampleA.caption,
                ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Tìm trong cửa hàng',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E8F5)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _products,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        const Text('Không thể tải sản phẩm của cửa hàng.'),
                        TextButton(
                          onPressed: () => setState(() => _products = _load()),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    );
                  }
                  final products = (snapshot.data ?? [])
                      .where(
                        (p) =>
                            '${p['productName'] ?? p['name'] ?? ''} ${p['description'] ?? ''}'
                                .toLowerCase()
                                .contains(_query),
                      )
                      .toList();
                  return Column(
                    children: [
                      ASectionHeader(
                        title: 'Sản phẩm',
                        action: Text('${products.length} sản phẩm'),
                      ),
                      const SizedBox(height: 12),
                      if (products.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Không có sản phẩm phù hợp.'),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width =
                                MediaQuery.textScalerOf(context).scale(14) >
                                        21 ||
                                    constraints.maxWidth < 300
                                ? constraints.maxWidth
                                : (constraints.maxWidth -
                                          12 *
                                              ((constraints.maxWidth / 220)
                                                      .floor()
                                                      .clamp(2, 4) -
                                                  1)) /
                                      (constraints.maxWidth / 220)
                                          .floor()
                                          .clamp(2, 4);
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: products
                                  .map(
                                    (raw) => SizedBox(
                                      width: width,
                                      child: _productRow(raw),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storePlaceholder() => Container(
    color: SampleA.pale,
    alignment: Alignment.center,
    child: const Icon(Icons.storefront, size: 64, color: SampleA.primary),
  );

  Widget _productRow(Map<String, dynamic> raw) {
    final product = ButtonProductModel.fromJson(raw);
    final url = _image(raw);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: SampleA.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 105,
            child: url == null
                ? const Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: SampleA.muted,
                  )
                : Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.inventory_2_outlined, size: 48),
                  ),
          ),
          const SizedBox(height: 8),
          Text(product.name, style: SampleA.body.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            product.priceFormatted,
            style: SampleA.body.copyWith(
              color: SampleA.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: _assigning ? null : () => _assign(raw),
            style: OutlinedButton.styleFrom(
              foregroundColor: SampleA.primary,
              side: const BorderSide(color: SampleA.primary),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: const Text('Gán vào nút'),
          ),
        ],
      ),
    );
  }
}
