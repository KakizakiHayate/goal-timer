import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/text_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/animation_consts.dart';
import 'pressable_card.dart';

/// 改善された目標カードウィジェット
/// カード型レイアウトで視覚的階層を強化
class GoalCard extends StatelessWidget {
  final String title;
  final String? description;
  final double progress; // 0.0 - 1.0
  final int streakDays;
  final String? avoidMessage;
  final VoidCallback? onTap;
  final VoidCallback? onTimerTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final bool isActive;
  final GlobalKey? tutorialKey; // チュートリアル用のKey
  final GlobalKey? timerButtonKey; // タイマーボタン用のKey

  const GoalCard({
    super.key,
    required this.title,
    this.description,
    required this.progress,
    required this.streakDays,
    this.avoidMessage,
    this.onTap,
    this.onTimerTap,
    this.onEditTap,
    this.onDeleteTap,
    this.isActive = true,
    this.tutorialKey,
    this.timerButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      key: tutorialKey, // チュートリアル用のKeyを追加
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingConsts.l,
        vertical: SpacingConsts.s,
      ),
      padding: const EdgeInsets.all(SpacingConsts.l),
      elevation: 2.0,
      borderRadius: 20.0,
      backgroundColor: ColorConsts.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー行
          _buildHeader(),

          const SizedBox(height: SpacingConsts.m),

          // プログレス表示
          _buildProgress(),

          if (avoidMessage != null) ...[
            const SizedBox(height: SpacingConsts.m),
            _buildAvoidanceMessage(),
          ],

          const SizedBox(height: SpacingConsts.m),

          // アクションボタン
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextConsts.h3.copyWith(
                  color: ColorConsts.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (description != null) ...[
                const SizedBox(height: SpacingConsts.xs),
                Text(
                  description!,
                  style: TextConsts.body.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: SpacingConsts.m),
        // 簡易的な継続日数表示
        if (streakDays > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingConsts.s,
              vertical: SpacingConsts.xs,
            ),
            decoration: BoxDecoration(
              color: ColorConsts.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department,
                    color: ColorConsts.success, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$streakDays',
                  style: TextConsts.caption.copyWith(
                    color: ColorConsts.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProgress() {
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '進捗',
              style: TextConsts.caption.copyWith(
                color: ColorConsts.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$percentage%',
              style: TextConsts.h4.copyWith(
                color: _getProgressColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingConsts.xs),
        AnimatedContainer(
          duration: AnimationConsts.medium,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: ColorConsts.backgroundSecondary,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvoidanceMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingConsts.m),
      decoration: BoxDecoration(
        color: ColorConsts.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConsts.error.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: ColorConsts.error, size: 18),
          const SizedBox(width: SpacingConsts.s),
          Expanded(
            child: Text(
              avoidMessage!,
              style: TextConsts.caption.copyWith(
                color: ColorConsts.error,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _ActionButton(
            key: timerButtonKey, // タイマーボタン用のKeyを設定
            icon: Icons.timer_outlined,
            label: 'タイマー開始',
            backgroundColor: ColorConsts.primary,
            textColor: Colors.white,
            onTap: onTimerTap,
          ),
        ),
        const SizedBox(width: SpacingConsts.s),
        _ActionButton(
          icon: Icons.edit_outlined,
          label: '編集',
          backgroundColor: ColorConsts.backgroundSecondary,
          textColor: ColorConsts.textSecondary,
          onTap: onEditTap,
        ),
        const SizedBox(width: SpacingConsts.s),
        _IconButton(
          icon: Icons.delete_outline,
          backgroundColor: ColorConsts.error.withOpacity(0.1),
          iconColor: ColorConsts.error,
          onTap: onDeleteTap,
        ),
      ],
    );
  }

  Color _getProgressColor() {
    if (progress >= 1.0) {
      return ColorConsts.success;
    } else if (progress >= 0.8) {
      return ColorConsts.success;
    } else if (progress >= 0.5) {
      return ColorConsts.primary;
    } else if (progress >= 0.3) {
      return ColorConsts.warning;
    } else {
      return ColorConsts.textTertiary;
    }
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingConsts.m,
                vertical: SpacingConsts.s,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow:
                    widget.backgroundColor == ColorConsts.primary
                        ? [
                          BoxShadow(
                            color: ColorConsts.primary.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ]
                        : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: widget.textColor, size: 18),
                  const SizedBox(width: SpacingConsts.xs),
                  Text(
                    widget.label,
                    style: TextConsts.caption.copyWith(
                      color: widget.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// アイコンのみのボタン（削除ボタン用）
class _IconButton extends StatefulWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _IconButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(SpacingConsts.s),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 18),
            ),
          ),
        );
      },
    );
  }
}
