import 'dart:async';
import 'package:get/get.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

// タイマー関連の定数
class TimerConstants {
  static const int tutorialDurationSeconds = 5;
  static const int countdownCompleteThreshold = 0;
  static const int pomodoroWorkMinutes = 25;
  static const int pomodoroBreakMinutes = 5;
}

// タイマーの状態
enum TimerStatus { initial, running, paused, completed }

// タイマーのモード
enum TimerMode { countdown, countup, pomodoro }

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
class TimerViewModel extends GetxController {
  Timer? _timer;
  int _elapsedSeconds = 0;

  // 状態（Rxを使わない）
  TimerState _state = TimerState();
  TimerState get state => _state;

  void setMode(TimerMode mode) {
    _state = state.copyWith(mode: mode);
    if (mode == TimerMode.countdown) {
      _state = state.copyWith(
        totalSeconds: 25 * 60,
        currentSeconds: 25 * 60,
      );
    } else if (mode == TimerMode.countup) {
      _state = state.copyWith(totalSeconds: 60 * 60, currentSeconds: 0);
    } else if (mode == TimerMode.pomodoro) {
      _state = state.copyWith(
        totalSeconds: TimerConstants.pomodoroWorkMinutes * 60,
        currentSeconds: TimerConstants.pomodoroWorkMinutes * 60,
      );
    }
    update(); // GetBuilderに通知
  }

  void startTimer() {
    if (state.status == TimerStatus.running) return;

    _state = state.copyWith(status: TimerStatus.running);
    update(); // GetBuilderに通知
    _elapsedSeconds = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;

      if (state.mode == TimerMode.countdown ||
          state.mode == TimerMode.pomodoro) {
        if (state.currentSeconds > 0) {
          _state = state.copyWith(
            currentSeconds: state.currentSeconds - 1,
          );
          update(); // GetBuilderに通知
        } else {
          completeTimer();
        }
      } else {
        _state = state.copyWith(currentSeconds: state.currentSeconds + 1);
        update(); // GetBuilderに通知
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _state = state.copyWith(status: TimerStatus.paused);
    update(); // GetBuilderに通知
    AppLogger.instance.i('タイマーを一時停止しました');
  }

  void resetTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _state = state.copyWith(
      currentSeconds: state.totalSeconds,
      status: TimerStatus.initial,
    );
    update(); // GetBuilderに通知
    AppLogger.instance.i('タイマーをリセットしました');
  }

  void completeTimer() {
    _timer?.cancel();
    _state = state.copyWith(
      status: TimerStatus.completed,
      currentSeconds: 0,
    );
    update(); // GetBuilderに通知
    AppLogger.instance.i('タイマーが完了しました: $_elapsedSeconds秒');
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
