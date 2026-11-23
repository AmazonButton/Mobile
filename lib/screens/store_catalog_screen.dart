import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  String get _storeId =>
      (widget.store['storeId'] ?? widget.store['id']).toString();
  @override
  void initState() {
    super.initState();
    _products = _load();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _query = value.trim().toLowerCase());
      }
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final id = (widget.store['storeId'] ?? widget.store['id'])?.toString();
    if (id == null || id.isEmpty) throw StateError('Thiếu mã cửa hàng');
    final rows = await ProductsApiService().getProducts(storeId: id);
    var products = rows
        .whereType<Map>()
        .where((p) => p['status'] == 'ACTIVE' && p['storeId']?.toString() == id)
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    if (products.isEmpty) {
      // Fallback: Nếu cửa hàng chưa đăng sản phẩm riêng, hiển thị danh mục sản phẩm đang mở bán
      final allRows = await ProductsApiService().getProducts();
      products = allRows
          .whereType<Map>()
          .where((p) => p['status'] == 'ACTIVE')
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
    }

    // Đồng bộ ưu đãi giảm giá sản phẩm song song (như bản Web)
    final now = DateTime.now();
    await Future.wait(
      products.map((p) async {
        final pid = (p['productId'] ?? p['id'] ?? '').toString();
        if (pid.isEmpty) return;
        final discounts = await ProductsApiService()
            .getProductDiscounts(pid)
            .timeout(const Duration(milliseconds: 1200), onTimeout: () => []);
        for (final d in discounts) {
          if (d['status'] != 'ACTIVE') continue;
          final start = DateTime.tryParse(d['startAt']?.toString() ?? '');
          final end = DateTime.tryParse(d['endAt']?.toString() ?? '');
          if (start != null && end != null && !now.isBefore(start) && !now.isAfter(end)) {
            final basePrice = num.tryParse('${p['basePrice'] ?? p['price'] ?? 0}') ?? 0;
            final pct = num.tryParse('${d['discountPercent'] ?? ''}');
            final amt = num.tryParse('${d['discountAmount'] ?? ''}');
            final reduction = pct != null
                ? (basePrice * pct / 100).round()
                : (amt ?? 0).round();
            final finalPrice = (basePrice - reduction).clamp(0, basePrice);
            if (finalPrice < basePrice) {
              p['_discountedPrice'] = finalPrice;
              p['_discountBadge'] = pct != null ? '-${pct.round()}%' : '-${reduction}đ';
            }
            break;
          }
        }
      }),
    );

    return products;
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
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm trong cửa hàng',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE0E8F5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _products,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Shimmer.fromColors(
                      baseColor: const Color(0xFFE2E8F0),
                      highlightColor: const Color(0xFFF1F5F9),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(
                          4,
                          (index) => Container(
                            width: 160,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ),
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

  String _formatVnd(num amount) {
    final s = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  Widget _productRow(Map<String, dynamic> raw) {
    final product = ButtonProductModel.fromJson(raw);
    final url = _image(raw);
    final discounted = raw['_discountedPrice'] as num?;
    final discountBadge = raw['_discountBadge'] as String?;
    final inv = raw['inventory'];
    final hasStockField = (inv is Map && inv['quantityOnHand'] != null) ||
        raw['stockQuantity'] != null ||
        raw['stock'] != null;
    final onHand = int.tryParse(
          ((inv is Map ? inv['quantityOnHand'] : null) ??
                  raw['stockQuantity'] ??
                  raw['stock'] ??
                  99)
              .toString(),
        ) ??
        99;
    final reserved = int.tryParse(
          ((inv is Map ? inv['quantityReserved'] : null) ??
                  raw['reservedStock'] ??
                  0)
              .toString(),
        ) ??
        0;
    final isOutOfStock = (hasStockField && (onHand - reserved) <= 0) ||
        (raw['status'] != null &&
            raw['status'].toString().toUpperCase() != 'ACTIVE');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOutOfStock ? const Color(0xFFFAFAFA) : Colors.white,
        border: Border.all(
          color: isOutOfStock ? const Color(0xFFFECACA) : SampleA.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Opacity(
                opacity: isOutOfStock ? 0.45 : 1.0,
                child: SizedBox(
                  height: 105,
                  width: double.infinity,
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
              ),
              if (isOutOfStock)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Hết hàng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              if (discountBadge != null && !isOutOfStock)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      discountBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(product.name, style: SampleA.body.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          if (discounted != null)
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _formatVnd(discounted),
                  style: SampleA.body.copyWith(
                    color: SampleA.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  product.priceFormatted,
                  style: SampleA.caption.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            )
          else
            Text(
              product.priceFormatted,
              style: SampleA.body.copyWith(
                color: SampleA.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: (_assigning || isOutOfStock) ? null : () => _assign(raw),
            style: OutlinedButton.styleFrom(
              foregroundColor: isOutOfStock ? const Color(0xFF94A3B8) : SampleA.primary,
              side: BorderSide(
                color: isOutOfStock ? const Color(0xFFCBD5E1) : SampleA.primary,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: Text(isOutOfStock ? 'Tạm hết hàng' : 'Gán vào nút'),
          ),
        ],
      ),
    );
  }
}
