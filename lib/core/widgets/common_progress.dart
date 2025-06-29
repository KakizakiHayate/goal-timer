import 'package:flutter/material.dart';
import '../utils/color_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/text_consts.dart';

enum ProgressVariant {
  linear,
  circular,
  ring,
}

class CommonProgress extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final ProgressVariant variant;
  final double? size;
  final double? strokeWidth;
  final bool showPercentage;
  final Color? progressColor;
  final Color? backgroundColor;
  final String? centerText;
  final Widget? centerWidget;
  
  const CommonProgress({
    super.key,
    required this.progress,
    this.variant = ProgressVariant.linear,
    this.size,
    this.strokeWidth,
    this.showPercentage = false,
    this.progressColor,
    this.backgroundColor,
    this.centerText,
    this.centerWidget,
  });

  @override
  State<CommonProgress> createState() => _CommonProgressState();
}

class _CommonProgressState extends State<CommonProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CommonProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _progressColor => widget.progressColor ?? ColorConsts.primary;
  Color get _backgroundColor => widget.backgroundColor ?? ColorConsts.backgroundSecondary;

  Widget _buildLinearProgress() {
    return Container(
      height: widget.size ?? 8,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(SpacingConsts.radiusRound),
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _progressColor,
                    _progressColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(SpacingConsts.radiusRound),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircularProgress() {
    final size = widget.size ?? 60.0;
    final strokeWidth = widget.strokeWidth ?? 6.0;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _backgroundColor,
            ),
          ),
          // Progress circle
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                ),
              );
            },
          ),
          // Center content
          if (widget.centerWidget != null)
            widget.centerWidget!
          else if (widget.centerText != null)
            Text(
              widget.centerText!,
              style: TextConsts.labelMedium,
              textAlign: TextAlign.center,
            )
          else if (widget.showPercentage)
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Text(
                  '${(_progressAnimation.value * 100).round()}%',
                  style: TextConsts.labelMedium.copyWith(
                    color: ColorConsts.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRingProgress() {
    final size = widget.size ?? 120.0;
    final strokeWidth = widget.strokeWidth ?? 12.0;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: _backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(_backgroundColor),
            ),
          ),
          // Progress ring
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                  strokeCap: StrokeCap.round,
                ),
              );
            },
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.centerWidget != null)
                widget.centerWidget!
              else if (widget.centerText != null)
                Text(
                  widget.centerText!,
                  style: TextConsts.h4,
                  textAlign: TextAlign.center,
                )
              else if (widget.showPercentage)
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Text(
                      '${(_progressAnimation.value * 100).round()}%',
                      style: TextConsts.number,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case ProgressVariant.linear:
        return _buildLinearProgress();
      case ProgressVariant.circular:
        return _buildCircularProgress();
      case ProgressVariant.ring:
        return _buildRingProgress();
    }
  }
}