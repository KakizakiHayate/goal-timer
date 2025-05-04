import 'package:goal_timer/features/goal_timer/data/repositories/goal_repository.dart';
import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';

// Clean Architectureのユースケース: ゴール一覧取得
class GetGoalsUseCase {
  final GoalRepository repository;

  GetGoalsUseCase(this.repository);

  // ゴール一覧を取得する
  Future<List<Goal>> execute() async {
    return await repository.getAllGoals();
  }
}
