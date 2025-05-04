import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';

// ゴールリポジトリのインターフェース
abstract class GoalRepository {
  // すべてのゴールを取得
  Future<List<Goal>> getAllGoals();

  // 特定のゴールを取得
  Future<Goal?> getGoalById(String id);

  // 新しいゴールを追加
  Future<Goal> addGoal(Goal goal);

  // ゴールを更新
  Future<Goal> updateGoal(Goal goal);

  // ゴールを削除
  Future<void> deleteGoal(String id);
}
