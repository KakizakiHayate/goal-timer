import 'package:goal_timer/features/goal_detail_setting/domain/repositories/goal_detail_repository.dart';

// 目標進捗更新ユースケース
class UpdateGoalProgressUseCase {
  final GoalDetailRepository repository;

  UpdateGoalProgressUseCase(this.repository);

  // 指定されたIDの目標進捗を更新する
  Future<void> execute(String id, int spentMinutes) async {
    await repository.updateGoalProgress(id, spentMinutes);
  }
}
