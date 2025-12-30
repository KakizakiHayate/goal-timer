import 'package:goal_timer/backup/core/models/goals/goals_model.dart';

/// 目標データのリポジトリインターフェース
abstract class SupabaseGoalsRepository {
  /// すべての目標を取得
  Future<List<GoalsModel>> getGoals();

  /// 特定のIDの目標を取得
  Future<GoalsModel?> getGoalById(String id);

  /// 新しい目標を作成
  Future<GoalsModel> createGoal(GoalsModel goal);

  /// 既存の目標を更新
  Future<GoalsModel> updateGoal(GoalsModel goal);

  /// 目標を削除
  Future<void> deleteGoal(String id);
}
