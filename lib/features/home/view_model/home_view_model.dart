import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/repositories/goals_repository.dart';
import '../../../core/data/repositories/study_logs_repository.dart';
import '../../../core/data/repositories/users_repository.dart';
import '../../../core/models/goals/goals_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/crashlytics_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/streak_consts.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/utils/user_consts.dart';

/// 目標削除操作の結果
enum DeleteGoalResult { success, failure }

/// エラーの種類
enum HomeErrorType { save, update, delete }

// Home画面の状態
class HomeState {
  final List<GoalsModel> goals;
  final Map<String, int> studiedSecondsByGoalId;
  final bool isLoading;
  final int currentStreak;
  final List<DateTime> recentStudyDates;
  final String displayName;
  final String? errorMessage;
  final HomeErrorType? errorType;

  HomeState({
    this.goals = const [],
    this.studiedSecondsByGoalId = const {},
    this.isLoading = false,
    this.currentStreak = 0,
    this.recentStudyDates = const [],
    this.displayName = UserConsts.defaultGuestName,
    this.errorMessage,
    this.errorType,
  });

  HomeState copyWith({
    List<GoalsModel>? goals,
    Map<String, int>? studiedSecondsByGoalId,
    bool? isLoading,
    int? currentStreak,
    List<DateTime>? recentStudyDates,
    String? displayName,
    String? errorMessage,
    HomeErrorType? errorType,
    bool clearError = false,
  }) {
    return HomeState(
      goals: goals ?? this.goals,
      studiedSecondsByGoalId:
          studiedSecondsByGoalId ?? this.studiedSecondsByGoalId,
      isLoading: isLoading ?? this.isLoading,
      currentStreak: currentStreak ?? this.currentStreak,
      recentStudyDates: recentStudyDates ?? this.recentStudyDates,
      displayName: displayName ?? this.displayName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorType: clearError ? null : (errorType ?? this.errorType),
    );
  }

  /// エラーがあるかどうか
  bool get hasError => errorMessage != null;

  /// 目標の進捗率を計算（0.0〜1.0）
  /// totalTargetMinutesを使用して進捗率を計算
  double getProgressForGoal(GoalsModel goal) {
    final studiedMinutes = getStudiedMinutesForGoal(goal);
    final totalTargetMinutes = goal.totalTargetMinutes ?? 0;
    return TimeUtils.calculateProgressRateFromMinutes(
      totalTargetMinutes,
      studiedMinutes,
    );
  }

  /// 目標の学習済み時間（分）を取得
  int getStudiedMinutesForGoal(GoalsModel goal) {
    final studiedSeconds = studiedSecondsByGoalId[goal.id] ?? 0;
    return studiedSeconds ~/ TimeUtils.secondsPerMinute;
  }
}

// Home画面のViewModel
class HomeViewModel extends GetxController {
  late final GoalsRepository _goalsRepository;
  late final StudyLogsRepository _studyLogsRepository;
  late final UsersRepository _usersRepository;
  late final AuthService _authService;
  late final CrashlyticsService _crashlyticsService;

  // 状態（Rxを使わない）
  HomeState _state = HomeState();
  HomeState get state => _state;

  HomeViewModel({
    GoalsRepository? goalsRepository,
    StudyLogsRepository? studyLogsRepository,
    UsersRepository? usersRepository,
    AuthService? authService,
    CrashlyticsService? crashlyticsService,
  }) {
    _goalsRepository = goalsRepository ?? GoalsRepository();
    _studyLogsRepository = studyLogsRepository ?? StudyLogsRepository();
    _usersRepository = usersRepository ?? UsersRepository();
    _authService = authService ?? AuthService();
    _crashlyticsService = crashlyticsService ?? CrashlyticsService();
  }

  /// 現在のユーザーID（未ログイン時は空文字列）
  String get _userId => _authService.currentUserId ?? '';

  /// エラー状態をクリアする
  void clearError() {
    _state = state.copyWith(clearError: true);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    loadGoals();
  }

  // データベースから目標と学習ログをロード
  Future<void> loadGoals() async {
    try {
      _state = state.copyWith(isLoading: true);
      update();

      final userId = _userId;

      // 期限切れの目標を更新
      await _goalsRepository.updateExpiredGoals(userId);

      // 既存目標のtotalTargetMinutesを補完（Issue #111実装前に作成された目標対応）
      await _goalsRepository.populateMissingTotalTargetMinutes(userId);

      // 目標、学習時間、ストリークデータ、displayNameを並列で取得
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDate = today.subtract(
        const Duration(days: StreakConsts.recentDaysCount - 1),
      );

      final (
        goals,
        studiedSeconds,
        recentStudyDates,
        currentStreak,
        displayName,
      ) = await (
        _goalsRepository.fetchActiveGoals(userId),
        _studyLogsRepository.fetchTotalSecondsForAllGoals(userId),
        _studyLogsRepository.fetchStudyDatesInRange(
          startDate: startDate,
          endDate: today,
          userId: userId,
        ),
        _studyLogsRepository.calculateCurrentStreak(userId),
        _usersRepository.getDisplayName(userId),
      ).wait;

      AppLogger.instance.i('目標を${goals.length}件読み込みました');
      AppLogger.instance.i('学習時間データを${studiedSeconds.length}件読み込みました');
      AppLogger.instance.i(
        'ストリーク: $currentStreak日, 直近学習日: ${recentStudyDates.length}日',
      );
      AppLogger.instance.i('displayName: $displayName');

      _state = state.copyWith(
        goals: goals,
        studiedSecondsByGoalId: studiedSeconds,
        currentStreak: currentStreak,
        recentStudyDates: recentStudyDates,
        displayName: displayName,
        isLoading: false,
      );
      update();
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標の読み込みに失敗しました', error, stackTrace);
      _state = state.copyWith(isLoading: false);
      update();
    }
  }

  // 目標を追加
  Future<void> addGoal({
    required String title,
    required String description,
    required int targetMinutes,
    required String avoidMessage,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    final userId = _userId;

    // 残り日数と総目標時間を計算
    final remainingDays = TimeUtils.calculateRemainingDays(deadline);
    final totalTargetMinutes = TimeUtils.calculateTotalTargetMinutes(
      targetMinutes: targetMinutes,
      remainingDays: remainingDays,
    );

    final goal = GoalsModel(
      id: const Uuid().v4(),
      userId: userId.isEmpty ? null : userId,
      title: title,
      description: description.isEmpty ? null : description,
      targetMinutes: targetMinutes,
      totalTargetMinutes: totalTargetMinutes,
      avoidMessage: avoidMessage,
      deadline: deadline,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _goalsRepository.upsertGoal(goal);
      AppLogger.instance.i('目標を保存しました: ${goal.id}');

      // 状態を直接更新（パフォーマンス改善: DBからの再読み込みを回避）
      _state = state.copyWith(goals: [...state.goals, goal]);
      update();

      // デバッグ: 保存後に全目標を表示（デバッグビルドのみ）
      assert(() {
        debugPrintAllGoals();
        return true;
      }());
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標の保存に失敗しました', error, stackTrace);

      // Crashlyticsにデータ送信
      await _crashlyticsService.sendFailedGoalData(goal, error, stackTrace);

      // エラー状態を設定
      _state = state.copyWith(
        errorMessage: '保存に失敗しました。ネットワーク接続を確認してください。',
        errorType: HomeErrorType.save,
      );
      update();

      rethrow;
    }
  }

  // 目標を更新
  Future<void> updateGoal({
    required GoalsModel original,
    required String title,
    required String description,
    required int targetMinutes,
    required String avoidMessage,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();

    // 残り日数と総目標時間を再計算
    final remainingDays = TimeUtils.calculateRemainingDays(deadline);
    final totalTargetMinutes = TimeUtils.calculateTotalTargetMinutes(
      targetMinutes: targetMinutes,
      remainingDays: remainingDays,
    );

    final updatedGoal = original.copyWith(
      title: title,
      description: description.isEmpty ? null : description,
      targetMinutes: targetMinutes,
      totalTargetMinutes: totalTargetMinutes,
      avoidMessage: avoidMessage,
      deadline: deadline,
      updatedAt: now,
    );

    try {
      await _goalsRepository.updateGoal(updatedGoal);
      AppLogger.instance.i('目標を更新しました: ${updatedGoal.id}');

      // 状態を直接更新（パフォーマンス改善: DBからの再読み込みを回避）
      final updatedGoals =
          state.goals
              .map((g) => g.id == updatedGoal.id ? updatedGoal : g)
              .toList();
      _state = state.copyWith(goals: updatedGoals);
      update();
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標の更新に失敗しました', error, stackTrace);

      // Crashlyticsにデータ送信
      await _crashlyticsService.sendFailedGoalData(updatedGoal, error, stackTrace);

      // エラー状態を設定
      _state = state.copyWith(
        errorMessage: '更新に失敗しました。ネットワーク接続を確認してください。',
        errorType: HomeErrorType.update,
      );
      update();

      rethrow;
    }
  }

  /// 目標削除を実行し、結果を返す（View層から呼び出すためのメソッド）
  /// MVVMパターンに従い、ビジネスロジックをViewModelに集約
  Future<DeleteGoalResult> onDeleteGoalConfirmed(GoalsModel goal) async {
    try {
      await _deleteGoalInternal(goal);
      return DeleteGoalResult.success;
    } catch (_) {
      // エラーは_deleteGoalInternal内でログ記録・エラー状態設定済み
      return DeleteGoalResult.failure;
    }
  }

  // 目標を削除（学習ログは保持）- 内部実装
  // ストリーク計算のため、削除された目標の学習記録も保持する
  Future<void> _deleteGoalInternal(GoalsModel goal) async {
    try {
      // 目標のみ削除（学習ログは保持してストリーク計算に使用）
      await _goalsRepository.deleteGoal(goal.id);
      AppLogger.instance.i('目標を削除しました（学習ログは保持）: ${goal.id}');

      // 状態を直接更新（パフォーマンス改善: DBからの再読み込みを回避）
      final updatedGoals = state.goals.where((g) => g.id != goal.id).toList();
      _state = state.copyWith(goals: updatedGoals);
      update();

      // デバッグ: 削除後に全目標を表示（デバッグビルドのみ）
      assert(() {
        debugPrintAllGoals();
        return true;
      }());
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標の削除に失敗しました', error, stackTrace);

      // Crashlyticsに送信
      await _crashlyticsService.sendFailedGoalDelete(goal.id, error, stackTrace);

      // エラー状態を設定
      _state = state.copyWith(
        errorMessage: '削除に失敗しました。ネットワーク接続を確認してください。',
        errorType: HomeErrorType.delete,
      );
      update();

      rethrow;
    }
  }

  // 目標リストを再読み込み
  void reloadGoals() {
    loadGoals();
  }

  /// displayNameを再読み込み
  /// 設定画面から戻ったときに呼び出す
  Future<void> refreshDisplayName() async {
    try {
      final displayName = await _usersRepository.getDisplayName(_userId);
      _state = state.copyWith(displayName: displayName);
      update();
      AppLogger.instance.i('displayNameを再読み込みしました: $displayName');
    } catch (error, stackTrace) {
      AppLogger.instance.e('displayNameの再読み込みに失敗しました', error, stackTrace);
    }
  }

  // フィルタリングされた目標リストを取得
  List<GoalsModel> get filteredGoals => state.goals;

  /// デバッグ用: 保存されている目標を全件取得して表示
  Future<void> debugPrintAllGoals() async {
    try {
      final goals = await _goalsRepository.fetchAllGoals(_userId);
      AppLogger.instance.i('=== 保存されている目標一覧 (${goals.length}件) ===');

      if (goals.isEmpty) {
        AppLogger.instance.i('目標が1件も保存されていません');
      } else {
        for (var goal in goals) {
          AppLogger.instance.i(
            'ID: ${goal.id.substring(0, 8)}..., '
            'Title: ${goal.title}, '
            'Target: ${goal.targetMinutes}分, '
            'Deadline: ${goal.deadline.toString().substring(0, 10)}, '
            'Synced: ${goal.syncUpdatedAt != null ? "✓" : "✗"}',
          );
        }
      }

      AppLogger.instance.i('====================================');
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標取得失敗', error, stackTrace);
    }
  }
}
