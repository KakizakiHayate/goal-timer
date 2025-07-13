import 'package:flutter/material.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/utils/v2_constants_adapter.dart';

/// 認証フォーム用テキストフィールド
/// フォーカス状態の視覚的フィードバックを強化
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.labelText,
    required this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.initialValue,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String labelText;
  final Function(String) onChanged;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final String? initialValue;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  
  bool _isObscured = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _isObscured = widget.obscureText;
    
    _animationController = AnimationController(
      duration: AnimationConsts.fast,
      vsync: this,
    );
    
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AnimationConsts.defaultCurve,
      ),
    );
    
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AnimationConsts.fast,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (_isFocused && !hasError)
                    BoxShadow(
                      color: ColorConsts.primary.withOpacity(0.15 * _focusAnimation.value),
                      offset: const Offset(0, 4),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                ],
              ),
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                obscureText: widget.obscureText && _isObscured,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onSubmitted,
                style: TextStyle(
                  fontSize: 17,
                  color: widget.enabled ? ColorConsts.textPrimary : ColorConsts.disabledText,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  labelStyle: TextStyle(
                    fontSize: 16,
                    color: hasError 
                        ? ColorConsts.error
                        : (_isFocused ? ColorConsts.primary : ColorConsts.textSecondary),
                    fontWeight: _isFocused ? FontWeight.w500 : FontWeight.normal,
                  ),
                  filled: true,
                  fillColor: widget.enabled 
                      ? (_isFocused ? ColorConsts.primaryExtraLight : ColorConsts.backgroundSecondary)
                      : ColorConsts.disabled,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: hasError ? ColorConsts.error : ColorConsts.border,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: hasError ? ColorConsts.error : ColorConsts.primary,
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: ColorConsts.error,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: ColorConsts.error,
                      width: 2.0,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: ColorConsts.border.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  suffixIcon: widget.obscureText
                      ? IconButton(
                          icon: AnimatedSwitcher(
                            duration: AnimationConsts.fast,
                            child: Icon(
                              _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              key: ValueKey(_isObscured),
                              color: _isFocused ? ColorConsts.primary : ColorConsts.textSecondary,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscured = !_isObscured;
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ColorConsts.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}