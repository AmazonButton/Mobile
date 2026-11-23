import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';
import '../services/products_api_service.dart';
import '../services/stores_api_service.dart';
import '../widgets/app_motion.dart';
import '../widgets/sample_a.dart';

/// Màn hình Sản phẩm & tồn kho dành riêng cho Chủ cửa hàng (đồng bộ với Web /store/products).
class StoreProductsScreen extends StatefulWidget {
  const StoreProductsScreen({super.key});

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _stockFilter = 'ALL'; // ALL, IN_STOCK, LOW, OUT
  int _filterDirection = 1;
  static const _filterOrder = ['ALL', 'IN_STOCK', 'LOW', 'OUT'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? storeId = context.read<UserProvider?>()?.storeId;
      if (storeId == null || storeId.isEmpty) {
        try {
          final myStore = await StoresApiService().getMyStore();
          storeId = (myStore['storeId'] ?? myStore['id'])?.toString();
        } catch (_) {}
      }
      final raw = await ProductsApiService().getProducts(storeId: storeId);
      final list = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      context.read<NotificationProvider?>()?.syncInventoryAlerts(list);
      setState(() {
        _products = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải danh sách sản phẩm của cửa hàng.';
        _loading = false;
      });
    }
  }

  String _formatVnd(dynamic value) {
    final numVal = num.tryParse(value?.toString() ?? '') ?? 0;
    final str = numVal.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final pos = str.length - i;
      buf.write(str[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return '${buf.toString()} ₫';
  }

  int _availableStock(Map<String, dynamic> p) {
    final inv = p['inventory'];
    final onHand =
        int.tryParse(
          ((inv is Map ? inv['quantityOnHand'] : null) ??
                  p['stockQuantity'] ??
                  p['stock'] ??
                  p['availableQuantity'] ??
                  0)
              .toString(),
        ) ??
        0;
    final reserved =
        int.tryParse(
          ((inv is Map
                      ? (inv['reservedQuantity'] ?? inv['quantityReserved'])
                      : null) ??
                  p['reservedQuantity'] ??
                  p['reservedStock'] ??
                  0)
              .toString(),
        ) ??
        0;
    return (onHand - reserved) < 0 ? 0 : (onHand - reserved);
  }

  int _minStockAlert(Map<String, dynamic> p) {
    final inv = p['inventory'];
    return int.tryParse(
          ((inv is Map ? inv['minStockAlert'] : null) ??
                  p['minStockAlert'] ??
                  p['lowStockThreshold'] ??
                  5)
              .toString(),
        ) ??
        5;
  }

  Widget _kpiCard(String label, int value, Color color) {
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
                fontSize: 17.5,
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

  Widget _stockChip(String label, String key) {
    final active = _stockFilter == key;
    return TactilePress(
      scaleDown: 0.95,
      haptic: true,
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (_stockFilter == key) return;
        final oldIdx = _filterOrder.indexOf(_stockFilter);
        final newIdx = _filterOrder.indexOf(key);
        setState(() {
          _filterDirection = newIdx >= oldIdx ? 1 : -1;
          _stockFilter = key;
        });
      },
      child: AnimatedContainer(
        duration: AppMotion.fastDuration,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF047857) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF047857) : const Color(0xFFE2E8F0),
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

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider?>();
    final outOfStockItems = _products
        .where((p) => _availableStock(p) <= 0)
        .toList();
    final lowStockItems = _products.where((p) {
      final avail = _availableStock(p);
      return avail > 0 && avail <= _minStockAlert(p);
    }).toList();

    final filtered = _products.where((p) {
      final avail = _availableStock(p);
      final minAlert = _minStockAlert(p);
      if (_stockFilter == 'OUT' && avail > 0) return false;
      if (_stockFilter == 'LOW' && (avail <= 0 || avail > minAlert)) {
        return false;
      }
      if (_stockFilter == 'IN_STOCK' && avail <= minAlert) return false;

      if (_search.trim().isNotEmpty) {
        final q = _search.trim().toLowerCase();
        final name = (p['name'] ?? p['productName'] ?? '')
            .toString()
            .toLowerCase();
        final sku = (p['sku'] ?? p['productCode'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(q) || sku.contains(q);
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
            onRefresh: _loadProducts,
            color: const Color(0xFF047857),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sản phẩm & tồn kho', style: SampleA.title),
                          const SizedBox(height: 4),
                          Text(
                            userProv?.storeName?.isNotEmpty == true
                                ? '${userProv!.storeName!} • ${_products.length} sản phẩm'
                                : '${_products.length} sản phẩm đang quản lý',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _loadProducts,
                      icon: const Icon(LucideIcons.refreshCw, size: 20),
                      tooltip: 'Làm mới',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _kpiCard('Tổng SP', _products.length, const Color(0xFF047857)),
                    const SizedBox(width: 10),
                    _kpiCard('Sắp hết', lowStockItems.length, const Color(0xFFD97706)),
                    const SizedBox(width: 10),
                    _kpiCard('Hết hàng', outOfStockItems.length, const Color(0xFFDC2626)),
                  ],
                ),
                const SizedBox(height: 14),
                if (!_loading &&
                    (outOfStockItems.isNotEmpty || lowStockItems.isNotEmpty)) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: outOfStockItems.isNotEmpty
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: outOfStockItems.isNotEmpty
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          size: 20,
                          color: outOfStockItems.isNotEmpty
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                outOfStockItems.isNotEmpty
                                    ? 'Cảnh báo: ${outOfStockItems.length} sản phẩm đã HẾT HÀNG!'
                                    : 'Cảnh báo: ${lowStockItems.length} sản phẩm sắp hết hàng!',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: outOfStockItems.isNotEmpty
                                      ? const Color(0xFF991B1B)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                              if (outOfStockItems.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Hết hàng: ${outOfStockItems.take(4).map((p) => p['name'] ?? p['productName']).join(', ')}${outOfStockItems.length > 4 ? '...' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB91C1C),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (lowStockItems.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Sắp hết: ${lowStockItems.take(4).map((p) => '${p['name'] ?? p['productName']} (còn ${_availableStock(p)})').join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB45309),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm tên sản phẩm hoặc mã SKU...',
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _stockChip('Tất cả', 'ALL'),
                      const SizedBox(width: 8),
                      _stockChip('Còn hàng', 'IN_STOCK'),
                      const SizedBox(width: 8),
                      _stockChip('Sắp hết', 'LOW'),
                      const SizedBox(width: 8),
                      _stockChip('Hết hàng', 'OUT'),
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
                                height: 82,
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
                              height: 82,
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
                        AButton(label: 'Thử lại', onPressed: _loadProducts),
                      ],
                    ),
                  )
                else
                  AppSlideSwitcher(
                    direction: _filterDirection,
                    child: Column(
                      key: ValueKey('products_$_stockFilter'),
                      children: [
                        if (filtered.isEmpty)
                          ACard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Column(
                                children: [
                                  const Icon(
                                    LucideIcons.packageOpen,
                                    size: 40,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _products.isEmpty
                                        ? 'Chưa có sản phẩm nào'
                                        : 'Không có sản phẩm khớp bộ lọc',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Sản phẩm thêm trên Web Quản lý cửa hàng sẽ tự động đồng bộ tại đây.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filtered.map((p) {
                    final name = (p['name'] ?? p['productName'] ?? 'Sản phẩm')
                        .toString();
                    final sku = (p['sku'] ?? p['productCode'] ?? '').toString();
                    final price = p['basePrice'] ?? p['price'] ?? 0;
                    final stock = _availableStock(p);
                    final minAlert = _minStockAlert(p);
                    final isOut = stock <= 0;
                    final isLow = !isOut && stock <= minAlert;
                    final status = (p['status'] ?? 'ACTIVE')
                        .toString()
                        .toUpperCase();
                    final img = (p['thumbnailUrl'] ?? p['imageUrl'] ?? '')
                        .toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: AppMotion.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: img.isNotEmpty
                                ? Image.network(
                                    img,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      LucideIcons.package,
                                      color: Color(0xFF047857),
                                    ),
                                  )
                                : const Icon(
                                    LucideIcons.package,
                                    color: Color(0xFF047857),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (sku.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'SKU: $sku',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      _formatVnd(price),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF047857),
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOut || status != 'ACTIVE'
                                            ? const Color(0xFFFEF2F2)
                                            : isLow
                                            ? const Color(0xFFFFFBEB)
                                            : const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isOut
                                            ? 'Hết hàng'
                                            : isLow
                                            ? 'Sắp hết: $stock'
                                            : 'Tồn kho: $stock',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isOut || status != 'ACTIVE'
                                              ? const Color(0xFFDC2626)
                                              : isLow
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF047857),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
