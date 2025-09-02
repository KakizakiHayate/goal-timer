import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';
import 'package:goal_timer/core/provider/supabase/goals/goals_provider.dart';
import 'package:goal_timer/features/goal_detail/presentation/viewmodels/goal_detail_view_model.dart';
import 'package:goal_timer/core/services/timer_restriction_service.dart';
import 'package:uuid/uuid.dart';

// タイマー関連の定数
class TimerConstants {
  static const int tutorialDurationSeconds = 5; // チュートリアル用タイマーの秒数
  static const int countdownCompleteThreshold = 0; // カウントダウン完了の閾値
  static const int pomodoroWorkMinutes = 25; // ポモドーロ作業時間（分）
  static const int pomodoroBreakMinutes = 5; // ポモドーロ休憩時間（分）
}

// タイマー制限サービスのプロバイダー
final timerRestrictionServiceProvider = Provider<TimerRestrictionService>((
  ref,
) {
  return TimerRestrictionService();
});

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
  pomodoro, // ポモドーロ（25分集中 + 5分休憩）
}

// タイマーの状態を表すクラス
class TimerState {
  final int totalSeconds; // カウントダウン用の合計秒数
  final int currentSeconds; // 現在の秒数（カウントダウン/カウントアップ両用）
  final TimerStatus status; // 状態
  final TimerMode mode; // モード
  final String? goalId; // 関連する目標ID（必須になる予定だが、初期化時はnullを許可）
  final bool isPomodoroBreak; // ポモドーロの休憩中かどうか
  final int pomodoroRound; // ポモドーロの現在のラウンド数

  TimerState({
    this.totalSeconds = 25 * 60, // デフォルト25分
    this.currentSeconds = 25 * 60,
    this.status = TimerStatus.initial,
    this.mode = TimerMode.countdown,
    this.goalId,
    this.isPomodoroBreak = false,
    this.pomodoroRound = 1,
  });

  // 新しい状態を作成するヘルパーメソッド
  TimerState copyWith({
    int? totalSeconds,
    int? currentSeconds,
    TimerStatus? status,
    TimerMode? mode,
    String? goalId,
    bool? isPomodoroBreak,
    int? pomodoroRound,
  }) {
    return TimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentSeconds: currentSeconds ?? this.currentSeconds,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      goalId: goalId ?? this.goalId,
      isPomodoroBreak: isPomodoroBreak ?? this.isPomodoroBreak,
      pomodoroRound: pomodoroRound ?? this.pomodoroRound,
    );
  }

  // 進捗率（0.0〜1.0）
  double get progress {
    if (mode == TimerMode.countdown || mode == TimerMode.pomodoro) {
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
  bool _isTutorialMode = false; // チュートリアルモードフラグ

  TimerViewModel(this._ref) : super(TimerState()) {
    // タイマー制限サービスを初期化
    _initializeRestrictions();
  }

  // タイマー制限サービスを初期化
  Future<void> _initializeRestrictions() async {
    final restrictionService = _ref.read(timerRestrictionServiceProvider);
    await restrictionService.initializeUserPlan();
  }

  // 目標IDを設定
  void setGoalId(String goalId) {
    state = state.copyWith(goalId: goalId);
  }

  // チュートリアルモードを設定
  void setTutorialMode(bool isTutorialMode) {
    _isTutorialMode = isTutorialMode;
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
        if (state.currentSeconds <= TimerConstants.countdownCompleteThreshold) {
          completeTimer();
        } else {
          state = state.copyWith(currentSeconds: state.currentSeconds - 1);
        }
      } else if (state.mode == TimerMode.pomodoro) {
        // ポモドーロモード
        if (state.currentSeconds <= 1) {
          _completePomodoroTimer();
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
    int initialSeconds;
    switch (state.mode) {
      case TimerMode.countdown:
        initialSeconds = state.totalSeconds;
        break;
      case TimerMode.countup:
        initialSeconds = 0;
        break;
      case TimerMode.pomodoro:
        initialSeconds = 25 * 60; // ポモドーロは25分に戻す
        break;
    }

    state = state.copyWith(
      currentSeconds: initialSeconds,
      status: TimerStatus.initial,
      isPomodoroBreak: false, // ポモドーロリセット時は集中時間に戻す
      pomodoroRound: 1, // ラウンドもリセット
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
      _recordStudyTime(_isTutorialMode);
    } else {
      AppLogger.instance.e('目標IDが設定されていないため、学習時間を記録できません');
    }
  }

  // ポモドーロタイマーの完了処理
  void _completePomodoroTimer() {
    _timer?.cancel();

    if (state.isPomodoroBreak) {
      // 休憩完了 -> 次のラウンドの集中時間に移行
      state = state.copyWith(
        isPomodoroBreak: false,
        pomodoroRound: state.pomodoroRound + 1,
        currentSeconds: 25 * 60, // 25分集中
        totalSeconds: 25 * 60,
        status: TimerStatus.initial,
      );
      AppLogger.instance.i('ポモドーロ休憩完了！ラウンド${state.pomodoroRound}の集中時間が始まります');
    } else {
      // 集中時間完了 -> 学習時間記録 & 休憩時間に移行
      AppLogger.instance.i('ポモドーロ集中時間完了！ ラウンド: ${state.pomodoroRound}');

      // 学習時間を記録（25分固定）
      if (state.hasGoal) {
        _recordStudyTime(_isTutorialMode);
      }

      // 4ラウンド目なら長い休憩（15分）、それ以外は短い休憩（5分）
      final breakMinutes = (state.pomodoroRound % 4 == 0) ? 15 : 5;

      state = state.copyWith(
        isPomodoroBreak: true,
        currentSeconds: breakMinutes * 60,
        totalSeconds: breakMinutes * 60,
        status: TimerStatus.initial,
      );

      AppLogger.instance.i('${breakMinutes}分の休憩時間に入ります');
    }
  }

  // 学習時間を記録する
  Future<void> _recordStudyTime([bool isTutorialMode = false]) async {
    // チュートリアルモードの場合はデータを保存しない
    if (isTutorialMode) {
      AppLogger.instance.i('チュートリアルモード: タイマーデータの保存をスキップしました');
      return;
    }

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

      // 目標の累計時間も更新 - 一時的に無効化（HybridRepository対応が必要）
      // TODO: updateGoalUseCaseProviderを使用して目標の累計時間を更新する必要がある
      try {
        final goalsRepository = _ref.read(hybridGoalsRepositoryProvider);
        final currentGoal = await goalsRepository.getGoalById(state.goalId!);
        if (currentGoal != null) {
          final updatedGoal = currentGoal.copyWith(
            spentMinutes: currentGoal.spentMinutes + studyMinutes,
          );
          await goalsRepository.updateGoal(updatedGoal);
        }
      } catch (e) {
        AppLogger.instance.w('目標の累計時間更新に失敗しました（記録は保存済み）: $e');
      }

      // 目標データのキャッシュをクリアして最新状態を反映
      _ref.invalidate(goalDetailListProvider);

      AppLogger.instance.i('学習時間の記録が完了しました: $studyMinutes分');
    } catch (error) {
      AppLogger.instance.e('学習時間の記録に失敗しました: $error');
    }
  }

  // タイマーモードの変更
  void changeMode(TimerMode mode) {
    // 制限チェック
    final restrictionService = _ref.read(timerRestrictionServiceProvider);
    final modeString = _timerModeToString(mode);

    if (!restrictionService.canUseTimerMode(modeString)) {
      AppLogger.instance.w('制限されたモードへの変更を試行: $modeString');
      return; // 制限されている場合は変更しない
    }

    if (state.status == TimerStatus.running) {
      pauseTimer();
    }

    // モードに基づいて初期値を設定
    int initialSeconds;
    int totalSeconds;

    switch (mode) {
      case TimerMode.countdown:
        initialSeconds = state.totalSeconds;
        totalSeconds = state.totalSeconds;
        break;
      case TimerMode.countup:
        initialSeconds = 0;
        totalSeconds = state.totalSeconds;
        break;
      case TimerMode.pomodoro:
        initialSeconds = 25 * 60; // ポモドーロは25分から開始
        totalSeconds = 25 * 60;
        break;
    }

    state = state.copyWith(
      mode: mode,
      currentSeconds: initialSeconds,
      totalSeconds: totalSeconds,
      status: TimerStatus.initial,
      isPomodoroBreak: false, // ポモドーロ切り替え時はリセット
      pomodoroRound: 1, // ラウンドもリセット
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

  // チュートリアル用のタイマー時間を設定（秒単位）
  void setTutorialTime(int seconds) {
    if (state.status == TimerStatus.running) {
      pauseTimer();
    }

    state = state.copyWith(
      totalSeconds: seconds,
      currentSeconds: state.mode == TimerMode.countdown ? seconds : 0,
      status: TimerStatus.initial,
    );
    _elapsedSeconds = 0; // 経過秒数リセット
  }

  // タイマーモードを制限サービス用の文字列に変換
  String _timerModeToString(TimerMode mode) {
    switch (mode) {
      case TimerMode.countdown:
        return 'countdown';
      case TimerMode.countup:
        return 'countup';
      case TimerMode.pomodoro:
        return 'pomodoro';
    }
  }

  // TimerModeから表示ラベルを取得
  String getModeLabel(TimerMode mode) {
    switch (mode) {
      case TimerMode.countdown:
        return 'フォーカス';
      case TimerMode.countup:
        return 'フリー';
      case TimerMode.pomodoro:
        return 'ポモドーロ';
    }
  }

  // 現在のモードの表示ラベル
  String get currentModeLabel => getModeLabel(state.mode);

  // ポモドーロモードの説明文を取得
  String get pomodoroDescription {
    if (state.mode != TimerMode.pomodoro) {
      return '';
    }

    if (state.isPomodoroBreak) {
      final minutes = state.currentSeconds ~/ 60;
      return 'ラウンド${state.pomodoroRound} - 休憩中 ($minutes分)';
    } else {
      return 'ラウンド${state.pomodoroRound} - 集中中 (25分)';
    }
  }

  // 特定のモードが利用可能かチェック
  bool canUseMode(TimerMode mode) {
    final restrictionService = _ref.read(timerRestrictionServiceProvider);
    return restrictionService.canUseTimerMode(_timerModeToString(mode));
  }

  // 利用可能なモード一覧を取得
  List<TimerMode> getAvailableModes() {
    final restrictionService = _ref.read(timerRestrictionServiceProvider);
    final available = restrictionService.getAvailableTimerModes();

    return TimerMode.values.where((mode) {
      return available.contains(_timerModeToString(mode));
    }).toList();
  }

  // モードの制限メッセージを取得
  String getModeRestrictionMessage(TimerMode mode) {
    final restrictionService = _ref.read(timerRestrictionServiceProvider);
    return restrictionService.getRestrictionMessage(_timerModeToString(mode));
  }

  // 現在のユーザープランを取得
  String getCurrentPlan() {
    final restrictionService = _ref.read(timerRestrictionServiceProvider);
    return restrictionService.getCurrentPlan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
