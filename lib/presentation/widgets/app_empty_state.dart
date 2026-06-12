import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppTheme.textMuted),
            ).animate().scale(delay: 100.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            if (action != null) ...[
              const SizedBox(height: 32),
              action!.animate().fadeIn(delay: 700.ms).scale(),
            ],
          ],
        ),
      ),
    );
  }
}
