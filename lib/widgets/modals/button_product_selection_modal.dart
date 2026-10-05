import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../constants/app_colors.dart';
import '../../models/button_product_model.dart';

enum ProductSortOption {
  popular('Phổ biến nhất'),
  priceAsc('Giá: Thấp đến cao'),
  priceDesc('Giá: Cao đến thấp'),
  rating('Đánh giá cao nhất');

  final String label;
  const ProductSortOption(this.label);
}

class ButtonProductSelectionModal extends StatefulWidget {
  final String buttonName;
  final String room;
  final String currentProductName;
  final Function(ButtonProductModel selectedProduct, String updatedRoom) onSave;

  const ButtonProductSelectionModal({
    super.key,
    required this.buttonName,
    required this.room,
    required this.currentProductName,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String buttonName,
    required String room,
    required String currentProductName,
    required Function(ButtonProductModel selectedProduct, String updatedRoom) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ButtonProductSelectionModal(
        buttonName: buttonName,
        room: room,
        currentProductName: currentProductName,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ButtonProductSelectionModal> createState() => _ButtonProductSelectionModalState();
}

class _ButtonProductSelectionModalState extends State<ButtonProductSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  late TextEditingController _roomController;
  final Set<String> _expandedProductIds = {};
  
  ProductSortOption _currentSort = ProductSortOption.popular;
  late ButtonProductModel _selectedProduct;
  List<ButtonProductModel> _allProducts = [];
  List<ButtonProductModel> _filteredProducts = [];
  bool _isEditingRoom = false;

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

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_allProducts);
      } else {
        _filteredProducts = _allProducts.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.shortName.toLowerCase().contains(query) ||
              p.brand.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query) ||
              p.specs.toLowerCase().contains(query);
        }).toList();
      }
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
    widget.onSave(_selectedProduct, _roomController.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── 1. DRAG HANDLE ──
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── 2. HEADER: TÊN THIẾT BỊ & NÚT ĐÓNG ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Cấu hình ${widget.buttonName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'IoT Button',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Room indicator / editor
                    _buildRoomRow(),
                  ],
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
                    child: const Icon(LucideIcons.x, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // ── 3. AMAZON DASH NOTICE BANNER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sản phẩm được chọn sẽ tự động tạo đơn hàng mỗi khi bạn nhấn nút vật lý. Ưu đãi chiết khấu áp dụng tự động.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. SEARCH & SORT BAR (AMAZON DASH FORMAT) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        hintText: 'Tìm sản phẩm (vd: Lavie, Gas, Gạo...)',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(LucideIcons.search, size: 17, color: Color(0xFF94A3B8)),
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
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sort',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronDown, size: 15, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 5. PRODUCT LIST (AMAZON DASH FORMAT CARDS) ──
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 16),
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

          // ── 6. BOTTOM ACTION BAR (STICKY) ──
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildRoomRow() {
    if (_isEditingRoom) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            height: 28,
            child: TextField(
              controller: _roomController,
              autofocus: true,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.check, size: 16, color: Color(0xFF10B981)),
            onPressed: () => setState(() => _isEditingRoom = false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _isEditingRoom = true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            'Vị trí: ${_roomController.text}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(LucideIcons.pencil, size: 11, color: Color(0xFF94A3B8)),
        ],
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
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 10 : 4,
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
                // ── Thumbnail / Product Icon Container ──
                Container(
                  width: 78,
                  height: 78,
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
                      size: 34,
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
                      // Badge if any (e.g. Most Popular)
                      if (product.badge != null) ...[
                        Row(
                          children: [
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
                          ],
                        ),
                        const SizedBox(height: 5),
                      ],

                      // Full Product Title
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Price & Unit Price & Delivery Badge
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
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
                      const SizedBox(height: 3),

                      const Text(
                        '+ Đã gồm thuế & hỗ trợ vác lầu',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Smart Reorder Discount Tag (Amazon Dash Extra % off)
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
                            Text(
                              product.discountTag,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
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
                      isExpanded ? 'Thu gọn' : '∨ Xem chi tiết sản phẩm',
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
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.searchX, size: 26, color: Color(0xFF94A3B8)),
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
            'Hãy thử tìm bằng từ khóa khác (ví dụ: Lavie, Gas, Gạo)',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _searchController.clear(),
            child: const Text('Xóa bộ lọc tìm kiếm'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                Expanded(
                  child: Text(
                    '${_selectedProduct.shortName} • ${_selectedProduct.priceFormatted}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Save Button
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
                    fontSize: 14,
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
