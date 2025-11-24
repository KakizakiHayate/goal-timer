import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import '../utils/color_consts.dart';
import '../utils/animation_consts.dart';

/// 改善されたサーキュラープログレスインジケーター
/// 達成感を演出するデザインに強化
class CustomCircularProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? centerWidget;
  final bool showAnimation;

  const CustomCircularProgressIndicator({
    super.key,
    required this.progress,
    this.size = 120.0,
    this.strokeWidth = 8.0,
    this.progressColor,
    this.backgroundColor,
    this.centerWidget,
    this.showAnimation = true,
  });

  @override
  State<CustomCircularProgressIndicator> createState() =>
      _CustomCircularProgressIndicatorState();
}

class _CustomCircularProgressIndicatorState extends State<CustomCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.showAnimation ? AnimationConsts.slow : Duration.zero,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AnimationConsts.smoothCurve,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(CustomCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: AnimationConsts.smoothCurve,
        ),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final progressValue = _progressAnimation.value;
        final progressColor =
            widget.progressColor ?? _getProgressColor(progressValue);

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              if (progressValue > 0.8) // 高達成時にグロー効果
                BoxShadow(
                  color: progressColor.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 背景サークル
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: material.CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: widget.strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.backgroundColor ?? ColorConsts.backgroundSecondary,
                  ),
                ),
              ),
              // プログレスサークル
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: material.CircularProgressIndicator(
                  value: progressValue,
                  strokeWidth: widget.strokeWidth,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              // 中央コンテンツ
              if (widget.centerWidget != null)
                widget.centerWidget!
              else
                _buildDefaultCenterWidget(progressValue),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultCenterWidget(double progress) {
    final percentage = (progress * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: widget.size * 0.2,
            fontWeight: FontWeight.bold,
            color: ColorConsts.textPrimary,
          ),
        ),
        if (percentage >= 100)
          Icon(
            Icons.check_circle,
            color: ColorConsts.success,
            size: widget.size * 0.15,
          ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return ColorConsts.success;
    } else if (progress >= 0.8) {
      return const Color(0xFF10B981); // 緑系
    } else if (progress >= 0.5) {
      return ColorConsts.primary;
    } else if (progress >= 0.3) {
      return ColorConsts.warning;
    } else {
      return ColorConsts.textTertiary;
    }
  }
}
