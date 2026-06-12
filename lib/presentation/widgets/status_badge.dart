import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

enum BadgeType { status, count, info }

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final BadgeType type;
  final bool isAnimated;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.type = BadgeType.status,
    this.isAnimated = false,
  });

  factory StatusBadge.projectStatus(String status) {
    late Color color;
    late String label;
    late IconData icon;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppTheme.success;
        label = 'Active';
        icon = Icons.bolt_rounded;
        break;
      case 'paused':
        color = AppTheme.warning;
        label = 'Paused';
        icon = Icons.pause_circle_outline_rounded;
        break;
      case 'completed':
      case 'done':
        color = AppTheme.primaryLight;
        label = 'Done';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'cancelled':
        color = AppTheme.error;
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      default:
        color = AppTheme.textMuted;
        label = status.toUpperCase();
        icon = Icons.info_outline_rounded;
    }
    return StatusBadge(label: label, color: color, icon: icon);
  }

  factory StatusBadge.invitationStatus(String status) {
    late Color color;
    late String label;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = AppTheme.success;
        label = 'Accepted';
        break;
      case 'declined':
        color = AppTheme.error;
        label = 'Declined';
        break;
      case 'pending':
        color = AppTheme.warning;
        label = 'Pending...';
        break;
      case 'join_request':
        color = AppTheme.secondary;
        label = 'Join Request';
        break;
      case 'cancellation_proposed':
        color = Colors.orange;
        label = 'Cancellation';
        break;
      default:
        color = AppTheme.textMuted;
        label = status.toUpperCase();
    }
    return StatusBadge(label: label, color: color);
  }

  factory StatusBadge.newCount(int count) {
    return StatusBadge(
      label: '$count New Requests',
      color: AppTheme.error,
      icon: Icons.notifications_active_rounded,
      isAnimated: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (isAnimated) {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1500.ms, color: color.withValues(alpha: 0.2));
    }

    return badge;
  }
}
