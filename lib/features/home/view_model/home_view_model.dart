import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/goals/goals_model.dart';
import '../../../core/data/local/local_goals_datasource.dart';
import '../../../core/data/local/app_database.dart';
import '../../../core/utils/app_logger.dart';

/// 目標削除操作の結果
enum DeleteGoalResult {
  success,
  failure,
}

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
  late final LocalGoalsDatasource _goalsDatasource;

  // 状態（Rxを使わない）
  HomeState _state = HomeState();
  HomeState get state => _state;

  HomeViewModel({
    LocalGoalsDatasource? goalsDatasource,
  }) {
    final database = AppDatabase();
    _goalsDatasource = goalsDatasource ?? LocalGoalsDatasource(database: database);
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

      final goals = await _goalsDatasource.fetchAllGoals();
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

      await _goalsDatasource.saveGoal(goal);
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
    try {
      final now = DateTime.now();
      final updatedGoal = original.copyWith(
        title: title,
        description: description.isEmpty ? null : description,
        targetMinutes: targetMinutes,
        avoidMessage: avoidMessage,
        deadline: deadline,
        updatedAt: now,
      );

      await _goalsDatasource.updateGoal(updatedGoal);
      AppLogger.instance.i('目標を更新しました: ${updatedGoal.id}');

      // 状態を直接更新（パフォーマンス改善: DBからの再読み込みを回避）
      final updatedGoals = state.goals
          .map((g) => g.id == updatedGoal.id ? updatedGoal : g)
          .toList();
      _state = state.copyWith(goals: updatedGoals);
      update();
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標の更新に失敗しました', error, stackTrace);
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
      // エラーは_deleteGoalInternal内でログ記録済み
      return DeleteGoalResult.failure;
    }
  }

  // 目標を削除（学習ログも含めてカスケード削除）- 内部実装
  // トランザクションを使用してデータ整合性を保証
  Future<void> _deleteGoalInternal(GoalsModel goal) async {
    try {
      // トランザクションで学習ログと目標をアトミックに削除
      await _goalsDatasource.deleteGoalWithStudyLogs(goal.id);
      AppLogger.instance.i('目標と学習ログを削除しました: ${goal.id}');

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
      final goals = await _goalsDatasource.fetchAllGoals();
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
