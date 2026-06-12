import 'dart:math' as math;
import 'package:flutter/material.dart';

class MatchScoreBadge extends StatelessWidget {
  final double score; // 0.0 - 1.0
  final double size;

  const MatchScoreBadge({
    super.key,
    required this.score,
    this.size = 60,
  });

  Color get _badgeColor {
    final s = score * 100;
    if (s >= 90) return Colors.greenAccent; // 🔥 Perfect Match
    if (s >= 70) return Colors.blueAccent;  // 👍 Strong Match
    if (s >= 50) return Colors.orangeAccent; // ⚠️ Medium
    return Colors.redAccent;                 // ❌ Weak
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: score,
              color: _badgeColor,
              strokeWidth: 3.5,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(score * 100).round()}',
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w800,
                  color: _badgeColor,
                  height: 1,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.w500,
                  color: _badgeColor.withValues(alpha: 0.8),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.color != color;
}
