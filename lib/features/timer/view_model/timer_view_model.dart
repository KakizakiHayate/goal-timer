import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

// タイマー関連の定数
class TimerConstants {
  static const int tutorialDurationSeconds = 5;
  static const int countdownCompleteThreshold = 0;
  static const int pomodoroWorkMinutes = 25;
  static const int pomodoroBreakMinutes = 5;
}

// タイマーの状態を管理するプロバイダー
final timerViewModelProvider =
    StateNotifierProvider<TimerViewModel, TimerState>((ref) {
  return TimerViewModel(ref: ref);
});

// タイマーの状態
enum TimerStatus {
  initial,
  running,
  paused,
  completed,
}

// タイマーのモード
enum TimerMode {
  countdown,
  countup,
  pomodoro,
}

// タイマーの状態を表すクラス
class TimerState {
  final int totalSeconds;
  final int currentSeconds;
  final TimerStatus status;
  final TimerMode mode;
  final bool isPomodoroBreak;
  final int pomodoroRound;

  TimerState({
    this.totalSeconds = 25 * 60,
    this.currentSeconds = 25 * 60,
    this.status = TimerStatus.initial,
    this.mode = TimerMode.countdown,
    this.isPomodoroBreak = false,
    this.pomodoroRound = 1,
  });

  TimerState copyWith({
    int? totalSeconds,
    int? currentSeconds,
    TimerStatus? status,
    TimerMode? mode,
    bool? isPomodoroBreak,
    int? pomodoroRound,
  }) {
    return TimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentSeconds: currentSeconds ?? this.currentSeconds,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      isPomodoroBreak: isPomodoroBreak ?? this.isPomodoroBreak,
      pomodoroRound: pomodoroRound ?? this.pomodoroRound,
    );
  }

  double get progress {
    if (mode == TimerMode.countdown || mode == TimerMode.pomodoro) {
      return 1.0 - (currentSeconds / totalSeconds);
    } else {
      return (currentSeconds / 3600).clamp(0.0, 1.0);
    }
  }

  String formatTime() {
    final hours = currentSeconds ~/ 3600;
    final minutes = (currentSeconds % 3600) ~/ 60;
    final seconds = currentSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  bool get isPaused => status == TimerStatus.paused;
  bool get isRunning => status == TimerStatus.running;
  bool get isCompleted => status == TimerStatus.completed;
}

// タイマーのViewModel
class TimerViewModel extends StateNotifier<TimerState> {
  Timer? _timer;
  int _elapsedSeconds = 0;

  TimerViewModel({required Ref ref})
      : super(TimerState());

  void setMode(TimerMode mode) {
    state = state.copyWith(mode: mode);
    if (mode == TimerMode.countdown) {
      state = state.copyWith(
        totalSeconds: 25 * 60,
        currentSeconds: 25 * 60,
      );
    } else if (mode == TimerMode.countup) {
      state = state.copyWith(
        totalSeconds: 60 * 60,
        currentSeconds: 0,
      );
    } else if (mode == TimerMode.pomodoro) {
      state = state.copyWith(
        totalSeconds: TimerConstants.pomodoroWorkMinutes * 60,
        currentSeconds: TimerConstants.pomodoroWorkMinutes * 60,
      );
    }
  }

  void startTimer() {
    if (state.status == TimerStatus.running) return;

    state = state.copyWith(status: TimerStatus.running);
    _elapsedSeconds = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;

      if (state.mode == TimerMode.countdown || state.mode == TimerMode.pomodoro) {
        if (state.currentSeconds > 0) {
          state = state.copyWith(currentSeconds: state.currentSeconds - 1);
        } else {
          completeTimer();
        }
      } else {
        state = state.copyWith(currentSeconds: state.currentSeconds + 1);
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
    AppLogger.instance.i('タイマーを一時停止しました');
  }

  void resetTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    state = state.copyWith(
      currentSeconds: state.totalSeconds,
      status: TimerStatus.initial,
    );
    AppLogger.instance.i('タイマーをリセットしました');
  }

  void completeTimer() {
    _timer?.cancel();
    state = state.copyWith(
      status: TimerStatus.completed,
      currentSeconds: 0,
    );
    AppLogger.instance.i('タイマーが完了しました: $_elapsedSeconds秒');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
