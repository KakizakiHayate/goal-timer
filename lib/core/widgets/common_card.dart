import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/shadow_consts.dart';

enum CardVariant { standard, elevated, outlined }

class CommonCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final CardVariant variant;
  final VoidCallback? onTap;
  final bool isInteractive;
  final Color? backgroundColor;
  final double? borderRadius;

  const CommonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.variant = CardVariant.standard,
    this.onTap,
    this.isInteractive = false,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  State<CommonCard> createState() => _CommonCardState();
}

class _CommonCardState extends State<CommonCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isInteractive || widget.onTap != null) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isInteractive || widget.onTap != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.isInteractive || widget.onTap != null) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  BoxDecoration _getDecoration() {
    switch (widget.variant) {
      case CardVariant.standard:
        return BoxDecoration(
          color: widget.backgroundColor ?? ColorConsts.cardBackground,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? SpacingConsts.radiusMd,
          ),
          boxShadow:
              _isPressed ? ShadowConsts.buttonPressed : ShadowConsts.cardShadow,
        );
      case CardVariant.elevated:
        return BoxDecoration(
          color: widget.backgroundColor ?? ColorConsts.cardBackground,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? SpacingConsts.radiusMd,
          ),
          boxShadow:
              _isPressed
                  ? ShadowConsts.elevationSmall
                  : ShadowConsts.elevationMedium,
        );
      case CardVariant.outlined:
        return BoxDecoration(
          color: widget.backgroundColor ?? ColorConsts.cardBackground,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? SpacingConsts.radiusMd,
          ),
          border: Border.all(color: ColorConsts.border, width: 1.0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin,
            decoration: _getDecoration(),
            child: Padding(
              padding:
                  widget.padding ??
                  const EdgeInsets.all(SpacingConsts.cardPadding),
              child: widget.child,
            ),
          ),
        );
      },
    );

    if (widget.onTap != null || widget.isInteractive) {
      return GestureDetector(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: card,
      );
    }

    return card;
  }
}
