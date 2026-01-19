import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/text_consts.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  success,
  warning,
  error,
}

enum ButtonSize { small, medium, large }

class CommonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isExpanded;
  final Widget? icon;
  final IconData? iconData;
  final bool iconRight;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.iconData,
    this.iconRight = false,
  });

  @override
  State<CommonButton> createState() => _CommonButtonState();
}

class _CommonButtonState extends State<CommonButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return SpacingConsts.buttonHeightSm;
      case ButtonSize.medium:
        return SpacingConsts.buttonHeight;
      case ButtonSize.large:
        return SpacingConsts.buttonHeightLg;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case ButtonSize.small:
        return TextConsts.buttonSmall;
      case ButtonSize.medium:
        return TextConsts.buttonMedium;
      case ButtonSize.large:
        return TextConsts.buttonLarge;
    }
  }

  Color _getBackgroundColor() {
    if (widget.onPressed == null) {
      return ColorConsts.textTertiary;
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return ColorConsts.primary;
      case ButtonVariant.secondary:
        return ColorConsts.backgroundSecondary;
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.ghost:
        return Colors.transparent;
      case ButtonVariant.success:
        return ColorConsts.success;
      case ButtonVariant.warning:
        return ColorConsts.warning;
      case ButtonVariant.error:
        return ColorConsts.error;
    }
  }

  Color _getTextColor() {
    if (widget.onPressed == null) {
      return Colors.white;
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
      case ButtonVariant.success:
      case ButtonVariant.warning:
      case ButtonVariant.error:
        return Colors.white;
      case ButtonVariant.secondary:
        return ColorConsts.textPrimary;
      case ButtonVariant.outline:
        return ColorConsts.primary;
      case ButtonVariant.ghost:
        return ColorConsts.primary;
    }
  }

  Color _getBorderColor() {
    switch (widget.variant) {
      case ButtonVariant.outline:
        return widget.onPressed == null
            ? ColorConsts.textTertiary
            : ColorConsts.primary;
      default:
        return Colors.transparent;
    }
  }

  List<BoxShadow>? _getShadow() {
    if (widget.variant == ButtonVariant.ghost ||
        widget.variant == ButtonVariant.outline) {
      return null;
    }

    return _isPressed
        ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ]
        : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ];
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
        ),
      );
    }

    final textWidget = Text(
      widget.text,
      style: _getTextStyle().copyWith(color: _getTextColor()),
    );

    final iconWidget =
        widget.icon ??
        (widget.iconData != null
            ? Icon(
              widget.iconData,
              color: _getTextColor(),
              size: widget.size == ButtonSize.small ? 16 : 20,
            )
            : null);

    if (iconWidget == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          widget.iconRight
              ? [
                textWidget,
                const SizedBox(width: SpacingConsts.sm),
                iconWidget,
              ]
              : [
                iconWidget,
                const SizedBox(width: SpacingConsts.sm),
                textWidget,
              ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap:
                widget.onPressed != null && !widget.isLoading
                    ? widget.onPressed
                    : null,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              height: _getHeight(),
              width: widget.isExpanded ? double.infinity : null,
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(SpacingConsts.radiusMd),
                border: Border.all(
                  color: _getBorderColor(),
                  width: widget.variant == ButtonVariant.outline ? 1.5 : 0,
                ),
                boxShadow: _getShadow(),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        widget.size == ButtonSize.small
                            ? SpacingConsts.md
                            : SpacingConsts.lg,
                  ),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
