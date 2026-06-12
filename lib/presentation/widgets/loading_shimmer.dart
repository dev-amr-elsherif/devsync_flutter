import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

class MatchCardShimmer extends StatelessWidget {
  const MatchCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceLight,
      highlightColor: AppTheme.cardBg,
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 140, height: 16),
                      const SizedBox(height: 8),
                      _ShimmerBox(width: 90, height: 12),
                    ],
                  ),
                ),
                _ShimmerBox(width: 44, height: 44, radius: 22),
              ],
            ),
            const SizedBox(height: 16),
            _ShimmerBox(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            _ShimmerBox(width: 200, height: 12),
            const SizedBox(height: 16),
            Row(
              children: [
                _ShimmerBox(width: 60, height: 20, radius: 10),
                const SizedBox(width: 8),
                _ShimmerBox(width: 80, height: 20, radius: 10),
                const SizedBox(width: 8),
                _ShimmerBox(width: 50, height: 20, radius: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
