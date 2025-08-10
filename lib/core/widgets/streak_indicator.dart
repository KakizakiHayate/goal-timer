import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/text_consts.dart';
import '../utils/animation_consts.dart';

/// 継続日数を表示するインジケーター
/// モチベーション維持のために視覚的に強調
class StreakIndicator extends StatefulWidget {
  final int streakDays;
  final bool showAnimation;
  final double size;

  const StreakIndicator({
    super.key,
    required this.streakDays,
    this.showAnimation = true,
    this.size = 48.0,
  });

  @override
  State<StreakIndicator> createState() => _StreakIndicatorState();
}

class _StreakIndicatorState extends State<StreakIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.showAnimation) {
      _controller = AnimationController(
        duration: AnimationConsts.medium,
        vsync: this,
      );
      _scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: AnimationConsts.bounceCurve,
        ),
      );
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StreakIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakDays != oldWidget.streakDays && widget.showAnimation) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    if (widget.showAnimation) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department,
          color: _getStreakColor(),
          size: widget.size * 0.6,
        ),
        const SizedBox(width: 4),
        Text(
          widget.streakDays.toString(),
          style: TextConsts.h3.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    if (!widget.showAnimation) {
      return content;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: content,
        );
      },
    );
  }

  Color _getStreakColor() {
    if (widget.streakDays >= 30) {
      return const Color(0xFFFFD700); // ゴールド
    } else if (widget.streakDays >= 7) {
      return const Color(0xFFFF6B35); // オレンジ
    } else if (widget.streakDays >= 3) {
      return const Color(0xFFFF9558); // 薄いオレンジ
    } else {
      return ColorConsts.textSecondary;
    }
  }
}