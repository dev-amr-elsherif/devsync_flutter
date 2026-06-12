import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'auth_controller.dart';

class OnboardingView extends GetView<AuthController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AnimatedBackground(),
          SafeArea(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    Text(
                      'Choose Your Path',
                      style: AppTheme.headlineMedium.copyWith(color: Colors.white, fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _RoleCard(
                      title: 'Developer',
                      description: 'Analyze your GitHub, sync your skills, and get matched with top projects.',
                      icon: Icons.code_rounded,
                      color: AppTheme.primary,
                      buttonText: 'Continue with GitHub',
                      onTap: controller.loginAsDeveloper,
                    ),
                    const SizedBox(height: 20),
                    _RoleCard(
                      title: 'Project Manager',
                      description: 'Create projects, browse AI-verified portfolios, and hire the best talent.',
                      icon: Icons.business_center_rounded,
                      color: AppTheme.secondary,
                      buttonText: 'Continue with Google',
                      onTap: controller.loginAsOwner,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.hub_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text('DevSync', style: AppTheme.displayLarge.copyWith(fontSize: 36, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text(
          'The AI-Powered Freelance Network',
          style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String buttonText;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Text(title, style: AppTheme.headlineMedium.copyWith(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          Text(description, style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.2),
                foregroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: CustomPaint(
            painter: _OrbPainter(_controller.value),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  _OrbPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final x1 = size.width * 0.2 + math.sin(progress * 2 * math.pi) * size.width * 0.15;
    final y1 = size.height * 0.2 + math.cos(progress * 2 * math.pi) * size.height * 0.1;
    paint.shader = RadialGradient(
      colors: [AppTheme.primary.withValues(alpha: 0.25), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(x1, y1), radius: size.width * 0.5));
    canvas.drawCircle(Offset(x1, y1), size.width * 0.5, paint);

    final x2 = size.width * 0.8 + math.cos(progress * 2 * math.pi + math.pi) * size.width * 0.15;
    final y2 = size.height * 0.8 + math.sin(progress * 2 * math.pi + math.pi) * size.height * 0.1;
    paint.shader = RadialGradient(
      colors: [AppTheme.secondary.withValues(alpha: 0.2), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(x2, y2), radius: size.width * 0.45));
    canvas.drawCircle(Offset(x2, y2), size.width * 0.45, paint);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.progress != progress;
}
