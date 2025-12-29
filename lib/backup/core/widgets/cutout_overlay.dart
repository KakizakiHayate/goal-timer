import 'package:flutter/material.dart';

/// showcaseview風の切り抜きオーバーレイウィジェット
/// 指定された領域のみを透明にして、その他を半透明でオーバーレイする
class CutoutOverlay extends StatefulWidget {
  final Rect? targetRect;
  final Widget child;
  final Color overlayColor;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final bool showPulseAnimation;
  final VoidCallback? onTargetTap;
  final VoidCallback? onOutsideTap;

  const CutoutOverlay({
    super.key,
    required this.targetRect,
    required this.child,
    this.overlayColor = const Color(0xAA000000),
    this.borderRadius = 12.0,
    this.borderWidth = 3.0,
    this.borderColor = Colors.white,
    this.showPulseAnimation = true,
    this.onTargetTap,
    this.onOutsideTap,
  });

  @override
  State<CutoutOverlay> createState() => _CutoutOverlayState();
}

class _CutoutOverlayState extends State<CutoutOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.showPulseAnimation) {
      _startPulseLoop();
    }
  }

  void _startPulseLoop() {
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 子ウィジェット
        widget.child,

        // 切り抜きオーバーレイ
        if (widget.targetRect != null)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                final tapPosition = details.globalPosition;

                // タップした位置がターゲット領域内かチェック
                if (_isInTargetArea(tapPosition)) {
                  widget.onTargetTap?.call();
                } else {
                  widget.onOutsideTap?.call();
                }
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CutoutPainter(
                      targetRect: widget.targetRect!,
                      overlayColor: widget.overlayColor,
                      borderRadius: widget.borderRadius,
                      borderWidth: widget.borderWidth,
                      borderColor: widget.borderColor,
                      pulseScale:
                          widget.showPulseAnimation
                              ? _pulseAnimation.value
                              : 1.0,
                    ),
                    child: Container(),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  bool _isInTargetArea(Offset tapPosition) {
    if (widget.targetRect == null) return false;

    final expandedRect = Rect.fromCenter(
      center: widget.targetRect!.center,
      width: widget.targetRect!.width + (widget.borderWidth * 2),
      height: widget.targetRect!.height + (widget.borderWidth * 2),
    );

    return expandedRect.contains(tapPosition);
  }
}

/// 切り抜きマスクを描画するCustomPainter
class _CutoutPainter extends CustomPainter {
  final Rect targetRect;
  final Color overlayColor;
  final double borderRadius;
  final double borderWidth;
  final Color borderColor;
  final double pulseScale;

  _CutoutPainter({
    required this.targetRect,
    required this.overlayColor,
    required this.borderRadius,
    required this.borderWidth,
    required this.borderColor,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // オーバーレイペイント
    final overlayPaint =
        Paint()
          ..color = overlayColor
          ..style = PaintingStyle.fill;

    // ボーダーペイント
    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    // グローエフェクトペイント
    final glowPaint =
        Paint()
          ..color = borderColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth * 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

    // パルススケールを適用したターゲット矩形
    final scaledTargetRect = Rect.fromCenter(
      center: targetRect.center,
      width: targetRect.width * pulseScale,
      height: targetRect.height * pulseScale,
    );

    // 切り抜きパスを作成
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            scaledTargetRect,
            Radius.circular(borderRadius),
          ),
        );

    // 切り抜き部分を除外（差集合）
    final finalPath = Path.combine(PathOperation.difference, path, cutoutPath);

    // オーバーレイを描画（切り抜き部分以外）
    canvas.drawPath(finalPath, overlayPaint);

    // グローエフェクトを描画
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaledTargetRect, Radius.circular(borderRadius)),
      glowPaint,
    );

    // ボーダーを描画
    canvas.drawRRect(
      RRect.fromRectAndRadius(scaledTargetRect, Radius.circular(borderRadius)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CutoutPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.pulseScale != pulseScale;
  }
}
