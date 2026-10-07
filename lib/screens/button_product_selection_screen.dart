import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../models/button_product_model.dart';

enum ProductSortOption {
  popular('Phổ biến nhất'),
  priceAsc('Giá: Thấp đến cao'),
  priceDesc('Giá: Cao đến thấp'),
  rating('Đánh giá cao nhất');

  final String label;
  const ProductSortOption(this.label);
}

class ButtonProductSelectionScreen extends StatefulWidget {
  final String buttonName;
  final String room;
  final String currentProductName;
  final Function(ButtonProductModel selectedProduct, String updatedRoom)? onSave;

  const ButtonProductSelectionScreen({
    super.key,
    required this.buttonName,
    required this.room,
    required this.currentProductName,
    this.onSave,
  });

  /// Static helper to navigate to this screen cleanly
  static Future<Map<String, dynamic>?> open({
    required BuildContext context,
    required String buttonName,
    required String room,
    required String currentProductName,
    Function(ButtonProductModel selectedProduct, String updatedRoom)? onSave,
  }) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (ctx) => ButtonProductSelectionScreen(
          buttonName: buttonName,
          room: room,
          currentProductName: currentProductName,
          onSave: onSave,
        ),
      ),
    );

    if (result != null && onSave != null) {
      onSave(result['product'] as ButtonProductModel, result['room'] as String);
    }
    return result;
  }

  @override
  State<ButtonProductSelectionScreen> createState() => _ButtonProductSelectionScreenState();
}

class _ButtonProductSelectionScreenState extends State<ButtonProductSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  late TextEditingController _roomController;
  final Set<String> _expandedProductIds = {};

  ProductSortOption _currentSort = ProductSortOption.popular;
  late ButtonProductModel _selectedProduct;
  List<ButtonProductModel> _allProducts = [];
  List<ButtonProductModel> _filteredProducts = [];
  String _selectedCategory = 'Tất cả';
  bool _isEditingRoom = false;

  final List<String> _categories = [
    'Tất cả',
    'Nhu yếu phẩm',
    'Nước uống',
    'Gia vị & Bếp',
    'Chăm sóc nhà cửa',
  ];

  @override
  void initState() {
    super.initState();
    _roomController = TextEditingController(text: widget.room);
    _allProducts = ButtonProductModel.sampleProducts;

    // Find initially selected product by matching shortName or name
    final matched = _allProducts.firstWhere(
      (p) =>
          p.shortName.toLowerCase() == widget.currentProductName.toLowerCase() ||
          p.name.toLowerCase().contains(widget.currentProductName.toLowerCase()) ||
          widget.currentProductName.toLowerCase().contains(p.shortName.toLowerCase()),
      orElse: () => _allProducts.first,
    );
    _selectedProduct = matched;
    _filteredProducts = List.from(_allProducts);
    _sortProducts();

    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        // Category filter
        final matchCategory = _selectedCategory == 'Tất cả' ||
            p.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
            (_selectedCategory == 'Nước uống' && p.category.toLowerCase().contains('nước')) ||
            (_selectedCategory == 'Gia vị & Bếp' &&
                (p.category.toLowerCase().contains('gia vị') || p.category.toLowerCase().contains('bếp'))) ||
            (_selectedCategory == 'Chăm sóc nhà cửa' &&
                (p.category.toLowerCase().contains('chăm sóc') || p.category.toLowerCase().contains('vệ sinh')));

        if (!matchCategory) return false;

        // Query filter
        if (query.isEmpty) return true;
        return p.name.toLowerCase().contains(query) ||
            p.shortName.toLowerCase().contains(query) ||
            p.brand.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query) ||
            p.specs.toLowerCase().contains(query);
      }).toList();

      _sortProducts();
    });
  }

  void _sortProducts() {
    switch (_currentSort) {
      case ProductSortOption.popular:
        _filteredProducts.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case ProductSortOption.priceAsc:
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceDesc:
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.rating:
        _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
  }

  void _showSortPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Sắp xếp sản phẩm theo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ...ProductSortOption.values.map((option) {
                final isSelected = _currentSort == option;
                return ListTile(
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : const Color(0xFF334155),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(LucideIcons.check, color: AppColors.primary, size: 18)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentSort = option;
                      _sortProducts();
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave() {
    HapticFeedback.mediumImpact();
    final updatedRoom = _roomController.text.trim();
    if (widget.onSave != null) {
      widget.onSave!(_selectedProduct, updatedRoom);
    }
    Navigator.pop(context, {
      'product': _selectedProduct,
      'room': updatedRoom,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── 1. HEADER: ROOM LOCATION & AMAZON DASH NOTICE ──
          _buildTopContextSection(),

          // ── 2. SEARCH & SORT BAR ──
          _buildSearchAndSortBar(),

          // ── 3. CATEGORY QUICK FILTERS ──
          _buildCategoryFilterBar(),

          const SizedBox(height: 6),

          // ── 4. PRODUCT LIST ──
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final product = _filteredProducts[index];
                      final isSelected = product.id == _selectedProduct.id;
                      final isExpanded = _expandedProductIds.contains(product.id);

                      return _buildProductCard(
                        product: product,
                        isSelected: isSelected,
                        isExpanded: isExpanded,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A), size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Cấu hình ${widget.buttonName}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Text(
                  'IoT Button',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Chọn sản phẩm tự động đặt khi nhấn nút vật lý',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
    );
  }

  Widget _buildTopContextSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Room Location Row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _isEditingRoom
                    ? Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: TextField(
                                controller: _roomController,
                                autofocus: true,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(LucideIcons.check, size: 18, color: Color(0xFF10B981)),
                            onPressed: () => setState(() => _isEditingRoom = false),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: () => setState(() => _isEditingRoom = true),
                        child: Row(
                          children: [
                            Text(
                              'Vị trí: ${_roomController.text}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(LucideIcons.pencil, size: 12, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Dash Smart Reorder Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF16A34A)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sản phẩm được chọn sẽ tự động tạo đơn hàng mỗi khi bạn nhấn nút vật lý. Ưu đãi chiết khấu áp dụng tự động.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF166534),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: 'Tìm sản phẩm (vd: Lavie, Gas, Pulppy...)',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchController.clear(),
                          child: const Icon(LucideIcons.xCircle, size: 16, color: Color(0xFF94A3B8)),
                        )
                      : null,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Sort Dropdown Button
          GestureDetector(
            onTap: _showSortPicker,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.slidersHorizontal, size: 14, color: Color(0xFF475569)),
                  const SizedBox(width: 6),
                  const Text(
                    'Sắp xếp',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
                _filterProducts();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard({
    required ButtonProductModel product,
    required bool isSelected,
    required bool isExpanded,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedProduct = product);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail / Product Icon ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: product.themeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: product.themeColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      product.icon,
                      size: 36,
                      color: product.themeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Center Content Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge if any
                      if (product.badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEA580C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                product.badge!,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC2410C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],

                      // Full Product Title
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Price & Unit Price & Delivery Badge (Responsive Wrap)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            product.priceFormatted,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            product.unitPriceFormatted,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFDCFCE7)),
                            ),
                            child: Text(
                              product.deliveryTag,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      const Text(
                        '+ Đã gồm thuế & hỗ trợ vác lầu',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Smart Reorder Discount Tag (Overflow-Proof with Flexible) ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.tag, size: 11, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.discountTag,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Rating Stars & Review Count
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (starIndex) => const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${product.rating} (${product.reviewCount})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // ── Right Radio Button ──
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                      width: isSelected ? 6.5 : 1.8,
                    ),
                  ),
                ),
              ],
            ),

            // ── See More / Collapse ──
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedProductIds.remove(product.id);
                  } else {
                    _expandedProductIds.add(product.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? 'Thu gọn thông số' : '∨ Xem chi tiết sản phẩm',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    if (isExpanded)
                      const Icon(LucideIcons.chevronUp, size: 13, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),

            // Expanded Description Details
            if (isExpanded) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quy cách: ${product.specs}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.searchX, size: 28, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Không tìm thấy sản phẩm phù hợp',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hãy thử tìm bằng từ khóa khác hoặc chọn danh mục "Tất cả"',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedCategory = 'Tất cả';
                _filterProducts();
              });
            },
            child: const Text('Đặt lại bộ lọc tìm kiếm'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected Product Summary Row
            Row(
              children: [
                const Text(
                  'Đã chọn: ',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                Expanded(
                  child: Text(
                    '${_selectedProduct.shortName} • ${_selectedProduct.priceFormatted}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Save CTA Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
