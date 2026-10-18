import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Skeleton loading placeholder with shimmering effect for HomeScreen.
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  Widget _box({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _box(width: 42, height: 42, borderRadius: 21),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 90, height: 12, borderRadius: 6),
                    const SizedBox(height: 6),
                    _box(width: 140, height: 20, borderRadius: 6),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                _box(width: 38, height: 38, borderRadius: 19),
                const SizedBox(width: 8),
                _box(width: 38, height: 38, borderRadius: 19),
                const SizedBox(width: 8),
                _box(width: 38, height: 38, borderRadius: 19),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _box(width: 170, height: 30, borderRadius: 20),
        const SizedBox(height: 24),

        // 2. Active Order Skeleton
        _box(width: double.infinity, height: 56, borderRadius: 20),
        const SizedBox(height: 24),

        // 3. Promo Banner Carousel Skeleton
        _box(width: double.infinity, height: 130, borderRadius: 16),
        const SizedBox(height: 10),
        Center(child: _box(width: 40, height: 5, borderRadius: 4)),
        const SizedBox(height: 24),

        // 4. "Nút bấm của tôi" Skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _box(width: 140, height: 20, borderRadius: 6),
            _box(width: 90, height: 12, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 16),
        _buildDeviceCardSkeleton(),
        const SizedBox(height: 16),
        _buildDeviceCardSkeleton(),
        const SizedBox(height: 24),

        // 5. Predictive Insight Skeleton
        _box(width: double.infinity, height: 60, borderRadius: 20),
        const SizedBox(height: 24),

        // 6. Quick Shop Shelf Skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _box(width: 120, height: 18, borderRadius: 6),
            _box(width: 60, height: 12, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _box(
                width: double.infinity,
                height: 190,
                borderRadius: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _box(
                width: double.infinity,
                height: 190,
                borderRadius: 16,
              ),
            ),
          ],
        ),
      ],
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.7));
  }

  Widget _buildDeviceCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(width: 56, height: 56, borderRadius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 130, height: 16, borderRadius: 6),
                    const SizedBox(height: 6),
                    _box(width: 180, height: 12, borderRadius: 6),
                  ],
                ),
              ),
              _box(width: 36, height: 36, borderRadius: 18),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _box(width: 60, height: 22, borderRadius: 20),
              const SizedBox(width: 8),
              _box(width: 50, height: 22, borderRadius: 20),
              const SizedBox(width: 8),
              _box(width: 60, height: 22, borderRadius: 20),
            ],
          ),
          const SizedBox(height: 16),
          _box(width: double.infinity, height: 46, borderRadius: 14),
        ],
      ),
    );
  }
}
