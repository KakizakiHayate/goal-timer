import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/text_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/animation_consts.dart';

/// 改善されたカスタムテキストフィールド
/// 目標作成・編集フォーム用
class CustomTextField extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final String? initialValue;
  final Function(String) onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.initialValue,
    required this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;

  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    _animationController = AnimationController(
      duration: AnimationConsts.fast,
      vsync: this,
    );

    _focusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AnimationConsts.defaultCurve,
      ),
    );

    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
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

  void _handleTextChange() {
    final text = _controller.text;
    widget.onChanged(text);

    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(text);
      });
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
    final hasError = _errorText != null && _errorText!.isNotEmpty;

    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ラベル
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingConsts.s),
              child: Text(
                widget.labelText,
                style: TextConsts.body.copyWith(
                  color:
                      hasError
                          ? ColorConsts.error
                          : (_isFocused
                              ? ColorConsts.primary
                              : ColorConsts.textSecondary),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // テキストフィールド
            AnimatedContainer(
              duration: AnimationConsts.fast,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (_isFocused && !hasError)
                    BoxShadow(
                      color: ColorConsts.primary.withValues(
                        alpha: 0.15 * _focusAnimation.value,
                      ),
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
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                textInputAction: widget.textInputAction,
                onFieldSubmitted: widget.onSubmitted,
                style: TextConsts.body.copyWith(
                  color:
                      widget.enabled
                          ? ColorConsts.textPrimary
                          : ColorConsts.disabledText,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextConsts.body.copyWith(
                    color: ColorConsts.textTertiary,
                  ),
                  filled: true,
                  fillColor:
                      widget.enabled
                          ? (_isFocused
                              ? ColorConsts.primaryExtraLight
                              : ColorConsts.backgroundSecondary)
                          : ColorConsts.disabled,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SpacingConsts.l,
                    vertical:
                        widget.maxLines > 1
                            ? SpacingConsts.l
                            : SpacingConsts.m + 2,
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
                      color: ColorConsts.border.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  prefixIcon:
                      widget.prefixIcon != null
                          ? Icon(
                            widget.prefixIcon,
                            color:
                                _isFocused
                                    ? ColorConsts.primary
                                    : ColorConsts.textSecondary,
                            size: 22,
                          )
                          : null,
                  suffixIcon: widget.suffixIcon,
                  counterText: '', // 文字数カウンターを非表示
                ),
              ),
            ),

            // エラーメッセージ
            if (hasError) ...[
              const SizedBox(height: SpacingConsts.s),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingConsts.l,
                ),
                child: Text(
                  _errorText!,
                  style: TextConsts.caption.copyWith(
                    color: ColorConsts.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            // 文字数制限表示
            if (widget.maxLength != null && _isFocused) ...[
              const SizedBox(height: SpacingConsts.s),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingConsts.l,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_controller.text.length}/${widget.maxLength}',
                    style: TextConsts.caption.copyWith(
                      color:
                          _controller.text.length > (widget.maxLength! * 0.9)
                              ? ColorConsts.warning
                              : ColorConsts.textTertiary,
                    ),
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
