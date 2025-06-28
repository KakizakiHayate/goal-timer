import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class HomeState {
  final List<GoalsModel> goals;
  final String filterType;
  final bool isLoading;
  final bool isSyncing;
  final SyncStatus syncStatus;

  HomeState({
    this.goals = const [],
    this.filterType = '全て',
    this.isLoading = false,
    this.isSyncing = false,
    this.syncStatus = SyncStatus.synced,
  });

  HomeState copyWith({
    List<GoalsModel>? goals,
    String? filterType,
    bool? isLoading,
    bool? isSyncing,
    SyncStatus? syncStatus,
  }) {
    return HomeState(
      goals: goals ?? this.goals,
      filterType: filterType ?? this.filterType,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  final Ref _ref;

  HomeViewModel(this._ref) : super(HomeState()) {
    // 初期データの読み込み
    _loadGoals();
    // 同期状態の監視
    _listenToSyncState();
  }

  // 目標データの読み込み（ローカル優先）
  void _loadGoals() async {
    state = state.copyWith(isLoading: true);

    try {
      // UseCaseを通じて目標データを取得（クリーンアーキテクチャに準拠）
      final goals = await _ref.read(fetchGoalsUseCaseProvider).call();

      state = state.copyWith(goals: goals, isLoading: false);

      AppLogger.instance.i('ホーム画面に${goals.length}件の目標を表示しました');
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

      // 同期完了時にデータを再読み込み
      if (previous?.status == SyncStatus.syncing &&
          next.status == SyncStatus.synced) {
        AppLogger.instance.i('同期完了 - データを再読み込みします');
        _reloadGoalsAfterSync();
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
    } catch (e) {
      AppLogger.instance.e('同期後のデータ再読み込みに失敗しました', e);
    }
  }

  // 外部から呼び出せる目標データのリロードメソッド
  void reloadGoals() {
    _loadGoals();
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

  // フィルター済みの目標リストを取得
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

  // 同期状態の取得
  bool get isSyncing => state.isSyncing;
  SyncStatus get syncStatus => state.syncStatus;
}
