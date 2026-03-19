import 'dart:async';

import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/local/local_settings_datasource.dart';
import '../../../core/data/repositories/study_logs_repository.dart';
import '../../../core/data/repositories/users_repository.dart';
import '../../../core/models/goals/goals_model.dart';
import '../../../core/models/study_daily_logs/study_daily_logs_model.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/rating_service.dart';
import '../../../core/utils/app_consts.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/streak_consts.dart';
import '../../../core/utils/time_utils.dart';
import '../../settings/view_model/settings_view_model.dart';

// タイマー関連の定数
class TimerConstants {
  static const int tutorialDurationSeconds = 5;
  static const int countdownCompleteThreshold = 0;
  static const int pomodoroWorkMinutes = 25;
  static const int pomodoroBreakMinutes = 5;
  static const int initialPomodoroRound = 1;
  static const int initialElapsedSeconds = 0;
  static const int countupInitialSeconds = 0;
  static const int timerIntervalSeconds = 1;
  static const int decrementValue = 1;
  static const int incrementValue = 1;
}

// タイマーの状態
enum TimerStatus { initial, running, paused, completed }

// タイマーのモード
enum TimerMode { countdown, countup, pomodoro }

// タイマーの状態を表すクラス
class TimerState {
  final int totalSeconds;
  final int currentSeconds;
  final int pomodoroRound;
  final TimerStatus status;
  final TimerMode mode;
  final bool isPomodoroBreak;
  final bool needsCompletionConfirm;
  final bool shouldShowFeedbackPopup;

  // デフォルト値の定数
  static const int _defaultSeconds =
      TimerConstants.pomodoroWorkMinutes * TimeUtils.secondsPerMinute;

  TimerState({
    int? totalSeconds,
    int? currentSeconds,
    this.status = TimerStatus.initial,
    this.mode = TimerMode.countdown,
    this.isPomodoroBreak = false,
    this.pomodoroRound = TimerConstants.initialPomodoroRound,
    this.needsCompletionConfirm = false,
    this.shouldShowFeedbackPopup = false,
  }) : totalSeconds = totalSeconds ?? _defaultSeconds,
       currentSeconds = currentSeconds ?? _defaultSeconds;

  TimerState copyWith({
    int? totalSeconds,
    int? currentSeconds,
    TimerStatus? status,
    TimerMode? mode,
    bool? isPomodoroBreak,
    int? pomodoroRound,
    bool? needsCompletionConfirm,
    bool? shouldShowFeedbackPopup,
  }) {
    return TimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentSeconds: currentSeconds ?? this.currentSeconds,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      isPomodoroBreak: isPomodoroBreak ?? this.isPomodoroBreak,
      pomodoroRound: pomodoroRound ?? this.pomodoroRound,
      needsCompletionConfirm:
          needsCompletionConfirm ?? this.needsCompletionConfirm,
      shouldShowFeedbackPopup:
          shouldShowFeedbackPopup ?? this.shouldShowFeedbackPopup,
    );
  }

  String formatTime() {
    return TimeUtils.formatDurationFromSeconds(currentSeconds);
  }

  bool get isShowTimerFinishButton {
    return status == TimerStatus.running || status == TimerStatus.paused;
  }

  bool get isPaused => status == TimerStatus.paused;
  bool get isRunning => status == TimerStatus.running;
  bool get isCompleted => status == TimerStatus.completed;

  /// モード切り替えが可能かどうか
  /// タイマーが動作中または一時停止中の場合は切り替え不可
  bool get isModeSwitchable =>
      status == TimerStatus.initial || status == TimerStatus.completed;

  /// 戻る時に確認ダイアログが必要かどうか
  /// 1秒でもカウントしていれば確認が必要
  /// ただし、完了済み（completed）の場合は不要
  bool get needsBackConfirmation {
    // 完了済みの場合は確認不要
    if (status == TimerStatus.completed) {
      return false;
    }

    switch (mode) {
      case TimerMode.countup:
        // カウントアップ: 1秒でもカウントしていれば確認が必要
        return currentSeconds > TimerConstants.countupInitialSeconds;
      case TimerMode.countdown:
      case TimerMode.pomodoro:
        // カウントダウン/ポモドーロ: 1秒でも減っていれば確認が必要
        return currentSeconds < totalSeconds;
    }
  }
}

// タイマーのViewModel
class TimerViewModel extends GetxController {
  final StudyLogsRepository _studyLogsRepository;
  final UsersRepository _usersRepository;
  final AuthService _authService;
  final GoalsModel goal;

  // PRコメント対応: インスタンス変数として一度だけ取得
  final SettingsViewModel _settingsViewModel;

  // 音声サービス
  final AudioService _audioService;

  // 通知サービス
  final NotificationService _notificationService;

  // 設定DataSource（フィードバック状態管理用）
  final LocalSettingsDataSource _settingsDataSource;

  Timer? _timer;
  int _elapsedSeconds = TimerConstants.initialElapsedSeconds;

  // バックグラウンド対応: タイマー開始時刻と一時停止時の累積経過秒数
  DateTime? _timerStartTime;
  int _pausedElapsedSeconds = TimerConstants.initialElapsedSeconds;

  // 学習セッションの開始日（深夜0時またぎ対応: 開始日を基準にログを保存）
  // 初回startTimer()でセット、pause/resumeでは維持、reset/保存完了でクリア
  DateTime? _studySessionStartDay;

  // 状態（Rxで管理）
  final Rx<TimerState> _state = TimerState().obs;
  TimerState get state => _state.value;

  // 経過時間を取得するgetter
  int get elapsedSeconds => _elapsedSeconds;

  /// 現在のユーザーID
  ///
  /// マイグレーション済み（Supabase使用時）は必ず値が存在する。
  /// マイグレーション未済（ローカルDB使用時）はnullの場合がある。
  String? get _userId => _authService.currentUserId;

  /// Repositoryに渡す用のユーザーID（nullの場合は空文字）
  String get _userIdForRepository => _authService.currentUserId ?? '';

  /// コンストラクタ（DIパターン適用）
  /// テスト時にはRepositoryを注入可能
  TimerViewModel({
    required this.goal,
    StudyLogsRepository? studyLogsRepository,
    UsersRepository? usersRepository,
    AuthService? authService,
    SettingsViewModel? settingsViewModel,
    NotificationService? notificationService,
    LocalSettingsDataSource? settingsDataSource,
    AudioService? audioService,
  }) : _settingsViewModel = settingsViewModel ?? Get.find<SettingsViewModel>(),
       _audioService = audioService ?? AudioService(),
       _notificationService = notificationService ?? NotificationService(),
       _studyLogsRepository = studyLogsRepository ?? StudyLogsRepository(),
       _usersRepository = usersRepository ?? UsersRepository(),
       _authService = authService ?? AuthService(),
       _settingsDataSource = settingsDataSource ?? LocalSettingsDataSource() {
    final defaultSeconds = _settingsViewModel.defaultTimerSeconds.value;

    _state.value = TimerState(
      totalSeconds: defaultSeconds,
      currentSeconds: defaultSeconds,
    );

    _initNotificationService();
  }

  Future<void> _initNotificationService() async {
    await _notificationService.init();
    await _notificationService.requestPermission();
  }

  @override
  void onClose() {
    _timer?.cancel();
    try {
      _audioService.dispose();
    } catch (error, stackTrace) {
      AppLogger.instance.e('AudioServiceのdisposeに失敗しました', error, stackTrace);
    }
    // タイマー完了通知のみキャンセル（ストリークリマインダーは維持）
    try {
      _notificationService.cancelScheduledNotification();
    } catch (error, stackTrace) {
      AppLogger.instance.e('通知のキャンセルに失敗しました', error, stackTrace);
    }
    super.onClose();
  }

  /// モードを設定する
  /// 戻り値: モード切り替えが成功した場合はtrue、ブロックされた場合はfalse
  bool setMode(TimerMode mode) {
    if (!state.isModeSwitchable) {
      AppLogger.instance.w('タイマー動作中のためモード切り替えをブロックしました');
      return false;
    }

    _state.value = state.copyWith(mode: mode);
    switch (mode) {
      case TimerMode.countdown:
        // PRコメント対応: インスタンス変数を使用
        final defaultSeconds = _settingsViewModel.defaultTimerSeconds.value;
        _state.value = state.copyWith(
          totalSeconds: defaultSeconds,
          currentSeconds: defaultSeconds,
        );
      case TimerMode.countup:
        // カウントアップモード: 上限なし
        _state.value = state.copyWith(
          totalSeconds: TimerConstants.countupInitialSeconds,
          currentSeconds: TimerConstants.countdownCompleteThreshold,
        );
      case TimerMode.pomodoro:
        const pomodoroSeconds =
            TimerConstants.pomodoroWorkMinutes * TimeUtils.secondsPerMinute;
        _state.value = state.copyWith(
          totalSeconds: pomodoroSeconds,
          currentSeconds: pomodoroSeconds,
        );
    }
    return true;
  }

  void startTimer() {
    if (state.status == TimerStatus.running) return;

    // バックグラウンド対応: 開始時刻を記録
    _timerStartTime = DateTime.now();

    // 学習セッションの開始日を記録（初回のみ）
    // 深夜0時またぎ対応: 開始日を基準にログを保存するため
    final now = DateTime.now();
    _studySessionStartDay ??= DateTime(now.year, now.month, now.day);

    _state.value = state.copyWith(
      status: TimerStatus.running,
      needsCompletionConfirm: false,
    );

    // カウントダウンモードの場合、繰り返し完了通知をスケジュール
    if (state.mode == TimerMode.countdown) {
      _scheduleCompletionNotification();
    }

    _timer = Timer.periodic(
      const Duration(seconds: TimerConstants.timerIntervalSeconds),
      (_) {
        _elapsedSeconds += TimerConstants.incrementValue;

        if (state.mode == TimerMode.countdown ||
            state.mode == TimerMode.pomodoro) {
          if (state.currentSeconds > TimeUtils.minValidSeconds) {
            _state.value = state.copyWith(
              currentSeconds:
                  state.currentSeconds - TimerConstants.decrementValue,
            );
          } else {
            completeTimer();
          }
        } else {
          // カウントアップモード: 上限なしで継続
          _state.value = state.copyWith(
            currentSeconds:
                state.currentSeconds + TimerConstants.incrementValue,
          );
        }
      },
    );
  }

  void pauseTimer() {
    _timer?.cancel();
    // バックグラウンド対応: 一時停止時の累積経過秒数を保存
    _pausedElapsedSeconds = _elapsedSeconds;
    _timerStartTime = null;
    _state.value = state.copyWith(status: TimerStatus.paused);
    // 通知をキャンセル
    _notificationService.cancelScheduledNotification();
    AppLogger.instance.i('タイマーを一時停止しました');
  }

  void resetTimer() {
    _timer?.cancel();
    _elapsedSeconds = TimerConstants.initialElapsedSeconds;
    _pausedElapsedSeconds = TimerConstants.initialElapsedSeconds;
    _timerStartTime = null;
    _studySessionStartDay = null; // 学習セッションの開始日をクリア
    _state.value = state.copyWith(
      currentSeconds: state.totalSeconds,
      status: TimerStatus.initial,
      needsCompletionConfirm: false,
    );
    // タイマー完了通知のみキャンセル（ストリークリマインダーは維持）
    _notificationService.cancelScheduledNotification();
    AppLogger.instance.i('タイマーをリセットしました');
  }

  void completeTimer() {
    _timer?.cancel();
    _timerStartTime = null;
    _state.value = state.copyWith(
      status: TimerStatus.completed,
      currentSeconds: TimerConstants.countdownCompleteThreshold,
      needsCompletionConfirm: true,
    );

    // カウントダウンモードの場合のみチャイム音を再生
    if (state.mode == TimerMode.countdown) {
      unawaited(_audioService.playTimerCompletionSound());
    }

    AppLogger.instance.i('タイマーが完了しました: $_elapsedSeconds秒');
    // フィードバックポップアップの判定はonTappedTimerFinishButtonで行う
    // （学習記録保存時にカウント）
  }

  /// フィードバックポップアップの表示判定を行い、必要に応じてフラグを立てる
  /// 1分以上の学習でカウント対象
  Future<void> _checkAndShowFeedbackPopup() async {
    try {
      // 最低学習時間（1分）未満はカウント対象外
      if (_elapsedSeconds < AppConsts.minStudySecondsForFeedback) {
        AppLogger.instance.i(
          'フィードバック: 学習時間が${AppConsts.minStudySecondsForFeedback}秒未満のためカウント対象外 '
          '($_elapsedSeconds秒)',
        );
        return;
      }

      // 学習完了カウントをインクリメント
      await _settingsDataSource.incrementCountdownCompletionCount();

      // 表示条件を満たしているかチェック
      final shouldShow = await _settingsDataSource.shouldShowFeedbackPopup();

      if (shouldShow) {
        _state.value = state.copyWith(shouldShowFeedbackPopup: true);
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'フィードバックポップアップの表示判定に失敗しました',
        error,
        stackTrace,
      );
    }
  }

  /// フィードバックポップアップの表示フラグをクリアする
  void clearFeedbackPopupFlag() {
    _state.value = state.copyWith(shouldShowFeedbackPopup: false);
  }

  /// フィードバックポップアップを非表示にした日時を記録する
  /// （「回答する」または「今はしない」を選択した場合に呼び出す）
  Future<void> recordFeedbackDismissed() async {
    try {
      await _settingsDataSource.saveLastFeedbackDismissedAt(DateTime.now());
      // カウントをリセット（次の3回目から再表示するため）
      await _settingsDataSource.resetCountdownCompletionCount();
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'フィードバック非表示日時の記録に失敗しました',
        error,
        stackTrace,
      );
    }
  }

  /// 完了通知をスケジュールする（繰り返し通知）
  Future<void> _scheduleCompletionNotification() async {
    if (state.currentSeconds > TimeUtils.minValidSeconds) {
      try {
        await _notificationService.scheduleRepeatingCompletionNotifications(
          delayBeforeCompletionSeconds: state.currentSeconds,
          goalTitle: goal.title,
          studyDurationSeconds: state.totalSeconds,
        );
      } catch (error, stackTrace) {
        AppLogger.instance.e(
          '完了通知のスケジュールに失敗しました',
          error,
          stackTrace,
        );
      }
    }
  }

  /// バックグラウンドから復帰した時に呼び出す
  /// フォアグラウンド復帰時に経過時間を再計算し、タイマーを再開する
  void onAppResumed() {
    final startTime = _timerStartTime;
    if (state.status != TimerStatus.running || startTime == null) {
      return;
    }

    final now = DateTime.now();
    final backgroundElapsed = now.difference(startTime).inSeconds;
    final totalElapsed = _pausedElapsedSeconds + backgroundElapsed;

    AppLogger.instance.i(
      'バックグラウンドから復帰: 経過時間=$backgroundElapsed秒, 累計=$totalElapsed秒',
    );

    if (state.mode == TimerMode.countdown || state.mode == TimerMode.pomodoro) {
      // カウントダウン/ポモドーロモード: 残り時間を計算
      final newCurrentSeconds = state.totalSeconds - totalElapsed;

      if (newCurrentSeconds <= TimeUtils.minValidSeconds) {
        // バックグラウンド中に完了した場合
        _elapsedSeconds = state.totalSeconds;
        // 残りの繰り返し通知をキャンセル（ユーザーがアプリに戻ったため不要）
        try {
          _notificationService.cancelRepeatingCompletionNotifications();
        } catch (error, stackTrace) {
          AppLogger.instance.e(
            '繰り返し通知のキャンセルに失敗しました',
            error,
            stackTrace,
          );
        }
        completeTimer();
        AppLogger.instance.i('バックグラウンド中にタイマーが完了しました');
      } else {
        // まだ完了していない場合: 経過時間を更新してタイマーを再開
        _elapsedSeconds = totalElapsed;
        _pausedElapsedSeconds = totalElapsed;
        _timerStartTime = now;
        _state.value = state.copyWith(currentSeconds: newCurrentSeconds);
        _restartTimer();
      }
    } else {
      // カウントアップモード: 経過時間を更新してタイマーを再開
      _elapsedSeconds = totalElapsed;
      _pausedElapsedSeconds = totalElapsed;
      _timerStartTime = now;
      _state.value = state.copyWith(currentSeconds: totalElapsed);
      _restartTimer();
    }
  }

  /// タイマーを再開する（バックグラウンド復帰時用）
  void _restartTimer() {
    // 既存のタイマーがあればキャンセル
    _timer?.cancel();

    AppLogger.instance.i('タイマーを再開します');

    _timer = Timer.periodic(
      const Duration(seconds: TimerConstants.timerIntervalSeconds),
      (_) {
        _elapsedSeconds += TimerConstants.incrementValue;

        if (state.mode == TimerMode.countdown ||
            state.mode == TimerMode.pomodoro) {
          if (state.currentSeconds > TimeUtils.minValidSeconds) {
            _state.value = state.copyWith(
              currentSeconds:
                  state.currentSeconds - TimerConstants.decrementValue,
            );
          } else {
            completeTimer();
          }
        } else {
          // カウントアップモード: 上限なしで継続
          _state.value = state.copyWith(
            currentSeconds:
                state.currentSeconds + TimerConstants.incrementValue,
          );
        }
      },
    );
  }

  /// バックグラウンドに移行する時に呼び出す
  void onAppPaused() {
    if (state.status != TimerStatus.running) {
      return;
    }

    // タイマーを停止（バックグラウンドでは動作しないため）
    _timer?.cancel();
    AppLogger.instance.i('アプリがバックグラウンドに移行しました');
  }

  /// 確認ダイアログを表示した後にフラグをクリアする
  void clearCompletionConfirmFlag() {
    _state.value = state.copyWith(needsCompletionConfirm: false);
  }

  Future<void> onTappedTimerFinishButton() async {
    try {
      // バリデーション
      if (goal.id.isEmpty) {
        AppLogger.instance.e('目標IDが設定されていません');
        return;
      }

      if (_elapsedSeconds <= TimeUtils.minValidSeconds) {
        AppLogger.instance.w('学習時間が0秒のため記録しません');
        return;
      }

      AppLogger.instance.i('学習記録を保存します: $_elapsedSeconds秒');

      await saveStudyDailyLogData();

      // 🔍 デバッグ: 保存後に全ログを表示
      await debugPrintAllLogs();

      // フィードバックポップアップの表示判定（リセット前に実行）
      await _checkAndShowFeedbackPopup();

      // タイマーをリセット
      resetTimer();
    } catch (error, stackTrace) {
      AppLogger.instance.e('学習記録の保存に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  Future<void> saveStudyDailyLogData() async {
    try {
      // 深夜0時またぎ対応: 学習セッションの開始日を使用
      // 例: 23:50開始→0:10終了の場合、開始日（前日）にカウント
      final studyDate = _studySessionStartDay ?? DateTime.now();
      final log = StudyDailyLogsModel(
        id: const Uuid().v4(),
        goalId: goal.id,
        studyDate: DateTime(studyDate.year, studyDate.month, studyDate.day),
        totalSeconds: _elapsedSeconds,
        userId: _userId,
      );

      // Repository経由で保存
      await _studyLogsRepository.upsertLog(log);

      // 保存完了後、学習セッションの開始日をクリア
      _studySessionStartDay = null;

      AppLogger.instance.i('学習記録を保存しました: ${log.id}, 学習日: ${log.studyDate}');

      // 1分以上学習した場合のみストリーク関連の処理を実行
      if (_elapsedSeconds >= StreakConsts.minStudySeconds) {
        await _updateLongestStreakIfNeeded();
      } else {
        AppLogger.instance.i('学習時間が1分未満のためストリーク処理をスキップ');
      }

      // 学習完了時に評価モーダル表示判定を実行
      await RatingService().onStudyCompleted();
    } catch (error, stackTrace) {
      AppLogger.instance.e('学習記録の保存に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 現在のストリークが最長を超えていれば更新する
  Future<void> _updateLongestStreakIfNeeded() async {
    try {
      final userId = _userIdForRepository;

      // 現在のストリークを計算
      final currentStreak = await _studyLogsRepository.calculateCurrentStreak(
        userId,
      );

      // 最長ストリークと比較して必要なら更新
      final updated = await _usersRepository.updateLongestStreakIfNeeded(
        currentStreak,
        userId,
      );

      if (updated) {
        AppLogger.instance.i('最長ストリークを更新しました: $currentStreak日');
      }

      // 明日のストリークリマインダーをスケジュール
      await _scheduleTomorrowStreakReminders(currentStreak);
    } catch (error, stackTrace) {
      // 最長ストリーク更新の失敗はログのみ（致命的エラーとしては扱わない）
      AppLogger.instance.e('最長ストリークの更新に失敗しました', error, stackTrace);
    }
  }

  /// 明日のストリークリマインダーをスケジュールする
  Future<void> _scheduleTomorrowStreakReminders(int currentStreak) async {
    try {
      final userId = _userIdForRepository;

      // リマインダー設定が有効かどうかを確認
      final reminderEnabled = await _usersRepository.getStreakReminderEnabled(
        userId,
      );
      if (!reminderEnabled) {
        AppLogger.instance.i('ストリークリマインダーはOFFのためスケジュールをスキップ');
        return;
      }

      // 今日のリマインダーをキャンセル（学習完了したため）
      await _notificationService.cancelTodayStreakReminders();

      // 明日のリマインダーをスケジュール
      await _notificationService.scheduleTomorrowStreakReminders(
        streakDays: currentStreak,
      );

      AppLogger.instance.i('明日のストリークリマインダーをスケジュールしました: $currentStreak日');
    } catch (error, stackTrace) {
      // リマインダースケジュールの失敗はログのみ（致命的エラーとしては扱わない）
      AppLogger.instance.e('ストリークリマインダーのスケジュールに失敗しました', error, stackTrace);
    }
  }

  /// デバッグ用: 保存されているログを全件取得して表示
  Future<void> debugPrintAllLogs() async {
    try {
      final logs = await _studyLogsRepository.fetchAllLogs(_userIdForRepository);
      AppLogger.instance.i('=== 保存されているログ一覧 (${logs.length}件) ===');

      if (logs.isEmpty) {
        AppLogger.instance.i('ログが1件も保存されていません');
      } else {
        for (var log in logs) {
          AppLogger.instance.i(
            'ID: ${log.id.substring(0, 8)}..., '
            'GoalID: ${log.goalId}, '
            'Date: ${log.studyDate.toString().substring(0, 10)}, '
            'Seconds: ${log.totalSeconds}秒, '
            'Synced: ${log.syncUpdatedAt != null ? "✓" : "✗"}',
          );
        }
      }

      AppLogger.instance.i('====================================');
    } catch (error, stackTrace) {
      AppLogger.instance.e('ログ取得失敗', error, stackTrace);
    }
  }
}
