import 'package:goal_timer/features/goal_detail_setting/domain/entities/goal_detail.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/repositories/goal_detail_repository.dart';

// 特定の目標詳細取得ユースケース
class GetGoalDetailUseCase {
  final GoalDetailRepository repository;

  GetGoalDetailUseCase(this.repository);

  // 指定されたIDの目標詳細を取得する
  Future<GoalDetail?> execute(String id) async {
    return await repository.getGoalDetailById(id);
  }
}
