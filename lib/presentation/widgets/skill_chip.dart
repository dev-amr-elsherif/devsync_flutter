import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SkillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SkillChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: onDelete != null ? 2 : 10,
        top: 2,
        bottom: 2,
      ),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.primary.withValues(alpha: 0.2)
            : AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppTheme.primary.withValues(alpha: 0.4)
              : AppTheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.primaryLight,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
