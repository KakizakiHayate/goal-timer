import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import '../view_model/timer_view_model.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/color_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/circular_progress_indicator.dart' as custom;

/// タイマー画面
class TimerScreen extends StatefulWidget {
  final GoalsModel goal;
  final String goalId;
  final bool isTutorialMode;

  const TimerScreen({
    super.key,
    required this.goal,
    required this.goalId,
    this.isTutorialMode = false,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    AppLogger.instance.i('TimerScreen: goalId=${widget.goalId}');

    // WidgetsBindingObserverを登録
    WidgetsBinding.instance.addObserver(this);

    // ViewModel の生成と注入（goal全体を渡す）
    Get.put(TimerViewModel(goal: widget.goal));
  }

  @override
  void dispose() {
    // WidgetsBindingObserverを解除
    WidgetsBinding.instance.removeObserver(this);
    Get.delete<TimerViewModel>();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final timerViewModel = Get.find<TimerViewModel>();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // アプリがバックグラウンドに移行
        timerViewModel.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        // アプリがフォアグラウンドに復帰
        timerViewModel.onAppResumed();
        // バックグラウンド中に完了した場合、確認ダイアログを表示
        _checkAndShowBackgroundCompletionDialog();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _checkAndShowBackgroundCompletionDialog() {
    final timerViewModel = Get.find<TimerViewModel>();
    if (timerViewModel.state.needsCompletionConfirm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showBackgroundCompletionDialog(context, timerViewModel);
        }
      });
    }
  }

  void _showBackgroundCompletionDialog(
    BuildContext context,
    TimerViewModel timerViewModel,
  ) {
    timerViewModel.clearCompletionConfirmFlag();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'タイマー完了',
          style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'バックグラウンド中にタイマーが完了しました。\n${TimeUtils.formatSecondsToHoursAndMinutes(timerViewModel.elapsedSeconds)}を学習完了として記録しますか？',
          style: TextConsts.body.copyWith(color: ColorConsts.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              timerViewModel.resetTimer();
              Navigator.pop(context);
            },
            child: Text(
              '記録しない',
              style: TextConsts.body.copyWith(
                color: ColorConsts.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await timerViewModel.onTappedTimerFinishButton();
              navigator.pop();
              navigator.pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '記録する',
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final timerViewModel = Get.find<TimerViewModel>();
      final timerState = timerViewModel.state;

      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorConsts.primary, ColorConsts.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.all(SpacingConsts.m),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'タイマー',
                          style: TextConsts.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // AppBarの中央揃え用
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(SpacingConsts.l),
                      child: Column(
                        children: [
                          const SizedBox(height: SpacingConsts.l),

                          // モード切り替え
                          _buildModeSwitcher(timerState, timerViewModel),

                          const SizedBox(height: SpacingConsts.xl),

                          // タイマー表示
                          _buildTimerDisplay(timerState),

                          const SizedBox(height: SpacingConsts.xl),

                          // コントロールボタン
                          _buildControlButtons(timerState, timerViewModel),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildModeSwitcher(
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // フォーカス（カウントダウン）
          _buildModeButton(
            'フォーカス',
            timerState.mode == TimerMode.countdown,
            () => _onModeTapped(timerViewModel, TimerMode.countdown),
            Icons.timer_outlined,
          ),

          // フリー（カウントアップ）
          _buildModeButton(
            'フリー',
            timerState.mode == TimerMode.countup,
            () => _onModeTapped(timerViewModel, TimerMode.countup),
            Icons.all_inclusive,
          ),
        ],
      ),
    );
  }

  void _onModeTapped(
    TimerViewModel timerViewModel,
    TimerMode newMode,
  ) {
    if (!timerViewModel.setMode(newMode)) {
      _showModeSwitchBlockedDialog(context);
    }
  }

  void _showModeSwitchBlockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'モード切り替え',
          style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'タイマーを保存またはリセットしてからモードを切り替えてください',
          style: TextConsts.body.copyWith(color: ColorConsts.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'OK',
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

  Widget _buildModeButton(
    String text,
    bool isActive,
    VoidCallback onTap,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingConsts.m,
          vertical: SpacingConsts.s,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
            const SizedBox(width: SpacingConsts.xs),
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

  /// プログレス値を計算する
  double _calculateProgressValue(TimerState timerState) {
    if (timerState.mode == TimerMode.countdown ||
        timerState.mode == TimerMode.pomodoro) {
      // カウントダウン/ポモドーロモード: 残り時間の割合を表示
      if (timerState.totalSeconds <= TimeUtils.minValidSeconds) {
        return TimeUtils.minValidSeconds.toDouble();
      }
      return timerState.currentSeconds / timerState.totalSeconds;
    } else {
      // カウントアップモード: 1時間ごとにリセットするプログレス表示
      return (timerState.currentSeconds % TimeUtils.secondsPerHour) /
          TimeUtils.secondsPerHour;
    }
  }

  Widget _buildTimerDisplay(TimerState timerState) {
    final timeText = timerState.formatTime();
    final progressValue = _calculateProgressValue(timerState);

    return Container(
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
          custom.CustomCircularProgressIndicator(
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
                SizedBox(
                  width: 220,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      timeText,
                      style: TextConsts.h1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 56,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SpacingConsts.s),
                Text(
                  _getTimerStatusText(timerState),
                  style: TextConsts.body.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimerStatusText(TimerState timerState) {
    if (timerState.isRunning) {
      return '集中中...';
    } else if (timerState.isPaused) {
      return '一時停止中';
    } else {
      return 'スタートを押してください';
    }
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
          onPressed: () {
            if (isRunning) {
              timerViewModel.pauseTimer();
            } else {
              timerViewModel.startTimer();
            }
          },
        ),

        const SizedBox(width: SpacingConsts.l),

        // 完了ボタン（経過時間がある場合のみ表示）
        timerState.isShowTimerFinishButton
            ? _buildControlButton(
              icon: Icons.check_rounded,
              onPressed: () {
                timerViewModel.pauseTimer();
                _showCompleteConfirmDialog(context, timerState, timerViewModel);
              },
              backgroundColor: Colors.green.withOpacity(0.2),
              iconColor: Colors.white,
            )
            : const SizedBox(width: 64), // ボタンサイズ分のスペースを確保
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
  }) {
    return GestureDetector(
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

  void _showCompleteConfirmDialog(
    BuildContext context,
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              '学習完了',
              style: TextConsts.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Text(
              '${TimeUtils.formatSecondsToHoursAndMinutes(timerViewModel.elapsedSeconds)}を学習完了として記録しますか？',
              style: TextConsts.body.copyWith(color: ColorConsts.textSecondary),
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
                onPressed: () async {
                  await timerViewModel.onTappedTimerFinishButton();
                  if (context.mounted) {
                    // ダイアログを閉じる
                    Navigator.pop(context);
                    // タイマー画面を閉じて、学習完了を通知（trueを返す）
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConsts.success,
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
