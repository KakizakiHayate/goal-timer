import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/text_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/animation_consts.dart';

/// 改善されたモーダルボトムシート
/// 目標作成・編集用
class ModalBottomSheet extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool isScrollable;
  final double? height;

  const ModalBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.isScrollable = true,
    this.height,
  });

  @override
  State<ModalBottomSheet> createState() => _ModalBottomSheetState();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    bool isScrollable = true,
    double? height,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalBottomSheet(
        title: title,
        actions: actions,
        isScrollable: isScrollable,
        height: height,
        child: child,
      ),
    );
  }
}

class _ModalBottomSheetState extends State<ModalBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AnimationConsts.smoothCurve,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.9;
    final minHeight = mediaQuery.size.height * 0.5;
    
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * mediaQuery.size.height * 0.1),
          child: Container(
            height: widget.height ?? maxHeight,
            decoration: const BoxDecoration(
              color: ColorConsts.cardBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // ハンドル
                _buildHandle(),
                
                // ヘッダー
                _buildHeader(),
                
                // コンテンツ
                Expanded(
                  child: widget.isScrollable
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingConsts.l,
                          ),
                          child: widget.child,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingConsts.l,
                          ),
                          child: widget.child,
                        ),
                ),
                
                // アクション
                if (widget.actions != null) _buildActions(),
                
                // Safe Area padding
                SizedBox(height: mediaQuery.padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(
        top: SpacingConsts.m,
        bottom: SpacingConsts.s,
      ),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: ColorConsts.textTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConsts.l,
        vertical: SpacingConsts.m,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ColorConsts.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: TextConsts.h3.copyWith(
                color: ColorConsts.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorConsts.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: ColorConsts.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.l),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: ColorConsts.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < widget.actions!.length; i++) ...[
            if (i > 0) const SizedBox(width: SpacingConsts.m),
            Expanded(child: widget.actions![i]),
          ],
        ],
      ),
    );
  }
}