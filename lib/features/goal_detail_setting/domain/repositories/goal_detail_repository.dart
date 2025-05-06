import 'package:goal_timer/features/goal_detail_setting/domain/entities/goal_detail.dart';

// 目標詳細のリポジトリインターフェース
abstract class GoalDetailRepository {
  // すべての目標詳細を取得
  Future<List<GoalDetail>> getAllGoalDetails();

  // 特定の目標詳細を取得
  Future<GoalDetail?> getGoalDetailById(String id);

  // 新しい目標詳細を追加
  Future<GoalDetail> addGoalDetail(GoalDetail goalDetail);

  // 目標詳細を更新
  Future<GoalDetail> updateGoalDetail(GoalDetail goalDetail);

  // 目標詳細を削除
  Future<void> deleteGoalDetail(String id);

  // 目標の進捗を更新
  Future<GoalDetail> updateGoalProgress(String id, double progressPercent);

  // 目標の費やした時間を更新
  Future<GoalDetail> updateGoalSpentTime(String id, int additionalMinutes);
}
