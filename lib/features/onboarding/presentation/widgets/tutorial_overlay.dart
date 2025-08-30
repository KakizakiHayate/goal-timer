import 'package:flutter/material.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/cutout_overlay.dart';

/// 真のshowcaseview実装：実際のUI要素を切り抜いてハイライト表示
/// targetButtonKeyで指定した要素のみを切り抜き、他をオーバーレイで覆う
class TutorialOverlay extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final bool showSkip;
  final bool showPulseEffect;
  final GlobalKey targetButtonKey; // ハイライトする実際のUI要素のKey（必須）
  final ScrollController? scrollController; // スクロール連動用

  const TutorialOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.targetButtonKey, // 必須パラメータに変更
    this.onNext,
    this.onSkip,
    this.showSkip = true,
    this.showPulseEffect = true,
    this.scrollController,
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

    // スクロールイベントリスナーを追加
    widget.scrollController?.addListener(_onScrollChanged);
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
    if (widget.targetButtonKey.currentContext == null) {
      print('⚠️ [TutorialOverlay] TargetButtonKey context is null, retrying...');
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _getButtonPosition();
        }
      });
      return;
    }

    try {
      final context = widget.targetButtonKey.currentContext!;
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      
      if (renderBox == null || !renderBox.hasSize) {
        print('⚠️ [TutorialOverlay] RenderBox not ready, retrying...');
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _getButtonPosition();
          }
        });
        return;
      }

      // グローバル座標を取得
      final globalPosition = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      
      // MediaQueryのコンテキストを使用してスクリーン座標を正確に計算
      final mediaQuery = MediaQuery.of(context);
      final screenSize = mediaQuery.size;
      final padding = mediaQuery.padding;
      
      // 実際の表示可能領域を考慮した位置調整
      final adjustedPosition = Offset(
        globalPosition.dx.clamp(0.0, screenSize.width - size.width),
        globalPosition.dy.clamp(padding.top, screenSize.height - padding.bottom - size.height),
      );
      
      print('✅ [TutorialOverlay] Button position found: global=$globalPosition, adjusted=$adjustedPosition, size=$size');
      print('✅ [TutorialOverlay] Screen size: $screenSize, padding: $padding');
      
      if (mounted) {
        setState(() {
          _buttonRect = Rect.fromLTWH(
            adjustedPosition.dx, 
            adjustedPosition.dy, 
            size.width, 
            size.height
          );
        });
      }
    } catch (e, stackTrace) {
      print('❌ [TutorialOverlay] Error getting button position: $e');
      print('❌ [TutorialOverlay] Stack trace: $stackTrace');
      
      // エラーが発生した場合も少し待ってから再試行
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _getButtonPosition();
        }
      });
    }
  }

  void _onScrollChanged() {
    // スクロールイベント発生時にボタンの位置を再計算
    if (mounted) {
      _getButtonPosition();
    }
  }

  bool _isTargetVisible() {
    if (_buttonRect == null) return false;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenPadding = MediaQuery.of(context).padding;
    
    // 表示可能領域内にあるかチェック
    return _buttonRect!.top >= screenPadding.top && 
           _buttonRect!.bottom <= screenHeight - screenPadding.bottom;
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScrollChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 真のshowcaseview：実際のUI要素を切り抜いて表示
    print('🎯 TutorialOverlay build called');
    print('- targetButtonKey: ${widget.targetButtonKey}');
    print('- buttonRect: $_buttonRect');
    
    if (_buttonRect != null) {
      print('✅ TutorialOverlay: Showing showcase view');
      return _buildShowcaseView();
    }
    
    // ボタン位置が取得できていない場合はローディング表示
    print('⏳ TutorialOverlay: Button position not ready, showing loading...');
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildShowcaseView() {
    return CutoutOverlay(
      targetRect: _buttonRect!,
      onTargetTap: () {
        // ターゲット領域がタップされた場合は次のステップへ
        widget.onNext?.call();
      },
      onOutsideTap: () {
        // 外側がタップされた場合はスキップ
        widget.onSkip?.call();
      },
      borderColor: ColorConsts.primary,
      showPulseAnimation: widget.showPulseEffect,
      child: Stack(
        children: [
          // 背景は透明（実際のUIが見える）
          Container(),
          
          // 矢印指示（ターゲットに向けて）
          _buildArrowPointer(),
          
          // 説明ツールチップを画面下部に配置
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

          // スクロール指示（ターゲットが見えない場合）
          if (!_isTargetVisible()) ...[ 
            const SizedBox(height: SpacingConsts.sm),
            Container(
              padding: const EdgeInsets.all(SpacingConsts.sm),
              decoration: BoxDecoration(
                color: ColorConsts.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorConsts.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swipe_vertical_rounded, 
                    color: ColorConsts.warning, 
                    size: 16,
                  ),
                  const SizedBox(width: SpacingConsts.xs),
                  Expanded(
                    child: Text(
                      '目標カードが見えない場合は、画面をスクロールしてください',
                      style: TextConsts.caption.copyWith(
                        color: ColorConsts.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

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

  Widget _buildArrowPointer() {
    if (_buttonRect == null) return const SizedBox.shrink();

    // ターゲット矩形の中心を計算
    final targetCenter = _buttonRect!.center;
    
    // 矢印の位置を計算（ターゲットの上に表示）
    final arrowTop = _buttonRect!.top - 60;
    final arrowLeft = targetCenter.dx - 15; // 矢印の幅の半分

    return Positioned(
      left: arrowLeft,
      top: arrowTop,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.showPulseEffect ? _pulseAnimation.value : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "ここをタップ" テキスト
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingConsts.sm,
                      vertical: SpacingConsts.xs,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConsts.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'ここをタップ',
                      style: TextConsts.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: SpacingConsts.xs),
                  
                  // 矢印
                  Container(
                    width: 0,
                    height: 0,
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(width: 15, color: Colors.transparent),
                        right: BorderSide(width: 15, color: Colors.transparent),
                        top: BorderSide(width: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// NOTE: TutorialManagerは古いAPIを使用しているため、
// 真のshowcaseview実装では実際のGlobalKeyが必要。
// 必要に応じて後で再設計する。
/*
/// チュートリアルステップの情報を保持するモデル
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final GlobalKey targetKey; // 実際のUI要素のKey
  final VoidCallback? onComplete;

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    required this.targetKey,
    this.onComplete,
  });
}

/// 複数ステップのチュートリアルを管理するウィジェット（再設計予定）
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
      targetButtonKey: currentStep.targetKey,
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
*/