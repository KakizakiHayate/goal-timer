import 'package:flutter/material.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/widgets/common_button.dart';

/// チュートリアル用のオーバーレイウィジェット
/// 特定のUI要素をハイライトし、説明を表示
class TutorialOverlay extends StatefulWidget {
  final Widget targetWidget;
  final String title;
  final String description;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final bool showSkip;
  final EdgeInsets targetPadding;
  final Alignment tooltipAlignment;
  final bool showPulseEffect;
  final bool showArrow;
  final GlobalKey? targetButtonKey; // 特定のボタンをハイライトする場合のKey

  const TutorialOverlay({
    super.key,
    required this.targetWidget,
    required this.title,
    required this.description,
    this.onNext,
    this.onSkip,
    this.showSkip = true,
    this.targetPadding = const EdgeInsets.all(8.0),
    this.tooltipAlignment = Alignment.bottomCenter,
    this.showPulseEffect = true,
    this.showArrow = true,
    this.targetButtonKey,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  Rect? _buttonRect; // ボタンの位置とサイズを保存

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    
    // パルスアニメーションをループ
    _startPulseLoop();

    // ボタンの位置を取得（少し遅らせる）
    _scheduleButtonPositionUpdate();
  }

  @override
  void didUpdateWidget(covariant TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ウィジェットが更新されたときも位置を再取得
    if (widget.targetButtonKey != oldWidget.targetButtonKey) {
      _scheduleButtonPositionUpdate();
    }
  }

  void _scheduleButtonPositionUpdate() {
    if (widget.targetButtonKey != null) {
      // 複数回のコールバックで確実に取得
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getButtonPosition();
      });
      // さらに少し遅らせて再取得
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _getButtonPosition();
        }
      });
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
  }

  void _getButtonPosition() {
    if (widget.targetButtonKey?.currentContext != null) {
      try {
        final RenderBox? renderBox = 
            widget.targetButtonKey!.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          
          // デバッグ用のログ
          print('Button position found: $position, size: $size');
          
          if (mounted) {
            setState(() {
              _buttonRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
            });
          }
        } else {
          print('RenderBox not ready, retrying...');
          // RenderBoxがまだ準備できていない場合は少し待ってから再試行
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              _getButtonPosition();
            }
          });
        }
      } catch (e) {
        print('Error getting button position: $e');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Stack(
        children: [
          // オーバーレイ背景（タップで閉じる）
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onSkip,
              child: Container(color: Colors.transparent),
            ),
          ),

          // ハイライトされたターゲット
          if (widget.targetButtonKey != null && _buttonRect != null)
            // ボタン特化のハイライト
            _buildButtonHighlight()
          else
            // 通常のハイライト
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.showPulseEffect ? _pulseAnimation.value : 1.0,
                      child: Container(
                        padding: widget.targetPadding,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ColorConsts.primary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ColorConsts.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: ColorConsts.primary.withValues(alpha: 0.1),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: widget.targetWidget,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ポインティングアロー（オプション）
          if (widget.showArrow)
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Container(
                    width: 0,
                    height: 0,
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(width: 15, color: Colors.transparent),
                        right: BorderSide(width: 15, color: Colors.transparent),
                        bottom: BorderSide(width: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 説明ツールチップ
          Positioned(
            left: SpacingConsts.md,
            right: SpacingConsts.md,
            bottom: 100,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTooltip(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: ColorConsts.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: ColorConsts.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: SpacingConsts.sm),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingConsts.md),

          // 説明
          Text(
            widget.description,
            style: TextConsts.bodyMedium.copyWith(
              color: ColorConsts.textSecondary,
              height: 1.6,
            ),
          ),

          const SizedBox(height: SpacingConsts.lg),

          // アクションボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.showSkip) ...[
                TextButton(
                  onPressed: widget.onSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingConsts.md,
                      vertical: SpacingConsts.sm,
                    ),
                  ),
                  child: Text(
                    'スキップ',
                    style: TextConsts.labelMedium.copyWith(
                      color: ColorConsts.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: SpacingConsts.sm),
              ],
              
              CommonButton(
                text: widget.onNext != null ? '次へ' : '完了',
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
                onPressed: widget.onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtonHighlight() {
    if (_buttonRect == null) return const SizedBox.shrink();

    // 緑色のハイライト色を定義
    const highlightColor = Color(0xFF10B981); // 緑色

    return Positioned(
      left: _buttonRect!.left - 12,
      top: _buttonRect!.top - 12,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.showPulseEffect ? _pulseAnimation.value : 1.0,
              child: Container(
                width: _buttonRect!.width + 24,
                height: _buttonRect!.height + 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: highlightColor,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: highlightColor.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: highlightColor.withValues(alpha: 0.3),
                      blurRadius: 35,
                      spreadRadius: 8,
                    ),
                    // より強いグロー効果
                    BoxShadow(
                      color: highlightColor.withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// チュートリアルステップの情報を保持するモデル
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final Widget Function() targetWidgetBuilder;
  final VoidCallback? onComplete;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.targetWidgetBuilder,
    this.onComplete,
  });
}

/// 複数ステップのチュートリアルを管理するウィジェット
class TutorialManager extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const TutorialManager({
    super.key,
    required this.steps,
    this.onComplete,
    this.onSkip,
  });

  @override
  State<TutorialManager> createState() => _TutorialManagerState();
}

class _TutorialManagerState extends State<TutorialManager> {
  int _currentStepIndex = 0;

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      // 全ステップ完了
      widget.onComplete?.call();
    }
  }

  void _skipTutorial() {
    widget.onSkip?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStepIndex >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final currentStep = widget.steps[_currentStepIndex];
    
    return TutorialOverlay(
      targetWidget: currentStep.targetWidgetBuilder(),
      title: currentStep.title,
      description: currentStep.description,
      onNext: () {
        currentStep.onComplete?.call();
        _nextStep();
      },
      onSkip: _skipTutorial,
    );
  }
}