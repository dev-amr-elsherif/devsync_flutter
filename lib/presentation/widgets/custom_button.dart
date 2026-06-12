import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DevSyncButton extends StatefulWidget {
  final String id;
  final VoidCallback? onPressed;
  final Widget child;
  final LinearGradient? gradient;
  final Color? borderColor;
  final bool isLoading;
  final double height;
  final double borderRadius;

  const DevSyncButton({
    super.key,
    required this.id,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.borderColor,
    this.isLoading = false,
    this.height = 54,
    this.borderRadius = 16,
  });

  @override
  State<DevSyncButton> createState() => _DevSyncButtonState();
}

class _DevSyncButtonState extends State<DevSyncButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed != null) _controller.reverse();
  }

  void _onTapUp(_) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        key: ValueKey(widget.id),
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.onPressed != null
                ? (widget.gradient ?? AppTheme.primaryGradient)
                : null,
            color: widget.onPressed == null ? AppTheme.surfaceLight : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 1)
                : null,
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: (widget.gradient?.colors.first ?? AppTheme.primary)
                          .withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : widget.child,
          ),
        ),
      ),
    );
  }
}
