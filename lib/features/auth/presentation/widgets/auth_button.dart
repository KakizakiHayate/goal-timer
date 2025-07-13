import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/utils/shadow_consts.dart';

/// 認証ボタンの種類
enum AuthButtonType { email, google, apple }

/// 認証ボタンウィジェット
/// タップフィードバックと視覚的階層を強化
class AuthButton extends StatefulWidget {
  const AuthButton({
    super.key,
    required this.type,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final AuthButtonType type;
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// AppleログインボタンがiOSでのみ表示されるかチェック
  static bool shouldShowAppleLogin() {
    return Platform.isIOS;
  }

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton>
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
    if (widget.isLoading || widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isLoading || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (widget.isLoading || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: isEnabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: AnimationConsts.fast,
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                border: _getBorder(),
                boxShadow: _getBoxShadow(),
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getLoadingColor(),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.type != AuthButtonType.email) ...[
                            _getIcon(),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            widget.text,
                            style: _getTextStyle().copyWith(
                              color: isEnabled
                                  ? _getTextColor()
                                  : ColorConsts.disabledText,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor() {
    if (!widget.isLoading && widget.onPressed == null) {
      return ColorConsts.disabled;
    }

    switch (widget.type) {
      case AuthButtonType.email:
        return _isPressed ? ColorConsts.primaryDark : ColorConsts.primary;
      case AuthButtonType.google:
        return _isPressed ? ColorConsts.backgroundSecondary : Colors.white;
      case AuthButtonType.apple:
        return _isPressed ? Colors.grey[900]! : Colors.black;
    }
  }

  Border? _getBorder() {
    if (widget.type == AuthButtonType.google) {
      return Border.all(
        color: _isPressed ? ColorConsts.border : ColorConsts.borderLight,
        width: 1.5,
      );
    }
    return null;
  }

  List<BoxShadow> _getBoxShadow() {
    if (_isPressed || (!widget.isLoading && widget.onPressed == null)) {
      return [];
    }

    if (widget.type == AuthButtonType.email) {
      return [
        BoxShadow(
          color: ColorConsts.primary.withOpacity(0.3),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];
    }
    return ShadowConsts.cardShadow;
  }

  Color _getTextColor() {
    switch (widget.type) {
      case AuthButtonType.email:
      case AuthButtonType.apple:
        return Colors.white;
      case AuthButtonType.google:
        return ColorConsts.textPrimary;
    }
  }

  Color _getLoadingColor() {
    switch (widget.type) {
      case AuthButtonType.email:
      case AuthButtonType.apple:
        return Colors.white;
      case AuthButtonType.google:
        return ColorConsts.textPrimary;
    }
  }

  Widget _getIcon() {
    switch (widget.type) {
      case AuthButtonType.google:
        // TODO: Google公式アイコンに置き換え
        return Icon(
          Icons.g_mobiledata,
          size: 24,
          color: ColorConsts.textPrimary,
        );
      case AuthButtonType.apple:
        return const Icon(
          Icons.apple,
          size: 24,
          color: Colors.white,
        );
      case AuthButtonType.email:
        return const SizedBox.shrink();
    }
  }

  TextStyle _getTextStyle() {
    return const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    );
  }
}