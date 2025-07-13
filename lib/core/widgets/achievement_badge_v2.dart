import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/text_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/animation_consts.dart';
import '../utils/v2_constants_adapter.dart';

/// 改善された達成バッジウィジェット
/// 達成感を演出するバッジ表示
class AchievementBadgeV2 extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final VoidCallback? onTap;

  const AchievementBadgeV2({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    this.unlockedAt,
    this.onTap,
  });

  @override
  State<AchievementBadgeV2> createState() => _AchievementBadgeV2State();
}

class _AchievementBadgeV2State extends State<AchievementBadgeV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.slow,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: AnimationConsts.bounceCurve),
      ),
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    
    if (widget.isUnlocked) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AchievementBadgeV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUnlocked && !oldWidget.isUnlocked) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isUnlocked ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(SpacingConstsV2.l),
              decoration: BoxDecoration(
                color: widget.isUnlocked
                    ? ColorConsts.cardBackground
                    : ColorConsts.backgroundSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isUnlocked
                      ? widget.color.withOpacity(0.3)
                      : ColorConsts.border,
                  width: widget.isUnlocked ? 2 : 1,
                ),
                boxShadow: widget.isUnlocked
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.3 * _glowAnimation.value),
                          offset: const Offset(0, 4),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // バッジアイコン
                  _buildBadgeIcon(),
                  
                  const SizedBox(height: SpacingConstsV2.m),
                  
                  // タイトル
                  Text(
                    widget.title,
                    style: TextConstsV2.body.copyWith(
                      color: widget.isUnlocked
                          ? ColorConsts.textPrimary
                          : ColorConsts.textTertiary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: SpacingConstsV2.s),
                  
                  // 説明
                  Text(
                    widget.description,
                    style: TextConsts.caption.copyWith(
                      color: widget.isUnlocked
                          ? ColorConsts.textSecondary
                          : ColorConsts.textTertiary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // 解除日時
                  if (widget.isUnlocked && widget.unlockedAt != null) ...[
                    const SizedBox(height: SpacingConstsV2.s),
                    Text(
                      _formatUnlockedDate(widget.unlockedAt!),
                      style: TextConsts.caption.copyWith(
                        color: widget.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: widget.isUnlocked
            ? widget.color
            : ColorConsts.textTertiary.withOpacity(0.3),
        shape: BoxShape.circle,
        boxShadow: widget.isUnlocked
            ? [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            widget.icon,
            color: widget.isUnlocked ? Colors.white : ColorConsts.textTertiary,
            size: 28,
          ),
          if (!widget.isUnlocked)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: ColorConsts.textTertiary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatUnlockedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '今日解除';
    } else if (difference.inDays == 1) {
      return '昨日解除';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前解除';
    } else {
      return '${date.month}/${date.day}解除';
    }
  }
}