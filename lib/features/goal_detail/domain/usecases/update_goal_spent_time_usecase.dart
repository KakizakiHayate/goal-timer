import 'package:goal_timer/features/goal_detail/domain/repositories/goal_detail_repository.dart';

// 目標に費やした時間更新ユースケース
class UpdateGoalSpentTimeUseCase {
  final GoalDetailRepository repository;

  UpdateGoalSpentTimeUseCase(this.repository);

  // 指定されたIDの目標に費やした時間を更新する
  Future<void> execute(String id, int additionalMinutes) async {
    await repository.updateGoalSpentTime(id, additionalMinutes);
  }
}
