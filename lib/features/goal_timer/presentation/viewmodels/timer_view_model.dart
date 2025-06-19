import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';
import 'package:goal_timer/core/provider/supabase/goals/goals_provider.dart';
import 'package:goal_timer/features/goal_detail/presentation/viewmodels/goal_detail_view_model.dart';
import 'package:uuid/uuid.dart';

// タイマーの状態を管理するプロバイダー
final timerViewModelProvider =
    StateNotifierProvider<TimerViewModel, TimerState>((ref) {
      return TimerViewModel(ref);
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
  final String? goalId; // 関連する目標ID（必須になる予定だが、初期化時はnullを許可）

  TimerState({
    this.totalSeconds = 25 * 60, // デフォルト25分
    this.currentSeconds = 25 * 60,
    this.status = TimerStatus.initial,
    this.mode = TimerMode.countdown,
    this.goalId,
  });

  // 新しい状態を作成するヘルパーメソッド
  TimerState copyWith({
    int? totalSeconds,
    int? currentSeconds,
    TimerStatus? status,
    TimerMode? mode,
    String? goalId,
  }) {
    return TimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentSeconds: currentSeconds ?? this.currentSeconds,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      goalId: goalId ?? this.goalId,
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

  // 目標IDが設定されているかチェック
  bool get hasGoal => goalId != null && goalId!.isNotEmpty;
}

// タイマービューモデル
class TimerViewModel extends StateNotifier<TimerState> {
  Timer? _timer;
  final Ref _ref;
  int _elapsedSeconds = 0; // タイマー実行中の経過秒数

  TimerViewModel(this._ref) : super(TimerState());

  // 目標IDを設定
  void setGoalId(String goalId) {
    state = state.copyWith(goalId: goalId);
  }

  // タイマーの開始
  void startTimer() {
    if (state.status == TimerStatus.running) return;

    // 目標IDが設定されていない場合はタイマーを開始しない
    if (!state.hasGoal) {
      AppLogger.instance.e('目標IDが設定されていないため、タイマーを開始できません');
      return;
    }

    state = state.copyWith(status: TimerStatus.running);
    _elapsedSeconds = 0; // 経過秒数リセット

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++; // 経過秒数を増加

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
    _elapsedSeconds = 0; // 経過秒数リセット
  }

  // タイマーの完了処理
  void completeTimer() {
    _timer?.cancel();
    state = state.copyWith(status: TimerStatus.completed);

    // 完了を知らせるフィードバック（ここではログのみ、実装時にバイブレーションや音を追加）
    AppLogger.instance.i(
      'タイマー完了！ 目標ID: ${state.goalId}, 実行時間: ${_elapsedSeconds}秒',
    );

    // 目標IDが設定されている場合のみ学習時間を記録
    if (state.hasGoal) {
      _recordStudyTime();
    } else {
      AppLogger.instance.e('目標IDが設定されていないため、学習時間を記録できません');
    }
  }

  // 学習時間を記録する
  Future<void> _recordStudyTime() async {
    if (!state.hasGoal) {
      AppLogger.instance.e('目標IDが設定されていないため、学習時間を記録できません');
      return;
    }

    // カウントダウンモードの場合は設定時間、カウントアップモードの場合は経過時間を使用
    final studyMinutes =
        state.mode == TimerMode.countdown
            ? state.totalSeconds ~/
                60 // 設定した時間（分）
            : _elapsedSeconds ~/ 60; // 経過した時間（分）

    if (studyMinutes <= 0) {
      AppLogger.instance.w(
        '学習時間が0分のため記録しません: 学習時間=$studyMinutes分, 目標ID=${state.goalId}',
      );
      return;
    }

    try {
      AppLogger.instance.i(
        'タイマー完了: 目標ID ${state.goalId} に $studyMinutes 分を記録します',
      );

      // 今日の日付で学習記録を作成
      final today = DateTime.now();
      final dailyLog = DailyStudyLogModel(
        id: const Uuid().v4(),
        goalId: state.goalId!,
        date: DateTime(today.year, today.month, today.day), // 時間は0:00に正規化
        minutes: studyMinutes,
      );

      // 学習記録リポジトリに記録
      final repository = _ref.read(hybridDailyStudyLogsRepositoryProvider);
      await repository.upsertDailyLog(dailyLog);

      // 目標の累計時間も更新
      final updateSpentTime = _ref.read(updateGoalSpentTimeProvider);
      await updateSpentTime(state.goalId!, studyMinutes);

      // 目標データのキャッシュをクリアして最新状態を反映
      _ref.invalidate(goalsListProvider);
      _ref.invalidate(goalDetailListProvider);

      AppLogger.instance.i('学習時間の記録が完了しました: $studyMinutes分');
    } catch (error) {
      AppLogger.instance.e('学習時間の記録に失敗しました: $error');
    }
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
    _elapsedSeconds = 0; // 経過秒数リセット
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
    _elapsedSeconds = 0; // 経過秒数リセット
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
