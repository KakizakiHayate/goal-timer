import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/repositories/goal_detail_repository.dart';

// 目標詳細の取得ユースケース
class GetGoalDetailsUseCase {
  final GoalDetailRepository repository;

  GetGoalDetailsUseCase(this.repository);

  // 全ての目標詳細を取得する
  Future<List<GoalsModel>> execute() async {
    return await repository.getAllGoalDetails();
  }
}
