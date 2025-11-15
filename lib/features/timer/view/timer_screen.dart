import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_model/timer_view_model.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/color_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/widgets/pressable_card.dart';

/// タイマー画面
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

class _TimerScreenState extends ConsumerState<TimerScreen> {
  @override
  void initState() {
    super.initState();
    AppLogger.instance.i('TimerScreen: goalId=${widget.goalId}');

    // 画面表示後にgoalIdを設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timerViewModelProvider.notifier).setGoalId(widget.goalId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerViewModelProvider);
    final timerViewModel = ref.read(timerViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: const Text('タイマー'),
        backgroundColor: ColorConsts.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // タイマー表示
              _buildTimerDisplay(timerState),

              SizedBox(height: SpacingConsts.xl),

              // 進捗インジケーター
              _buildProgressIndicator(timerState),

              SizedBox(height: SpacingConsts.xl),

              // コントロールボタン
              _buildControlButtons(timerState, timerViewModel),

              SizedBox(height: SpacingConsts.xl),

              // モード切替
              _buildModeSelector(timerState, timerViewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(TimerState timerState) {
    return Text(
      timerState.formatTime(),
      style: TextConsts.h1.copyWith(
        fontSize: 64,
        color: ColorConsts.textPrimary,
      ),
    );
  }

  Widget _buildProgressIndicator(TimerState timerState) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CircularProgressIndicator(
        value: timerState.progress,
        strokeWidth: 8,
        backgroundColor: ColorConsts.backgroundSecondary,
        valueColor: AlwaysStoppedAnimation<Color>(ColorConsts.primary),
      ),
    );
  }

  Widget _buildControlButtons(TimerState timerState, TimerViewModel timerViewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 開始/一時停止ボタン
        PressableCard(
          onTap: () {
            if (timerState.isRunning) {
              timerViewModel.pauseTimer();
            } else {
              timerViewModel.startTimer();
            }
          },
          child: Container(
            padding: EdgeInsets.all(SpacingConsts.md),
            decoration: BoxDecoration(
              color: timerState.isRunning
                  ? ColorConsts.backgroundSecondary
                  : ColorConsts.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              timerState.isRunning ? Icons.pause : Icons.play_arrow,
              size: 48,
              color: timerState.isRunning
                  ? ColorConsts.textPrimary
                  : Colors.white,
            ),
          ),
        ),

        SizedBox(width: SpacingConsts.md),

        // リセットボタン
        PressableCard(
          onTap: () {
            timerViewModel.resetTimer();
          },
          child: Container(
            padding: EdgeInsets.all(SpacingConsts.md),
            decoration: BoxDecoration(
              color: ColorConsts.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.refresh,
              size: 48,
              color: ColorConsts.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(TimerState timerState, TimerViewModel timerViewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: TimerMode.values.map((mode) {
        final isSelected = timerState.mode == mode;
        final modeLabel = _getModeLabel(mode);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: SpacingConsts.xs),
          child: PressableCard(
            onTap: () {
              timerViewModel.setMode(mode);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: SpacingConsts.md,
                vertical: SpacingConsts.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorConsts.primary
                    : ColorConsts.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                modeLabel,
                style: TextConsts.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : ColorConsts.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getModeLabel(TimerMode mode) {
    switch (mode) {
      case TimerMode.countdown:
        return 'カウントダウン';
      case TimerMode.countup:
        return 'カウントアップ';
      case TimerMode.pomodoro:
        return 'ポモドーロ';
    }
  }
}
