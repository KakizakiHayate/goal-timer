import 'package:flutter/material.dart';

import '../utils/animation_consts.dart';
import '../utils/color_consts.dart';

/// タップ可能なカードウィジェット
/// マイクロインタラクションとフィードバックを提供
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;
  final bool enabled;
  final double elevation;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.enabled = true,
    this.elevation = 1.0,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.buttonTap,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AnimationConsts.scalePressed,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AnimationConsts.sharpCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.enabled ? widget.onTap : null,
            child: Container(
              margin: widget.margin,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? ColorConsts.cardBackground,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  if (widget.elevation > 0)
                    BoxShadow(
                      color:
                          _isPressed
                              ? Colors.transparent
                              : ColorConsts.shadowLight,
                      offset: const Offset(0, 2),
                      blurRadius: widget.elevation * 4,
                      spreadRadius: 0,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color:
                        _isPressed
                            ? ColorConsts.pressedOverlay
                            : Colors.transparent,
                  ),
                  child: AnimatedOpacity(
                    duration: AnimationConsts.fast,
                    opacity:
                        widget.enabled ? 1.0 : AnimationConsts.opacityDisabled,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
