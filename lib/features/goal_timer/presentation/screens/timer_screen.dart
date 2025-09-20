import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/timer_view_model.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/circular_progress_indicator.dart' as custom;
import '../../../../core/widgets/animated_check_icon.dart';
import '../../../../core/widgets/pressable_card.dart';
import '../../../onboarding/presentation/view_models/tutorial_view_model.dart';
import '../../../onboarding/presentation/widgets/tutorial_overlay.dart';
import '../../../onboarding/presentation/widgets/tutorial_completion_dialog.dart';
import '../../../../core/utils/route_names.dart';
import '../../../../core/provider/providers.dart';

/// 改善されたタイマー画面
/// 集中力向上とモチベーション維持に焦点を当てたデザイン
class TimerScreen extends ConsumerStatefulWidget {
  final String goalId;
  final bool isTutorialMode;

  const TimerScreen({
    super.key, 
    required this.goalId,
    this.isTutorialMode = false,
  });

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen>
    with TickerProviderStateMixin {
  static final Set<String> _loggedGoalIds = {};

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  bool _showCompletionAnimation = false;
  
  // チュートリアル用：メインタイマーボタンのKey
  final GlobalKey _mainTimerButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: AnimationConsts.smoothCurve,
      ),
    );

    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedGoalIds.contains(widget.goalId)) {
      AppLogger.instance.i('TimerScreenV2: goalId=${widget.goalId}');
      _loggedGoalIds.add(widget.goalId);
    }

    final timerState = ref.watch(timerViewModelProvider);
    final timerViewModel = ref.read(timerViewModelProvider.notifier);
    final tutorialState = ref.watch(tutorialViewModelProvider);

    // チュートリアル中のタイマー完了を監視
    ref.listen(timerViewModelProvider, (previous, current) {
      // 最新のチュートリアル状態を取得
      final currentTutorialState = ref.read(tutorialViewModelProvider);
      
      AppLogger.instance.d('🔍 タイマー状態変化を検知:');
      AppLogger.instance.d('  - isTutorialMode: ${widget.isTutorialMode}');
      AppLogger.instance.d('  - currentTutorialState.isTutorialActive: ${currentTutorialState.isTutorialActive}');
      AppLogger.instance.d('  - currentTutorialState.currentStepId: ${currentTutorialState.currentStepId}');
      AppLogger.instance.d('  - previous?.status: ${previous?.status}');
      AppLogger.instance.d('  - current.status: ${current.status}');
      
      if (widget.isTutorialMode && 
          currentTutorialState.isTutorialActive &&
          previous?.status != TimerStatus.completed &&
          current.status == TimerStatus.completed) {
        AppLogger.instance.i('🎉 チュートリアル完了条件を満たしました - ダイアログを表示します');
        
        // ダイアログ表示（completeTutorialはダイアログ内で実行）
        _showTutorialCompletionDialog();
      } else {
        AppLogger.instance.d('⚠️ チュートリアル完了条件を満たしていません');
        if (!widget.isTutorialMode) {
          AppLogger.instance.d('   理由: isTutorialMode=false');
        }
        if (!currentTutorialState.isTutorialActive) {
          AppLogger.instance.d('   理由: isTutorialActive=false');
        }
        if (previous?.status == TimerStatus.completed) {
          AppLogger.instance.d('   理由: 既にcompletedだった');
        }
        if (current.status != TimerStatus.completed) {
          AppLogger.instance.d('   理由: currentはcompletedではない');
        }
      }
    });

    // 目標IDをタイマービューモデルに設定
    if (timerState.goalId != widget.goalId) {
      Future.microtask(() {
        timerViewModel.setGoalId(widget.goalId);
        timerViewModel.setTutorialMode(widget.isTutorialMode);
      });
    }

    // チュートリアルモードの場合、タイマーを5秒に設定
    if (widget.isTutorialMode && timerState.status == TimerStatus.initial) {
      Future.microtask(() {
        timerViewModel.setTutorialTime(TimerConstants.tutorialDurationSeconds);
      });
    }

    // タイマー実行中のパルスアニメーション
    if (timerState.status == TimerStatus.running &&
        !_pulseAnimationController.isAnimating) {
      _pulseAnimationController.repeat(reverse: true);
    } else if (timerState.status != TimerStatus.running) {
      _pulseAnimationController.stop();
      _pulseAnimationController.reset();
    }

    final mainScaffold = Scaffold(
      backgroundColor: _getBackgroundColor(timerState),
      appBar: _buildAppBar(timerState),
      body: SlideTransition(
        position: _slideAnimation,
        child: Stack(
          children: [
            // メインコンテンツ
            _buildMainContent(context, timerState, timerViewModel),

            // 完了アニメーション
            if (_showCompletionAnimation) _buildCompletionOverlay(),
          ],
        ),
      ),
    );

    // チュートリアルオーバーレイの表示
    if (widget.isTutorialMode && 
        tutorialState.isTutorialActive &&
        tutorialState.currentStepId == 'timer_operation' &&
        timerState.status == TimerStatus.initial) {
      return Stack(
        children: [
          mainScaffold,
          _buildTimerOperationTutorial(),
        ],
      );
    }

    return mainScaffold;
  }

  PreferredSizeWidget _buildAppBar(TimerState timerState) {
    return AppBar(
      title: Text(
        'フォーカスタイム',
        style: TextConsts.h3.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _getThemeColor(timerState),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          final timerViewModel = ref.read(timerViewModelProvider.notifier);
          if (timerViewModel.hasElapsedTime) {
            _showExitConfirmDialog(context);
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(SpacingConsts.l),
        child: Column(
          children: [
            const SizedBox(height: SpacingConsts.l),

            // モード切り替え
            _buildModeSwitcher(timerState, timerViewModel),

            const SizedBox(height: SpacingConsts.l),

            // タイマー表示
            _buildTimerDisplay(timerState, timerViewModel),

            const SizedBox(height: SpacingConsts.l),

            // コントロールボタン
            _buildControlButtons(timerState, timerViewModel),

            const SizedBox(height: SpacingConsts.l),

            // 統計情報
            _buildStatsCard(timerState),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitcher(
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    final availableModes = timerViewModel.getAvailableModes();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.all(2), // 余白を削減
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min, // 必要最小限の幅に
            children: [
              // フォーカス（カウントダウン）
              if (availableModes.contains(TimerMode.countdown))
                _buildModeButton(
                  'フォーカス',
                  timerState.mode == TimerMode.countdown,
                  () => timerViewModel.changeMode(TimerMode.countdown),
                  Icons.timer_outlined,
                ),

              // フリー（カウントアップ）
              if (availableModes.contains(TimerMode.countup))
                _buildModeButton(
                  'フリー',
                  timerState.mode == TimerMode.countup,
                  () => timerViewModel.changeMode(TimerMode.countup),
                  Icons.all_inclusive,
                ),

              // ポモドーロ（プレミアム機能）
              if (availableModes.contains(TimerMode.pomodoro))
                _buildModeButton(
                  'ポモドーロ',
                  timerState.mode == TimerMode.pomodoro,
                  () => timerViewModel.changeMode(TimerMode.pomodoro),
                  Icons.spa,
                )
              else if (TimerMode.values.contains(TimerMode.pomodoro))
                _buildLockedModeButton(
                  'ポモドーロ',
                  Icons.spa,
                  timerViewModel.getModeRestrictionMessage(TimerMode.pomodoro),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(
    String text,
    bool isActive,
    VoidCallback onTap,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimationConsts.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingConsts.m, // 水平の余白を削減
          vertical: SpacingConsts.s,   // 垂直の余白を削減
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? ColorConsts.textPrimary : Colors.white,
              size: 20,
            ),
            const SizedBox(width: SpacingConsts.xs), // アイコンとテキストの間隔を縮小
            Text(
              text,
              style: TextConsts.body.copyWith(
                color: isActive ? ColorConsts.textPrimary : Colors.white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedModeButton(
    String text,
    IconData icon,
    String restrictionMessage,
  ) {
    return GestureDetector(
      onTap: () {
        // 制限メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(restrictionMessage),
            backgroundColor: ColorConsts.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingConsts.m, // 水平の余白を削減
          vertical: SpacingConsts.s,   // 垂直の余白を削減
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              color: Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: SpacingConsts.xs), // アイコンとテキストの間隔を縮小
            Text(
              text,
              style: TextConsts.body.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    final minutes = timerState.currentSeconds ~/ 60;
    final seconds = timerState.currentSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final progressValue =
        timerState.mode == TimerMode.countdown
            ? timerState.currentSeconds / (25 * 60)
            : (timerState.currentSeconds % (60 * 60)) / (60 * 60);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale:
              timerState.status == TimerStatus.running
                  ? _pulseAnimation.value
                  : 1.0,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  offset: const Offset(0, 8),
                  blurRadius: 32,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // プログレスリング
                custom.CircularProgressIndicator(
                  progress:
                      timerState.mode == TimerMode.countdown
                          ? 1 - progressValue
                          : progressValue,
                  size: 260.0,
                  strokeWidth: 12.0,
                  progressColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  showAnimation: false,
                  centerWidget: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeText,
                        style: TextConsts.h1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 56,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: SpacingConsts.s),
                      Text(
                        _getTimerStatusText(timerState, timerViewModel),
                        style: TextConsts.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButtons(
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    final isRunning = timerState.status == TimerStatus.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // リセットボタン
        _buildControlButton(
          icon: Icons.refresh_rounded,
          onPressed: () => timerViewModel.resetTimer(),
          backgroundColor: Colors.white.withOpacity(0.2),
          iconColor: Colors.white,
        ),

        const SizedBox(width: SpacingConsts.l),

        // メイン操作ボタン
        _buildMainControlButton(
          icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          key: _mainTimerButtonKey, // チュートリアル用のKey
          onPressed: () {
            if (isRunning) {
              timerViewModel.pauseTimer();
            } else {
              timerViewModel.startTimer();
            }
          },
        ),

        const SizedBox(width: SpacingConsts.l),

        // 学習完了ボタン（設定ボタンを置き換え）
        if (_shouldShowCompletionButton(timerState))
          _buildControlButton(
            icon: Icons.check_rounded,
            onPressed: () => _showCompleteConfirmDialog(context, timerState, timerViewModel),
            backgroundColor: Colors.white.withOpacity(0.2),
            iconColor: Colors.white,
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    double size = 64.0,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }

  Widget _buildMainControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    GlobalKey? key,
  }) {
    return GestureDetector(
      key: key,
      onTap: onPressed,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Icon(icon, color: ColorConsts.textPrimary, size: 40),
      ),
    );
  }

  Widget _buildStatsCard(TimerState timerState) {
    return PressableCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(SpacingConsts.l),
      backgroundColor: Colors.white.withOpacity(0.1),
      borderRadius: 20.0,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.schedule_rounded,
              label: '今日の総時間',
              value: '2時間 30分', // TODO: 実際のデータに置き換え
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              icon: Icons.whatshot_rounded,
              label: '連続日数',
              value: '5日', // TODO: 実際のデータに置き換え
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: SpacingConsts.xs),
        Text(
          value,
          style: TextConsts.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextConsts.caption.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompletionOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: AnimatedCheckIcon(
          show: _showCompletionAnimation,
          size: 120.0,
          onComplete: () {
            setState(() {
              _showCompletionAnimation = false;
            });
          },
        ),
      ),
    );
  }

  Color _getBackgroundColor(TimerState timerState) {
    if (timerState.mode == TimerMode.countdown) {
      return ColorConsts.primary;
    } else if (timerState.mode == TimerMode.pomodoro) {
      // ポモドーロモードは集中時間と休憩時間で色を変える
      return timerState.isPomodoroBreak
          ? const Color(0xFF059669)
          : ColorConsts.primary;
    } else {
      return ColorConsts.success;
    }
  }

  Color _getThemeColor(TimerState timerState) {
    if (timerState.mode == TimerMode.countdown ||
        timerState.mode == TimerMode.pomodoro) {
      return ColorConsts.primaryDark;
    } else {
      return const Color(0xFF059669);
    }
  }

  String _getTimerStatusText(
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    switch (timerState.mode) {
      case TimerMode.countdown:
        return 'フォーカス中';
      case TimerMode.countup:
        return 'フリータイム';
      case TimerMode.pomodoro:
        if (timerState.isPomodoroBreak) {
          final breakType =
              (timerState.pomodoroRound % 4 == 0) ? '長い休憩' : '短い休憩';
          return 'ラウンド${timerState.pomodoroRound}\n$breakType';
        } else {
          return 'ラウンド${timerState.pomodoroRound}\n集中時間';
        }
    }
  }


  void _showExitConfirmDialog(BuildContext context) {
    final timerState = ref.read(timerViewModelProvider);
    final timerViewModel = ref.read(timerViewModelProvider.notifier);
    
    // 経過時間がない場合は直接終了
    if (!timerViewModel.hasElapsedTime) {
      Navigator.of(context).pop();
      return;
    }

    // モード別の学習時間計算（表示用）
    int studyMinutes;
    switch (timerState.mode) {
      case TimerMode.countdown:
        studyMinutes = (timerState.totalSeconds - timerState.currentSeconds) ~/ 60;
        break;
      case TimerMode.countup:
        studyMinutes = timerState.currentSeconds ~/ 60;
        break;
      case TimerMode.pomodoro:
        studyMinutes = 25;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '学習時間の保存',
          style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '次回から学習から離れる場合は、学習完了のチェックマークボタンを押してください\n\nカウントした時間が失われてしまいます。保存しますか？',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('↩️'),
                const SizedBox(width: 4),
                Text(
                  '戻る',
                  style: TextConsts.body.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              Navigator.pop(context); // タイマー画面を閉じる
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🗑️'),
                const SizedBox(width: 4),
                Text(
                  '保存しない',
                  style: TextConsts.body.copyWith(
                    color: ColorConsts.error,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              timerViewModel.completeTimerManually();
              Navigator.pop(context); // ダイアログを閉じる
              // フィードバック表示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${studyMinutes}分の学習を記録しました'),
                  backgroundColor: ColorConsts.success,
                  duration: const Duration(seconds: 2),
                ),
              );
              Navigator.pop(context); // タイマー画面を閉じる
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💾'),
                const SizedBox(width: 4),
                Text(
                  '保存する',
                  style: TextConsts.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// チュートリアル：タイマー操作ガイド
  Widget _buildTimerOperationTutorial() {
    return TutorialOverlay(
      targetButtonKey: _mainTimerButtonKey,
      title: 'タイマーを開始しよう',
      description: 'スタートボタンをタップしてタイマーを開始します。チュートリアル用に5秒間のデモタイマーが設定されています。',
      onNext: () async {
        final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.nextStep('timer_completion');
      },
      onSkip: () async {
        final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.skipTutorial();
        if (mounted) {
          Navigator.pushReplacementNamed(context, RouteNames.onboardingAccountPromotion);
        }
      },
    );
  }

  /// チュートリアル完了ダイアログを表示
  Future<void> _showTutorialCompletionDialog() async {
    AppLogger.instance.i('🎨 _showTutorialCompletionDialog()開始');
    AppLogger.instance.d('  - mounted状態: $mounted');
    AppLogger.instance.d('  - goalId: ${widget.goalId}');
    
    // 目標データを取得
    try {
      AppLogger.instance.d('📋 目標データを取得中...');
      final goalsRepository = ref.read(hybridGoalsRepositoryProvider);
      final goal = await goalsRepository.getGoalById(widget.goalId);
      final goalTitle = goal?.title ?? '学習目標';
      AppLogger.instance.i('✅ 目標データ取得成功: $goalTitle');

      if (mounted) {
        AppLogger.instance.i('🎭 ダイアログ表示開始');
        TutorialCompletionDialog.show(
          context,
          goalTitle: goalTitle,
          onContinue: () async {
            AppLogger.instance.i('▶️ 続けるボタンがタップされました');
            
            // ここでチュートリアル完了処理を実行
            final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
            await tutorialViewModel.completeTutorial();
            AppLogger.instance.i('✅ チュートリアル完了処理が完了しました');
            
            Navigator.of(context).pop(); // ダイアログを閉じる
            AppLogger.instance.i('🚀 AccountPromotionScreenへ遷移中...');
            Navigator.pushReplacementNamed(
              context, 
              RouteNames.onboardingAccountPromotion,
            );
          },
        );
        AppLogger.instance.i('✨ ダイアログ表示完了');
      } else {
        AppLogger.instance.w('⚠️ ウィジェットがmountされていません');
      }
    } catch (e) {
      AppLogger.instance.e('❌ 目標データ取得エラー: $e');
      // エラーの場合はデフォルトのタイトルで表示
      if (mounted) {
        AppLogger.instance.i('🎭 エラー時ダイアログ表示開始');
        TutorialCompletionDialog.show(
          context,
          goalTitle: '学習目標',
          onContinue: () async {
            AppLogger.instance.i('▶️ 続けるボタンがタップされました（エラー時）');
            
            // ここでチュートリアル完了処理を実行
            final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
            await tutorialViewModel.completeTutorial();
            AppLogger.instance.i('✅ チュートリアル完了処理が完了しました（エラー時）');
            
            Navigator.of(context).pop(); // ダイアログを閉じる
            AppLogger.instance.i('🚀 AccountPromotionScreenへ遷移中...（エラー時）');
            Navigator.pushReplacementNamed(
              context, 
              RouteNames.onboardingAccountPromotion,
            );
          },
        );
      }
    }
  }

  // 学習完了ボタンの表示判定
  bool _shouldShowCompletionButton(TimerState timerState) {
    final timerViewModel = ref.read(timerViewModelProvider.notifier);
    return timerState.status == TimerStatus.running ||
           timerState.status == TimerStatus.paused ||
           timerViewModel.hasElapsedTime;
  }

  void _showCompleteConfirmDialog(
    BuildContext context,
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    // モード別の学習時間計算（表示用）
    int studyMinutes;
    switch (timerState.mode) {
      case TimerMode.countdown:
        studyMinutes = (timerState.totalSeconds - timerState.currentSeconds) ~/ 60;
        break;
      case TimerMode.countup:
        studyMinutes = timerViewModel.hasElapsedTime ? (timerState.currentSeconds ~/ 60) : 0;
        break;
      case TimerMode.pomodoro:
        studyMinutes = 25;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '学習完了',
          style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '$studyMinutes分を学習完了として記録しますか？',
          style: TextConsts.body.copyWith(
            color: ColorConsts.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'キャンセル',
              style: TextConsts.body.copyWith(
                color: ColorConsts.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              timerViewModel.completeTimerManually();
              Navigator.pop(context);
              // フィードバック表示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${studyMinutes}分の学習を記録しました！'),
                  backgroundColor: ColorConsts.success,
                  duration: const Duration(seconds: 2),
                ),
              );
              // タイマー画面を閉じる
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '完了',
              style: TextConsts.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
