import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/goals/goals_model.dart';
import '../../../core/data/local/local_goals_datasource.dart';
import '../../../core/data/local/app_database.dart';
import '../../../core/utils/app_logger.dart';

// Home画面の状態
class HomeState {
  final List<GoalsModel> goals;
  final bool isLoading;

  HomeState({
    this.goals = const [],
    this.isLoading = false,
  });

  HomeState copyWith({
    List<GoalsModel>? goals,
    bool? isLoading,
  }) {
    return HomeState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Home画面のViewModel
class HomeViewModel extends GetxController {
  late final LocalGoalsDatasource _datasource;

  // 状態（Rxを使わない）
  HomeState _state = HomeState();
  HomeState get state => _state;

  HomeViewModel() {
    _datasource = LocalGoalsDatasource(database: AppDatabase());
  }

  @override
  void onInit() {
    super.onInit();
    loadGoals();
  }

  // ローカルデータベースから目標をロード
  Future<void> loadGoals() async {
    try {
      _state = state.copyWith(isLoading: true);
      update();

      final goals = await _datasource.fetchAllGoals();
      AppLogger.instance.i('目標を${goals.length}件読み込みました');

      _state = state.copyWith(
        goals: goals,
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
    try {
      final now = DateTime.now();
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: null,
        title: title,
        description: description.isEmpty ? null : description,
        targetMinutes: targetMinutes,
        avoidMessage: avoidMessage,
        deadline: deadline,
        createdAt: now,
        updatedAt: now,
      );

      await _datasource.saveGoal(goal, isSynced: false);
      AppLogger.instance.i('目標を保存しました: ${goal.id}');

      // 目標リストを再読み込み
      await loadGoals();

      // デバッグ: 保存後に全目標を表示
      await debugPrintAllGoals();
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標の保存に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  // 目標リストを再読み込み
  void reloadGoals() {
    loadGoals();
  }

  // フィルタリングされた目標リストを取得
  List<GoalsModel> get filteredGoals => state.goals;

  /// デバッグ用: 保存されている目標を全件取得して表示
  Future<void> debugPrintAllGoals() async {
    try {
      final goals = await _datasource.fetchAllGoals();
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
