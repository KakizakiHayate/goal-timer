import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/features/goal_detail/presentation/viewmodels/goal_detail_view_model.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/timer_view_model.dart';
import 'package:goal_timer/features/goal_timer/presentation/widgets/timer_progress_ring.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class TimerScreen extends ConsumerWidget {
  final String? goalId;

  const TimerScreen({super.key, this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerViewModelProvider);
    final timerViewModel = ref.read(timerViewModelProvider.notifier);

    // 目標情報を取得（存在する場合）
    final goalAsyncValue =
        goalId != null
            ? ref.watch(goalDetailProvider(goalId!))
            : const AsyncValue<GoalsModel?>.data(null);

    // 目標IDをタイマービューモデルに設定
    if (goalId != null && timerState.goalId != goalId) {
      // 画面表示後に一度だけ実行するために遅延実行
      Future.microtask(() {
        timerViewModel.setGoalId(goalId!);
        // 目標詳細画面から来た場合は自動的にタイマーを開始
        if (timerState.status == TimerStatus.initial) {
          timerViewModel.startTimer();
        }
      });
    }

    // 残り時間が少ない場合のフラグ（カウントダウンモードで5分以下）
    final isTimeRunningOut =
        timerState.mode == TimerMode.countdown &&
        timerState.currentSeconds <= 300 &&
        timerState.status == TimerStatus.running;

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
                data: (goalDetail) {
                  if (goalDetail == null) {
                    return const Text('目標情報の取得に失敗しました');
                  }
                  return _buildGoalInfo(context, goalDetail);
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
            // 目標IDがある場合、避けたい未来メッセージを大きく表示
            if (goalId != null) ...[
              goalAsyncValue.when(
                data: (goalDetail) {
                  if (goalDetail == null) {
                    return const SizedBox.shrink();
                  }
                  return _buildAvoidMessageBanner(
                    context,
                    goalDetail,
                    isTimeRunningOut: isTimeRunningOut,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 30),
            ],
            _buildControlButtons(context, timerState, timerViewModel),
          ],
        ),
      ),
    );
  }

  // 目標情報を表示するウィジェット
  Widget _buildGoalInfo(BuildContext context, GoalsModel goal) {
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
          const SizedBox(height: 16),
          // 避けたい未来（avoidMessage）を強調表示
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red, size: 20),
                    SizedBox(width: 6),
                    Text(
                      '避けたい未来',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  goal.avoidMessage,
                  style: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
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

  // 避けたい未来メッセージを大きく表示するバナー
  Widget _buildAvoidMessageBanner(
    BuildContext context,
    GoalsModel goal, {
    bool isTimeRunningOut = false,
  }) {
    // 残り時間が少ない場合はアニメーションを使用
    if (isTimeRunningOut) {
      return _buildAnimatedAvoidBanner(context, goal);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                '避けたい未来',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            goal.avoidMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3,
                  color: Color.fromRGBO(0, 0, 0, 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 残り時間が少ない場合の点滅するavoidメッセージバナー
  Widget _buildAnimatedAvoidBanner(BuildContext context, GoalsModel goal) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5 + (value * 0.5)),
                blurRadius: 12,
                spreadRadius: 2 + (value * 4),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 28 + (value * 4),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '避けたい未来',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                goal.avoidMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.3 + (value * 0.2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      onEnd: () {
        // アニメーションが終了したら再度開始する（点滅効果）
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            // 再描画を強制してアニメーションを再開
            (context as Element).markNeedsBuild();
          }
        });
      },
    );
  }
}
