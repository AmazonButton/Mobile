import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/button_product_model.dart';

/// Minimalist Product Selection Bottom Sheet matching Screen 3 in the design.
class ProductSelectionSheet extends StatefulWidget {
  final String buttonName;
  final String currentProductName;
  final Function(ButtonProductModel selectedProduct) onSave;

  const ProductSelectionSheet({
    super.key,
    required this.buttonName,
    required this.currentProductName,
    required this.onSave,
  });

  /// Opens the Product Selection bottom sheet.
  static Future<ButtonProductModel?> show({
    required BuildContext context,
    required String buttonName,
    required String currentProductName,
    required Function(ButtonProductModel selectedProduct) onSave,
  }) {
    return showModalBottomSheet<ButtonProductModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => ProductSelectionSheet(
        buttonName: buttonName,
        currentProductName: currentProductName,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<ProductSelectionSheet> {
  late final List<ButtonProductModel> _products;
  late ButtonProductModel _selectedProduct;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả'; // 'Tất cả', 'Nước uống', 'Gas'

  final List<String> _categories = const ['Tất cả', 'Nước uống', 'Gas'];

  @override
  void initState() {
    super.initState();
    _products = ButtonProductModel.sampleProducts;

    // Find initially selected product or default to first
    _selectedProduct = _products.firstWhere(
      (p) =>
          p.shortName.toLowerCase() == widget.currentProductName.toLowerCase() ||
          p.name.toLowerCase().contains(widget.currentProductName.toLowerCase()) ||
          widget.currentProductName.toLowerCase().contains(p.shortName.toLowerCase()),
      orElse: () => _products.first,
    );
  }

  bool _isProductGas(ButtonProductModel p) {
    final lower = '${p.shortName} ${p.name} ${p.category}'.toLowerCase();
    return lower.contains('gas') || lower.contains('petrolimex') || lower.contains('saigon petro');
  }

  List<ButtonProductModel> get _filteredProducts {
    return _products.where((p) {
      // Category filter
      if (_selectedCategory == 'Nước uống') {
        final lower = '${p.shortName} ${p.name} ${p.category}'.toLowerCase();
        if (_isProductGas(p) || lower.contains('gạo') || lower.contains('rice')) {
          return false;
        }
      } else if (_selectedCategory == 'Gas') {
        if (!_isProductGas(p)) return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = p.name.toLowerCase().contains(q) ||
            p.shortName.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _handleSave() {
    HapticFeedback.mediumImpact();
    widget.onSave(_selectedProduct);
    Navigator.of(context).pop(_selectedProduct);
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
                      Text(
                        'Cấu hình ${widget.buttonName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
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
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
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
                          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Freeship Notification ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.check,
                    size: 15,
                    color: Color(0xFF16A34A),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Freeship cho đơn từ 150.000đ',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Scrollable Radio Cards List ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                physics: const BouncingScrollPhysics(),
                children: _filteredProducts.map((product) {
                  final isSelected = product.id == _selectedProduct.id;
                  final isGas = _isProductGas(product);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedProduct = product);
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
                                  isGas ? LucideIcons.flame : LucideIcons.droplets,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(height: 3),
                                  Text(
                                    product.priceFormatted,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                  // Selected Item Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                            _selectedProduct.shortName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _selectedProduct.priceFormatted,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Save Changes Button
                  GestureDetector(
                    onTap: _handleSave,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Lưu thay đổi',
                            style: TextStyle(
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
