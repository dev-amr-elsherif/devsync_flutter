import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdvancedNetworkingAnimation extends StatelessWidget {
  final Widget child;
  const AdvancedNetworkingAnimation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// A glowing orb animation used for background elements in the networking screens
class NetworkingOrb extends StatelessWidget {
  const NetworkingOrb({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.2 + (0.1 * value)),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}
