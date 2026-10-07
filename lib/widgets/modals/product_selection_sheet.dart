import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/button_product_model.dart';

/// Reusable tactile bounce helper: scales down to 0.96 on tap.
class _TactileBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TactileBounce({required this.child, this.onTap});

  @override
  State<_TactileBounce> createState() => _TactileBounceState();
}

class _TactileBounceState extends State<_TactileBounce> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Standalone Product Selection Bottom Sheet conforming to Apple / Big Tech standards.
///
/// Features:
/// - Exact 85% height of screen with sticky persistent bottom bar
/// - Radio cards with pure white / #EFF6FF background & #1D4ED8 active border
/// - LucideIcons.checkCircle2 & LucideIcons.circle for radio indicators
/// - Promotional tags ("Freeship đơn từ 150k") with light green backgrounds
/// - Massive dark blue "Lưu thay đổi" button with tactile bounce (0.96 scale)
/// - Sequential card entry animations (flutter_animate)
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

  /// Opens the Product Selection bottom sheet (85% screen height).
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
      barrierColor: Colors.black.withValues(alpha: 0.4),
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

  String _getProductImage(ButtonProductModel p) {
    final lower = '${p.shortName} ${p.name}'.toLowerCase();
    if (lower.contains('petrolimex')) {
      return 'https://images.unsplash.com/photo-1584281722572-881585869106?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('saigon petro') || lower.contains('gas')) {
      return 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('st25') || lower.contains('gạo')) {
      return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('aquafina')) {
      return 'https://images.unsplash.com/photo-1560023907-5f339617ea30?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('omo')) {
      return 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('pulppy')) {
      return 'https://images.unsplash.com/photo-1584556812952-905ffd0c611a?w=200&auto=format&fit=crop&q=80';
    }
    if (lower.contains('vihawa')) {
      return 'https://images.unsplash.com/photo-1527661591475-527312dd65f5?w=200&auto=format&fit=crop&q=80';
    }
    return 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=200&auto=format&fit=crop&q=80';
  }

  List<ButtonProductModel> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.shortName.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
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
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Slate 50
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          children: [
            // ── Top Drag Handle & Header ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
              child: Column(
                children: [
                  // Drag indicator
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cấu hình ${widget.buttonName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Chọn sản phẩm tự động chốt đơn khi bấm nút',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      _TactileBounce(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.x,
                              size: 18,
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            // ── Search & Filter Row ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      size: 17,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tìm theo tên sản phẩm, danh mục...',
                          hintStyle: TextStyle(
                            fontSize: 13,
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // ── Scrollable Radio Cards List ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                physics: const BouncingScrollPhysics(),
                children: _filteredProducts.map((product) {
                  final isSelected = product.id == _selectedProduct.id;
                  final imageUrl = _getProductImage(product);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRadioProductCard(
                      product: product,
                      imageUrl: imageUrl,
                      isSelected: isSelected,
                    ),
                  );
                }).toList()
                    .animate(interval: 50.ms)
                    .fade(duration: 300.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
              ),
            ),

            // ── Sticky Persistent Bottom Bar ──
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                max(20.0, bottomSafeArea + 10) + bottomInset,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selected item summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Đã chọn: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _selectedProduct.shortName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _selectedProduct.priceFormatted,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8), // Primary Blue
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Massive dark blue Save Changes button with tactile bounce
                  _TactileBounce(
                    onTap: _handleSave,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8), // Primary Blue (Deep)
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.checkCircle2,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Lưu thay đổi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildRadioProductCard({
    required ButtonProductModel product,
    required String imageUrl,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedProduct = product);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFF6FF) // Subtle blue tint
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1D4ED8) // Primary Blue
                : const Color(0xFFE2E8F0), // Thin gray border
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Product Thumbnail
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFBFDBFE)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: const Color(0xFFE2E8F0),
                    highlightColor: const Color(0xFFF8FAFC),
                    child: Container(color: const Color(0xFFE2E8F0)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: Icon(
                        LucideIcons.package,
                        size: 22,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Info Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.shortName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.specs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price + Promotional Tag Row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        product.priceFormatted,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      // Promotional Tag: "Freeship đơn từ 150k" or product tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5), // Light green bg
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFA7F3D0), // Border light green
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'Freeship đơn từ 150k',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857), // Green text
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. Trailing Radio Icon
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF1D4ED8), // Primary Blue
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.checkCircle2,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              )
            else
              const Icon(
                LucideIcons.circle,
                size: 22,
                color: Color(0xFFCBD5E1), // Gray outline
              ),
          ],
        ),
      ),
    );
  }
}
