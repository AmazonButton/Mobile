import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/device_model.dart';
import '../services/products_api_service.dart';
import '../models/button_product_model.dart';

class StoreCatalogScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  const StoreCatalogScreen({super.key, required this.store});
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
          uri.host.isNotEmpty)
        return uri.toString();
    }
    return null;
  }

  Future<void> _assign(Map<String, dynamic> raw) async {
    if (_assigning) return;
    setState(() => _assigning = true);
    try {
      final provider = context.read<DeviceProvider>();
      final product = ButtonProductModel.fromJson(raw);
      Future<List<DeviceModel>> load() async {
        await provider.loadDevices().timeout(const Duration(seconds: 15));
        if (provider.errorMessage != null)
          throw StateError('Không thể tải nút bấm');
        return provider.devices.where((d) => d.storeId == _storeId).toList();
      }

      final cached = provider.devices
          .where((d) => d.storeId == _storeId)
          .toList();
      Future<List<DeviceModel>> pending = cached.isNotEmpty
          ? Future.value(cached)
          : load();
      final selected = await showModalBottomSheet<DeviceModel>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .75,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Thêm ${product.name} vào nút',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<DeviceModel>>(
                      future: pending,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done)
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Đang tải nút bấm...'),
                              ],
                            ),
                          );
                        if (snapshot.hasError)
                          return Column(
                            children: [
                              const Text(
                                'Không thể tải nút bấm. Vui lòng thử lại.',
                              ),
                              TextButton(
                                onPressed: () =>
                                    setSheetState(() => pending = load()),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          );
                        final devices = snapshot.data ?? [];
                        if (devices.isEmpty)
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Bạn chưa sở hữu nút bấm của cửa hàng này.',
                            ),
                          );
                        return Column(
                          children: [
                            for (final device in devices)
                              ListTile(
                                leading: const Icon(Icons.touch_app_outlined),
                                title: Text(device.name),
                                subtitle: Text(device.product),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () =>
                                    Navigator.pop(sheetContext, device),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (selected == null || !mounted) return;
      // Recheck the current association before sending the customer-config request.
      if (!provider.devices.any(
        (d) => d.id == selected.id && d.storeId == _storeId,
      )) {
        throw StateError('Nút không còn thuộc cửa hàng này');
      }
      await provider.updateDeviceProduct(selected.id, product, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${product.name} vào ${selected.name}')),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thêm sản phẩm vào nút. Vui lòng thử lại.'),
          ),
        );
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
      body: RefreshIndicator(
        onRefresh: () async {
          final future = _load();
          setState(() => _products = future);
          await future;
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F0FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    size: 42,
                    color: Color(0xFF477BB9),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.store['name']?.toString() ?? 'Cửa hàng',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.store['address']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${distance.toStringAsFixed(1)} km đường thẳng từ địa chỉ của bạn',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm',
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
                if (snapshot.connectionState != ConnectionState.done)
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                if (snapshot.hasError)
                  return Column(
                    children: [
                      const Text('Không thể tải sản phẩm của cửa hàng.'),
                      TextButton(
                        onPressed: () => setState(() => _products = _load()),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  );
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sản phẩm',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('${products.length} sản phẩm'),
                      ],
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
                          final width = (constraints.maxWidth - 16) / 2;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 24,
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
    );
  }

  Widget _productRow(Map<String, dynamic> raw) {
    final product = ButtonProductModel.fromJson(raw);
    final url = _image(raw);
    return InkWell(
      onTap: _assigning ? null : () => _assign(raw),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: url == null
                        ? const Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          )
                        : Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    tooltip: 'Thêm vào nút bấm',
                    onPressed: _assigning ? null : () => _assign(raw),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFB9CCED),
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.add, size: 27),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.priceFormatted,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Color(0xFF333333),
            ),
          ),
          if (raw['unit'] != null || raw['specs'] != null) ...[
            const SizedBox(height: 3),
            Text(
              (raw['specs'] ?? raw['unit']).toString(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF858585)),
            ),
          ],
        ],
      ),
    );
  }
}
