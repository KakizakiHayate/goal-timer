import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// タイマーの状態を管理するプロバイダー
final timerViewModelProvider =
    StateNotifierProvider<TimerViewModel, TimerState>((ref) {
      return TimerViewModel();
    });

// タイマーの状態
enum TimerStatus {
  initial, // 初期状態
  running, // 実行中
  paused, // 一時停止中
  completed, // 完了
}

// タイマーのモード
enum TimerMode {
  countdown, // カウントダウン
  countup, // カウントアップ
}

// タイマーの状態を表すクラス
class TimerState {
  final int totalSeconds; // カウントダウン用の合計秒数
  final int currentSeconds; // 現在の秒数（カウントダウン/カウントアップ両用）
  final TimerStatus status; // 状態
  final TimerMode mode; // モード

  TimerState({
    this.totalSeconds = 25 * 60, // デフォルト25分
    this.currentSeconds = 25 * 60,
    this.status = TimerStatus.initial,
    this.mode = TimerMode.countdown,
  });

  // 新しい状態を作成するヘルパーメソッド
  TimerState copyWith({
    int? totalSeconds,
    int? currentSeconds,
    TimerStatus? status,
    TimerMode? mode,
  }) {
    return TimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentSeconds: currentSeconds ?? this.currentSeconds,
      status: status ?? this.status,
      mode: mode ?? this.mode,
    );
  }

  // 進捗率（0.0〜1.0）
  double get progress {
    if (mode == TimerMode.countdown) {
      return 1.0 - (currentSeconds / totalSeconds);
    } else {
      // カウントアップの場合は1時間（3600秒）を最大として進捗率を計算
      return (currentSeconds / 3600).clamp(0.0, 1.0);
    }
  }

  // 表示用の時間文字列（例: 25:00）
  String get displayTime {
    final minutes = (currentSeconds / 60).floor();
    final seconds = currentSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// タイマービューモデル
class TimerViewModel extends StateNotifier<TimerState> {
  Timer? _timer;

  TimerViewModel() : super(TimerState());

  // タイマーの開始
  void startTimer() {
    if (state.status == TimerStatus.running) return;

    state = state.copyWith(status: TimerStatus.running);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.mode == TimerMode.countdown) {
        // カウントダウンモード
        if (state.currentSeconds <= 1) {
          completeTimer();
        } else {
          state = state.copyWith(currentSeconds: state.currentSeconds - 1);
        }
      } else {
        // カウントアップモード
        state = state.copyWith(currentSeconds: state.currentSeconds + 1);
      }
    });
  }

  // タイマーの一時停止
  void pauseTimer() {
    if (state.status != TimerStatus.running) return;

    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  // タイマーのリセット
  void resetTimer() {
    _timer?.cancel();

    // モードによって初期値を変更
    final initialSeconds =
        (state.mode == TimerMode.countdown) ? state.totalSeconds : 0;

    state = state.copyWith(
      currentSeconds: initialSeconds,
      status: TimerStatus.initial,
    );
  }

  // タイマーの完了処理
  void completeTimer() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.completed);
  }

  // タイマーモードの変更
  void changeMode(TimerMode mode) {
    if (state.status == TimerStatus.running) {
      pauseTimer();
    }

    // モードに基づいて初期値を設定
    final initialSeconds =
        (mode == TimerMode.countdown) ? state.totalSeconds : 0;

    state = state.copyWith(
      mode: mode,
      currentSeconds: initialSeconds,
      status: TimerStatus.initial,
    );
  }

  // カウントダウンの時間を設定（分単位）
  void setTime(int minutes) {
    if (state.status == TimerStatus.running) {
      pauseTimer();
    }

    final newTotalSeconds = minutes * 60;
    state = state.copyWith(
      totalSeconds: newTotalSeconds,
      currentSeconds: state.mode == TimerMode.countdown ? newTotalSeconds : 0,
      status: TimerStatus.initial,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
