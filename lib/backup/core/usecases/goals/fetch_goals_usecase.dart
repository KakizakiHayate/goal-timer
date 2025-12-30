import 'package:goal_timer/backup/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/backup/core/models/goals/goals_model.dart';
import 'package:goal_timer/backup/core/utils/app_logger.dart';

/// 目標データ取得のユースケース
/// クリーンアーキテクチャに従い、ViewModelとRepositoryの間の橋渡しを行う
class FetchGoalsUseCase {
  final GoalsRepository _repository;

  FetchGoalsUseCase(this._repository);

  /// 目標リストを取得する
  Future<List<GoalsModel>> call() async {
    try {
      AppLogger.instance.i('目標データの取得を開始します');
      final goals = await _repository.getGoals();
      AppLogger.instance.i('目標データの取得が完了しました: ${goals.length}件');
      return goals;
    } catch (e) {
      AppLogger.instance.e('目標データの取得に失敗しました', e);
      rethrow;
    }
  }
}
