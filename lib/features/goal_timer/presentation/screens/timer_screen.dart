import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/goal_view_model.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/timer_view_model.dart';
import 'package:goal_timer/features/goal_timer/presentation/widgets/timer_progress_ring.dart';

class TimerScreen extends ConsumerWidget {
  final String? goalId;

  const TimerScreen({super.key, this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerViewModelProvider);
    final timerViewModel = ref.read(timerViewModelProvider.notifier);

    // 目標情報を取得（存在する場合）
    final goalAsyncValue = ref.watch(goalListProvider);

    // 目標IDをタイマービューモデルに設定
    if (goalId != null && timerState.goalId != goalId) {
      // 画面表示後に一度だけ実行するために遅延実行
      Future.microtask(() {
        timerViewModel.setGoalId(goalId!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('タイマー'),
        backgroundColor: ColorConsts.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 目標情報を表示（存在する場合）
            if (goalId != null) ...[
              goalAsyncValue.when(
                data: (goals) {
                  final goal = goals.firstWhere(
                    (g) => g.id == goalId,
                    orElse:
                        () => Goal(
                          id: '',
                          title: '不明な目標',
                          description: '',
                          deadline: DateTime.now(),
                        ),
                  );

                  return _buildGoalInfo(context, goal);
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('目標情報の取得に失敗しました'),
              ),
              const SizedBox(height: 20),
            ],
            _buildModeSwitcher(context, timerState, timerViewModel),
            const SizedBox(height: 40),
            _buildTimerDisplay(context, timerState),
            const SizedBox(height: 40),
            _buildControlButtons(context, timerState, timerViewModel),
          ],
        ),
      ),
    );
  }

  // 目標情報を表示するウィジェット
  Widget _buildGoalInfo(BuildContext context, Goal goal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目標: ${goal.title}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (goal.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              goal.description,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '期限: ${_formatDate(goal.deadline)}',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // 日付のフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  Widget _buildModeSwitcher(
    BuildContext context,
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            context,
            'カウントダウン',
            timerState.mode == TimerMode.countdown,
            () => timerViewModel.changeMode(TimerMode.countdown),
            ColorConsts.primary,
          ),
          _buildModeButton(
            context,
            'カウントアップ',
            timerState.mode == TimerMode.countup,
            () => timerViewModel.changeMode(TimerMode.countup),
            ColorConsts.success,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String text,
    bool isActive,
    VoidCallback onTap,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(BuildContext context, TimerState timerState) {
    final minutes = timerState.currentSeconds ~/ 60;
    final seconds = timerState.currentSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final progressValue =
        timerState.mode == TimerMode.countdown
            ? timerState.currentSeconds /
                (25 * 60) // 25分を基準
            : timerState.currentSeconds / (60 * 60); // 1時間を基準

    final color =
        timerState.mode == TimerMode.countdown
            ? ColorConsts.primary
            : ColorConsts.success;

    return Column(
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TimerProgressRing(
                progress:
                    timerState.mode == TimerMode.countdown
                        ? progressValue
                        : 1 - progressValue,
                color: color,
                backgroundColor: Colors.grey[200]!,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    timerState.mode == TimerMode.countdown
                        ? 'カウントダウン'
                        : 'カウントアップ',
                    style: TextStyle(fontSize: 16, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    final isRunning = timerState.status == TimerStatus.running;
    final color =
        timerState.mode == TimerMode.countdown
            ? ColorConsts.primary
            : ColorConsts.success;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(
          icon: isRunning ? Icons.pause : Icons.play_arrow,
          onPressed: () {
            if (isRunning) {
              timerViewModel.pauseTimer();
            } else {
              timerViewModel.startTimer();
            }
          },
          color: color,
          size: 72,
          iconSize: 36,
        ),
        const SizedBox(width: 20),
        _buildCircleButton(
          icon: Icons.refresh,
          onPressed: () => timerViewModel.resetTimer(),
          color: Colors.grey[400]!,
        ),
        const SizedBox(width: 20),
        _buildCircleButton(
          icon: Icons.settings,
          onPressed: () {
            _showTimerSettingDialog(context, timerState, timerViewModel);
          },
          color: Colors.grey[400]!,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 56,
    double iconSize = 24,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        child: Icon(icon, size: iconSize),
      ),
    );
  }

  void _showTimerSettingDialog(
    BuildContext context,
    TimerState timerState,
    TimerViewModel timerViewModel,
  ) {
    if (timerState.mode == TimerMode.countdown) {
      showDialog(
        context: context,
        builder: (context) {
          int minutes = 25; // デフォルト25分

          return AlertDialog(
            title: const Text('タイマー設定'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('カウントダウン時間（分）'),
                    Slider(
                      value: minutes.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      label: minutes.toString(),
                      onChanged: (value) {
                        setState(() {
                          minutes = value.toInt();
                        });
                      },
                    ),
                    Text('$minutes分', style: const TextStyle(fontSize: 18)),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  timerViewModel.setTime(minutes);
                  Navigator.pop(context);
                },
                child: const Text('設定'),
              ),
            ],
          );
        },
      );
    }
  }
}
