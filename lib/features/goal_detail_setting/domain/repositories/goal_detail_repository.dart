import 'package:goal_timer/core/models/goals/goals_model.dart';

// 目標詳細のリポジトリインターフェース
abstract class GoalDetailRepository {
  // すべての目標詳細を取得
  Future<List<GoalsModel>> getAllGoalDetails();

  // 特定の目標詳細を取得
  Future<GoalsModel?> getGoalDetailById(String id);

  // 新しい目標詳細を追加
  Future<GoalsModel> addGoalDetail(GoalsModel goalDetail);

  // 目標詳細を更新
  Future<GoalsModel> updateGoalDetail(GoalsModel goalDetail);

  // 目標詳細を削除
  Future<void> deleteGoalDetail(String id);

  // 目標の進捗を更新
  Future<GoalsModel> updateGoalProgress(String id, double progressPercent);

  // 目標の費やした時間を更新
  Future<GoalsModel> updateGoalSpentTime(String id, int additionalMinutes);
}
