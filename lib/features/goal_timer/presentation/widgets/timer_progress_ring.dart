import 'dart:math';
import 'package:flutter/material.dart';

class TimerProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? color;
  final Widget? child;

  const TimerProgressRing({
    Key? key,
    required this.progress,
    this.size = 280,
    this.strokeWidth = 12,
    this.backgroundColor = Colors.black12,
    this.foregroundColor = Colors.white,
    this.color,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? foregroundColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景の円
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
          // 進捗の円弧
          CustomPaint(
            size: Size(size, size),
            painter: TimerProgressPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor.withOpacity(0.2),
              foregroundColor: effectiveColor.withOpacity(0.9),
            ),
          ),
          // 中央のコンテンツ
          if (child != null) child!,
        ],
      ),
    );
  }
}

class TimerProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  TimerProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth / 2;

    // 背景の円
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 進捗の円弧
    final foregroundPaint =
        Paint()
          ..color = foregroundColor
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    // 円弧の描画（-π/2から開始、時計回りに進む）
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // 上から開始
      2 * pi * progress, // 進捗に合わせた角度
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
