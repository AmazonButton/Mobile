import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/sample_a.dart';
import '../widgets/smart_order_tour.dart';
import 'home/widgets/home_quick_shop_shelf.dart';

/// Màn hình Mua sắm — Khám phá cửa hàng (mở khi bấm nút "Mua sắm").
class ShopStoresScreen extends StatelessWidget {
  final SmartOrderTour? tour;

  const ShopStoresScreen({super.key, this.tour});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mua sắm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: AContent(
        maxWidth: SampleA.listWidth,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: HomeQuickShopShelf(tour: tour),
        ),
      ),
    );
  }
}
