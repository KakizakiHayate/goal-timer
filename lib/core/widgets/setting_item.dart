import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/text_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/animation_consts.dart';
import 'pressable_card.dart';

/// 改善された設定項目ウィジェット
class SettingItem extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const SettingItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<SettingItem> createState() => _SettingItemState();
}

class _SettingItemState extends State<SettingItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.fast,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: PressableCard(
        onTap: widget.enabled ? widget.onTap : null,
        margin: const EdgeInsets.only(bottom: SpacingConsts.s),
        padding: const EdgeInsets.all(SpacingConsts.l),
        backgroundColor: ColorConsts.cardBackground,
        borderRadius: 16.0,
        elevation: 1.0,
        enabled: widget.enabled,
        child: Row(
          children: [
            // アイコン
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (widget.iconColor ?? ColorConsts.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: widget.enabled 
                    ? (widget.iconColor ?? ColorConsts.primary)
                    : ColorConsts.disabledText,
                size: 22,
              ),
            ),
            
            const SizedBox(width: SpacingConsts.m),
            
            // タイトルとサブタイトル
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextConsts.body.copyWith(
                      color: widget.enabled 
                          ? ColorConsts.textPrimary
                          : ColorConsts.disabledText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: SpacingConsts.xs),
                    Text(
                      widget.subtitle!,
                      style: TextConsts.caption.copyWith(
                        color: widget.enabled 
                            ? ColorConsts.textSecondary
                            : ColorConsts.disabledText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // トレーリング
            if (widget.trailing != null) ...[
              const SizedBox(width: SpacingConsts.m),
              widget.trailing!,
            ] else if (widget.onTap != null) ...[
              const SizedBox(width: SpacingConsts.m),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: widget.enabled 
                    ? ColorConsts.textTertiary
                    : ColorConsts.disabledText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}