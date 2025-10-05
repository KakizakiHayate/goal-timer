import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/models/study_statistics.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';
import 'package:goal_timer/core/services/study_statistics_service.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:goal_timer/features/auth/domain/entities/auth_state.dart'
    as app_auth;

class HomeState {
  final List<GoalsModel> goals;
  final String filterType;
  final bool isLoading;
  final bool isSyncing;
  final SyncStatus syncStatus;
  final StudyStatistics statistics;
  final bool isStatisticsLoading;
  final Map<String, int> goalStreaks;

  HomeState({
    this.goals = const [],
    this.filterType = '全て',
    this.isLoading = false,
    this.isSyncing = false,
    this.syncStatus = SyncStatus.synced,
    StudyStatistics? statistics,
    this.isStatisticsLoading = false,
    this.goalStreaks = const {},
  }) : statistics = statistics ?? StudyStatistics.empty();

  HomeState copyWith({
    List<GoalsModel>? goals,
    String? filterType,
    bool? isLoading,
    bool? isSyncing,
    SyncStatus? syncStatus,
    StudyStatistics? statistics,
    bool? isStatisticsLoading,
    Map<String, int>? goalStreaks,
  }) {
    return HomeState(
      goals: goals ?? this.goals,
      filterType: filterType ?? this.filterType,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      syncStatus: syncStatus ?? this.syncStatus,
      statistics: statistics ?? this.statistics,
      isStatisticsLoading: isStatisticsLoading ?? this.isStatisticsLoading,
      goalStreaks: goalStreaks ?? this.goalStreaks,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref _ref;
  final StudyStatisticsService _statisticsService;

  HomeViewModel(this._ref, this._statisticsService) : super(HomeState()) {
    // 初期データの読み込み
    _loadGoals();
    _loadStatistics();
    // 同期状態の監視
    _listenToSyncState();
    // アプリ起動時の同期チェック実行
    _performStartupSyncCheck();
  }

  /// アプリ起動時の同期チェック（認証済みユーザー用）
  void _performStartupSyncCheck() async {
    try {
      AppLogger.instance.i('ホーム画面初期化時の同期チェックを開始します');

      // 認証状態を確認
      final authState = _ref.read(globalAuthStateProvider);
      if (authState == app_auth.AuthState.authenticated) {
        // SyncCheckerを通じて同期チェック実行
        final syncChecker = _ref.read(syncCheckerProvider);
        await syncChecker.checkAndSyncIfNeeded();
        AppLogger.instance.i('ホーム画面初期化時の同期チェックが完了しました');
      } else {
        AppLogger.instance.i('未認証のためホーム画面での同期チェックをスキップします');
      }
    } catch (e) {
      AppLogger.instance.e('ホーム画面初期化時の同期チェックでエラーが発生しました', e);
      // エラーでもアプリの動作を止めない
    }
  }

  // 目標データの読み込み（ローカル優先）
  void _loadGoals() async {
    state = state.copyWith(isLoading: true);

    try {
      // UseCaseを通じて目標データを取得（クリーンアーキテクチャに準拠）
      final goals = await _ref.read(fetchGoalsUseCaseProvider).call();

      state = state.copyWith(goals: goals, isLoading: false);

      AppLogger.instance.i('ホーム画面に${goals.length}件の目標を表示しました');

      // ストリーク情報も読み込む
      _loadGoalStreaks();
    } catch (e) {
      AppLogger.instance.e('目標データの読み込みに失敗しました', e);
      state = state.copyWith(isLoading: false);
    }
  }

  // 同期状態の監視
  void _listenToSyncState() {
    _ref.listen<SyncState>(syncStateProvider, (previous, next) {
      state = state.copyWith(
        isSyncing: next.status == SyncStatus.syncing,
        syncStatus: next.status,
      );

      // 同期完了時にデータを再読み込み（SyncCheckerからの通知のみ処理）
      if (previous?.status == SyncStatus.syncing &&
          next.status == SyncStatus.synced) {
        AppLogger.instance.i('真の同期完了 - データを再読み込みします');
        _reloadGoalsAfterSync();
        _loadStatistics(); // 統計も再読み込み
      }
    });
  }

  // 同期後のデータ再読み込み
  void _reloadGoalsAfterSync() async {
    try {
      // 同期後の再読み込みでは同期を避けるため、直接ローカルから取得
      final repository = _ref.read(goalsRepositoryProvider);

      // ローカルデータのみを取得（同期処理をスキップ）
      final goals = await repository.getLocalGoalsOnly();

      state = state.copyWith(goals: goals);
      AppLogger.instance.i('同期後のデータ再読み込みが完了しました: ${goals.length}件');

      // ストリーク情報も再読み込み
      _loadGoalStreaks();
    } catch (e) {
      AppLogger.instance.e('同期後のデータ再読み込みに失敗しました', e);
    }
  }

  // 外部から呼び出せる目標データのリロードメソッド
  void reloadGoals() {
    _loadGoals();
    _loadStatistics(); // 統計も更新
  }

  // 手動同期の実行
  void performSync() async {
    try {
      // UseCaseを通じて同期処理を実行（クリーンアーキテクチャに準拠）
      await _ref.read(syncGoalsUseCaseProvider).syncWithRemote();
      AppLogger.instance.i('手動同期を実行しました');
    } catch (e) {
      AppLogger.instance.e('手動同期に失敗しました', e);
    }
  }

  // 強制全件同期の実行（デバッグ用）
  void performForceSync() async {
    try {
      // UseCaseを通じて強制全件同期を実行（クリーンアーキテクチャに準拠）
      await _ref.read(syncGoalsUseCaseProvider).forceFullSync();
      AppLogger.instance.i('強制全件同期を実行しました');
    } catch (e) {
      AppLogger.instance.e('強制全件同期に失敗しました', e);
    }
  }

  // フィルター変更処理
  void changeFilter(String filterType) {
    state = state.copyWith(filterType: filterType);
    AppLogger.instance.i('フィルターを変更しました: $filterType');
  }

  // 進行中の目標のみを表示するためフィルタリングをする
  List<GoalsModel> get filteredGoals {
    if (state.filterType == '全て') {
      return state.goals;
    } else if (state.filterType == '進行中') {
      return state.goals.where((goal) => goal.getProgressRate() < 1.0).toList();
    } else {
      return state.goals
          .where((goal) => goal.getProgressRate() >= 1.0)
          .toList();
    }
  }

  // 統計データの読み込み
  void _loadStatistics() async {
    state = state.copyWith(isStatisticsLoading: true);

    try {
      final statistics = await _statisticsService.getCurrentUserStatistics();

      state = state.copyWith(
        statistics: statistics,
        isStatisticsLoading: false,
      );

      AppLogger.instance.i('統計データを更新しました');
    } catch (e) {
      AppLogger.instance.e('統計データの読み込みに失敗しました', e);
      state = state.copyWith(
        statistics: StudyStatistics.empty(),
        isStatisticsLoading: false,
      );
    }
  }

  // 統計データのリロード
  void reloadStatistics() {
    _loadStatistics();
  }

  // 目標のストリーク情報を一括読み込み
  void _loadGoalStreaks() async {
    try {
      final streaks = <String, int>{};
      for (final goal in state.goals) {
        final streak = await _statisticsService.getGoalStreak(goal.id);
        streaks[goal.id] = streak;
      }
      state = state.copyWith(goalStreaks: streaks);
      AppLogger.instance.d('${streaks.length}件のストリーク情報を読み込みました');
    } catch (e) {
      AppLogger.instance.e('ストリーク情報の読み込みに失敗しました', e);
    }
  }

  // キャッシュから特定の目標のストリーク日数を取得
  int? getGoalStreakFromCache(String goalId) {
    return state.goalStreaks[goalId];
  }

  // 特定の目標のストリーク日数を取得（後方互換性のため残す）
  Future<int> getGoalStreak(String goalId) async {
    try {
      return await _statisticsService.getGoalStreak(goalId);
    } catch (e) {
      AppLogger.instance.e('目標ストリーク取得に失敗しました: $goalId', e);
      return 0;
    }
  }

  // 同期状態の取得
  bool get isSyncing => state.isSyncing;
  SyncStatus get syncStatus => state.syncStatus;

  // 統計データの取得
  StudyStatistics get statistics => state.statistics;
  bool get isStatisticsLoading => state.isStatisticsLoading;
}
