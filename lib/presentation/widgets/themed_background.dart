import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Widget بيحط خلفية gradient بتتغير مع الثيم تلقائياً
class ThemedBackground extends StatelessWidget {
  final Widget child;

  const ThemedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          // ✅ بيقرأ الثيم الحالي من context مش static
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradientOf(context),
          ),
        ),
        child,
      ],
    );
  }
}
