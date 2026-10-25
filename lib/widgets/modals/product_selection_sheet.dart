import '../../services/stock_service.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/button_product_model.dart';
import '../../services/api_client.dart';
import '../../services/devices_api_service.dart';
import '../../services/products_api_service.dart';

/// Minimalist Product Selection Bottom Sheet matching Screen 3 in the design.
class ProductSelectionSheet extends StatefulWidget {
  final String buttonName;
  final String currentProductName;
  final String? deviceId;
  final FutureOr<void> Function(
    ButtonProductModel selectedProduct,
    int quantity,
  )
  onSave;

  const ProductSelectionSheet({
    super.key,
    required this.buttonName,
    required this.currentProductName,
    this.deviceId,
    required this.onSave,
  });

  /// Opens the Product Selection bottom sheet.
  static Future<ButtonProductModel?> show({
    required BuildContext context,
    required String buttonName,
    required String currentProductName,
    String? deviceId,
    required FutureOr<void> Function(
      ButtonProductModel selectedProduct,
      int quantity,
    )
    onSave,
  }) {
    return showModalBottomSheet<ButtonProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => ProductSelectionSheet(
        buttonName: buttonName,
        currentProductName: currentProductName,
        deviceId: deviceId,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<ProductSelectionSheet>
    with WidgetsBindingObserver {
  List<ButtonProductModel> _products = [];
  ButtonProductModel? _selectedProduct;
  int _quantity = 1;
  bool get _canSave =>
      _loadError == null &&
      !_isLoading &&
      !_isSaving &&
      _selectedProduct?.stock != null &&
      _quantity > 0 &&
      _quantity <= _selectedProduct!.stock!.available;
  bool _initialized = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';

  List<String> get _categories => [
    'Tất cả',
    ..._products.map((p) => p.category).toSet(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProducts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isSaving && !_isLoading) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final deviceId = widget.deviceId;
      if (deviceId == null || deviceId.isEmpty) {
        throw StateError('Missing device');
      }
      final device = await DevicesApiService().getDeviceById(deviceId);
      final storeId = device['storeId']?.toString();
      if (storeId == null || storeId.isEmpty) throw StateError('Missing store');
      final rows = await ProductsApiService().getProducts(storeId: storeId);
      for (final row in rows.whereType<Map>()) {
        StockService.instance.remember(
          (row['productId'] ?? row['id']).toString(),
          row['inventory'],
        );
      }
      final products = rows
          .whereType<Map>()
          .where(
            (p) =>
                p['status'] == 'ACTIVE' && p['storeId']?.toString() == storeId,
          )
          .map((p) => ButtonProductModel.fromJson(Map<String, dynamic>.from(p)))
          .toList();
      final mappings = device['products'] ?? device['buttonProducts'];
      String? currentId;
      int savedQuantity = 1;
      if (mappings is List && mappings.isNotEmpty && mappings.first is Map) {
        savedQuantity =
            int.tryParse(mappings.first['quantity'].toString()) ?? 1;
        currentId =
            (mappings.first['productId'] ??
                    mappings.first['product']?['productId'])
                ?.toString();
      }
      ButtonProductModel? selected;
      for (final product in products) {
        if (product.id == currentId ||
            (currentId == null && product.name == widget.currentProductName)) {
          selected = product;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _products = products;
        if (!_initialized) {
          _selectedProduct = selected;
          _quantity = savedQuantity;
          _initialized = true;
        } else {
          final id = _selectedProduct?.id;
          _selectedProduct = products.where((p) => p.id == id).firstOrNull;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Không thể tải sản phẩm của cửa hàng. Vui lòng thử lại.';
      });
    }
  }

  bool _isProductGas(ButtonProductModel p) {
    final lower = '${p.shortName} ${p.name} ${p.category}'.toLowerCase();
    return lower.contains('gas') ||
        lower.contains('petrolimex') ||
        lower.contains('saigon petro');
  }

  List<ButtonProductModel> get _filteredProducts {
    return _products.where((p) {
      // Category filter
      if (_selectedCategory != 'Tất cả' && p.category != _selectedCategory) {
        return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches =
            p.name.toLowerCase().contains(q) ||
            p.shortName.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _handleSave() async {
    final product = _selectedProduct;
    if (product == null || !_canSave) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(product, _quantity);
      if (mounted) Navigator.of(context).pop(product);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = error is ApiException
            ? error.message
            : 'Không thể lưu sản phẩm. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          children: [
            // ── Top Header with Drag Handle ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Cấu hình ${widget.buttonName}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tìm theo tên sản phẩm, danh mục',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _searchQuery = ''),
                        child: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Category Filter Chips ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = category);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0F172A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Freeship Notification ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(LucideIcons.check, size: 15, color: Color(0xFF16A34A)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Freeship cho đơn từ 150.000đ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Scrollable Radio Cards List ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_loadError!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: _loadProducts,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  : _filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        _products.isEmpty
                            ? 'Cửa hàng chưa có sản phẩm đang bán'
                            : 'Không tìm thấy sản phẩm',
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      physics: const BouncingScrollPhysics(),
                      children: _filteredProducts.map((product) {
                        final isSelected = product.id == _selectedProduct?.id;
                        final isGas = _isProductGas(product);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap:
                                _isSaving ||
                                    product.stock == null ||
                                    product.stock!.available == 0
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (_selectedProduct?.id != product.id) {
                                        _quantity = 1;
                                      }
                                      _selectedProduct = product;
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.6 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icon Box
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isGas
                                          ? const Color(0xFFFFF7ED)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isGas
                                            ? LucideIcons.flame
                                            : LucideIcons.droplets,
                                        size: 20,
                                        color: isGas
                                            ? const Color(0xFFEA580C)
                                            : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Product Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.shortName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          product.stock?.label() ??
                                              'Chưa kiểm tra được tồn kho',
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          product.priceFormatted,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Radio Check Icon
                                  if (isSelected)
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          LucideIcons.check,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFCBD5E1),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),

            // ── Sticky Persistent Bottom Bar ──
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                max(20.0, bottomSafeArea + 12) + bottomInset,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedProduct != null) ...[
                    Row(
                      children: [
                        const Expanded(child: Text('Số lượng')),
                        IconButton(
                          tooltip: 'Giảm số lượng',
                          onPressed: !_isSaving && _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$_quantity'),
                        IconButton(
                          tooltip: 'Tăng số lượng',
                          onPressed:
                              !_isSaving &&
                                  _quantity <
                                      (_selectedProduct?.stock?.available ?? 0)
                              ? () => setState(() => _quantity++)
                              : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    Text(
                      _selectedProduct?.stock?.label(_quantity) ??
                          'Chưa kiểm tra được tồn kho',
                    ),
                  ],
                  TextButton(
                    onPressed: _isSaving || _isLoading ? null : _loadProducts,
                    child: const Text('Kiểm tra lại tồn kho'),
                  ),
                  // Selected Item Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đã chọn',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedProduct?.shortName ?? 'Chọn sản phẩm',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _selectedProduct?.priceFormatted ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _saveError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Save Changes Button
                  GestureDetector(
                    onTap: !_canSave ? null : _handleSave,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: !_canSave
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
