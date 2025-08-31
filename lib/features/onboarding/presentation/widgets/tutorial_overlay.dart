import 'package:flutter/material.dart';
import 'dart:math';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/cutout_overlay.dart';

/// 矢印の方向を表すEnum
enum ArrowDirection { up, down, left, right, none }

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
  
  // 矢印の方向を管理
  ArrowDirection _arrowDirection = ArrowDirection.down;

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
      // レイヤー構造を再設計：CutoutOverlayとダイアログを分離
      return Stack(
        children: [
          // レイヤー1: 黒い半透明オーバーレイ（切り抜き付き）
          CutoutOverlay(
            targetRect: _buttonRect!,
            onTargetTap: () {
              widget.onNext?.call();
            },
            onOutsideTap: () {
              widget.onSkip?.call();
            },
            borderColor: ColorConsts.primary,
            showPulseAnimation: widget.showPulseEffect,
            child: Container(), // 空のコンテナ
          ),
          
          // レイヤー2: チュートリアルダイアログ（最上層・独立）
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            top: _calculateDialogPosition(),
            left: SpacingConsts.md,
            right: SpacingConsts.md,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTooltipWithArrow(),
            ),
          ),
          
          // レイヤー3: スマート矢印ポインター（不要なため削除）
          // _buildSmartArrowPointer() は使用しない
        ],
      );
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

  /// ダイアログ位置の動的計算（デバイス対応）
  double _calculateDialogPosition() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeArea = MediaQuery.of(context).padding;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    // ダイアログの動的高さ推定（レスポンシブ対応）
    final dialogHeight = _estimateDialogHeight();
    const arrowHeight = 30.0; // 三角矢印の高さ
    const idealGap = 30.0; // 矢印とボタン間の理想的な距離（重なり防止のため増加）
    
    // ターゲットボタンの位置を基準に計算
    final buttonTop = _buttonRect!.top;
    final buttonBottom = _buttonRect!.bottom;
    
    // デバイス密度を考慮した最小余白
    final minSpacing = _getDeviceAwareSpacing(devicePixelRatio, screenWidth);
    
    // 優先順位で配置位置を決定
    double dialogTop;
    
    // 1. ボタンの上に配置（最優先）
    final spaceAboveButton = buttonTop - safeArea.top;
    final requiredSpaceAbove = dialogHeight + arrowHeight + idealGap + minSpacing;
    
    if (spaceAboveButton >= requiredSpaceAbove) {
      // 動的計算：矢印の先端がボタン上端から idealGap 分離れるように配置
      dialogTop = buttonTop - arrowHeight - idealGap - dialogHeight;
      _arrowDirection = ArrowDirection.down;
      
      // 重なり検証のためのデバッグ出力
      final arrowBottomY = dialogTop + dialogHeight + arrowHeight;
      final gapToButton = buttonTop - arrowBottomY;
      print('✅ [TutorialOverlay] ダイアログをボタン上部に配置');
      print('   dialogTop: $dialogTop, buttonTop: $buttonTop');
      print('   矢印下端: $arrowBottomY, ボタンまでの実際の距離: ${gapToButton.toStringAsFixed(1)}px');
      print('   必要距離: ${idealGap}px, 重なり: ${gapToButton < 0 ? "あり" : "なし"}');
    }
    // 2. ボタンの下に配置
    else {
      final spaceBelowButton = screenHeight - buttonBottom - safeArea.bottom;
      final requiredSpaceBelow = dialogHeight + arrowHeight + idealGap + minSpacing;
      
      if (spaceBelowButton >= requiredSpaceBelow) {
        // 動的計算：矢印の先端がボタン下端から idealGap 分離れるように配置
        dialogTop = buttonBottom + idealGap + arrowHeight;
        _arrowDirection = ArrowDirection.up;
        
        // 重なり検証のためのデバッグ出力
        final arrowTopY = dialogTop - arrowHeight;
        final gapFromButton = arrowTopY - buttonBottom;
        print('✅ [TutorialOverlay] ダイアログをボタン下部に配置');
        print('   dialogTop: $dialogTop, buttonBottom: $buttonBottom');
        print('   矢印上端: $arrowTopY, ボタンからの実際の距離: ${gapFromButton.toStringAsFixed(1)}px');
        print('   必要距離: ${idealGap}px, 重なり: ${gapFromButton < 0 ? "あり" : "なし"}');
      }
      // 3. 画面上部に固定配置（スペース不足の場合）
      else {
        dialogTop = safeArea.top + minSpacing;
        _arrowDirection = ArrowDirection.none;
        print('⚠️ [TutorialOverlay] スペース不足のため画面上部に配置');
        print('   dialogTop: $dialogTop, 利用可能上部: ${spaceAboveButton.toStringAsFixed(1)}px, 下部: ${spaceBelowButton.toStringAsFixed(1)}px');
      }
    }
    
    // 画面境界内に収める（安全な範囲内に配置）
    final originalDialogTop = dialogTop;
    dialogTop = dialogTop.clamp(safeArea.top, screenHeight - safeArea.bottom - dialogHeight);
    
    if (originalDialogTop != dialogTop) {
      print('⚠️ [TutorialOverlay] ダイアログ位置を画面境界内に調整: ${originalDialogTop.toStringAsFixed(1)} → ${dialogTop.toStringAsFixed(1)}');
    }
    
    print('📍 [TutorialOverlay] 最終配置 - ダイアログ: ${dialogTop.toStringAsFixed(1)}, 矢印方向: $_arrowDirection');
    
    return dialogTop;
  }

  /// ダイアログ高さの動的推定
  double _estimateDialogHeight() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // デバイスサイズに応じた基本高さ
    double baseHeight = 200.0;
    
    if (screenWidth > 600) {
      // タブレット
      baseHeight = 240.0;
    } else if (screenWidth <= 350) {
      // 小型スマートフォン
      baseHeight = 180.0;
    }
    
    // テキスト長に応じた調整
    final titleLines = (widget.title.length / 20).ceil();
    final descriptionLines = (widget.description.length / 30).ceil();
    
    final additionalHeight = (titleLines - 1) * 24 + (descriptionLines - 2) * 20;
    
    return baseHeight + additionalHeight;
  }

  /// デバイス対応の最小余白計算
  double _getDeviceAwareSpacing(double devicePixelRatio, double screenWidth) {
    // 高密度ディスプレイでは余白を調整
    double baseSpacing = 20.0;
    
    if (devicePixelRatio > 3.0) {
      baseSpacing = 25.0;
    } else if (devicePixelRatio < 2.0) {
      baseSpacing = 15.0;
    }
    
    // 画面幅に応じた調整
    if (screenWidth > 600) {
      baseSpacing += 10.0; // タブレットでは余白を増やす
    } else if (screenWidth <= 350) {
      baseSpacing -= 5.0; // 小型デバイスでは余白を減らす
    }
    
    return baseSpacing;
  }

  /// ツールチップと矢印を統合したウィジェット
  Widget _buildTooltipWithArrow() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上向き矢印（ダイアログが下にある場合）
        if (_arrowDirection == ArrowDirection.up)
          _buildArrow(isUpward: true),
        
        // ダイアログ本体（強調された影付き）
        Container(
          padding: const EdgeInsets.all(SpacingConsts.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // 強い影で浮遊感を演出（最上層であることを明確に）
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
            // プライマリカラーのボーダーで視認性向上
            border: Border.all(
              color: ColorConsts.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: _buildDialogContent(),
        ),
        
        // 下向き矢印（ダイアログが上にある場合）
        if (_arrowDirection == ArrowDirection.down)
          _buildArrow(isUpward: false),
      ],
    );
  }

  /// 矢印ウィジェット（動的サイズ対応）
  Widget _buildArrow({required bool isUpward}) {
    // デバイスサイズに応じた矢印サイズ
    final screenWidth = MediaQuery.of(context).size.width;
    final arrowWidth = screenWidth > 600 ? 36.0 : 30.0;
    const arrowHeight = 20.0;
    
    return SizedBox(
      width: arrowWidth,
      height: arrowHeight,
      child: CustomPaint(
        painter: TrianglePainter(
          color: Colors.white,
          borderColor: ColorConsts.primary.withValues(alpha: 0.2),
          isUpward: isUpward,
        ),
      ),
    );
  }

  /// ダイアログの内容
  Widget _buildDialogContent() {
    // レスポンシブ対応のためのテキストスタイル取得
    final titleStyle = _getResponsiveTitleStyle();
    final bodyStyle = _getResponsiveBodyStyle();
    
    return Column(
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
                style: titleStyle.copyWith(
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
          style: bodyStyle.copyWith(
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
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsivePadding(),
                    vertical: SpacingConsts.sm,
                  ),
                ),
                child: Text(
                  'スキップ',
                  style: _getResponsiveLabelStyle().copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: SpacingConsts.sm),
            ],
            
            CommonButton(
              text: widget.onNext != null ? '次へ' : '完了',
              variant: ButtonVariant.primary,
              size: _getResponsiveButtonSize(),
              onPressed: widget.onNext,
            ),
          ],
        ),
      ],
    );
  }

  /// レスポンシブ対応：タイトルスタイル
  TextStyle _getResponsiveTitleStyle() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 600) {
      // タブレット
      return TextConsts.h3;
    } else if (screenWidth > 350) {
      // 標準スマートフォン
      return TextConsts.h4;
    } else {
      // 小型スマートフォン
      return TextConsts.h4.copyWith(fontSize: 18);
    }
  }

  /// レスポンシブ対応：本文スタイル
  TextStyle _getResponsiveBodyStyle() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 600) {
      // タブレット
      return TextConsts.bodyLarge;
    } else if (screenWidth > 350) {
      // 標準スマートフォン
      return TextConsts.bodyMedium;
    } else {
      // 小型スマートフォン
      return TextConsts.bodySmall;
    }
  }

  /// レスポンシブ対応：ラベルスタイル
  TextStyle _getResponsiveLabelStyle() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 600) {
      return TextConsts.labelLarge;
    } else {
      return TextConsts.labelMedium;
    }
  }

  /// レスポンシブ対応：パディング
  double _getResponsivePadding() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 600) {
      return SpacingConsts.lg;
    } else if (screenWidth > 350) {
      return SpacingConsts.md;
    } else {
      return SpacingConsts.sm;
    }
  }

  /// レスポンシブ対応：ボタンサイズ
  ButtonSize _getResponsiveButtonSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 600) {
      return ButtonSize.large;
    } else if (screenWidth > 350) {
      return ButtonSize.medium;
    } else {
      return ButtonSize.small;
    }
  }


}

/// 三角形を描画するPainter
class TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isUpward;

  TrianglePainter({
    required this.color,
    required this.borderColor,
    required this.isUpward,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    
    if (isUpward) {
      // 上向き矢印
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      // 下向き矢印
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    
    path.close();
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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