import 'package:goal_timer/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

/// 目標削除のユースケース
/// クリーンアーキテクチャに従い、ViewModelとRepositoryの間の橋渡しを行う
class DeleteGoalUseCase {
  final GoalsRepository _repository;

  DeleteGoalUseCase(this._repository);

  /// 目標を削除する
  Future<void> call({
    required String goalId,
    required String goalTitle,
  }) async {
    try {
      AppLogger.instance.i('目標の削除を開始します: $goalTitle (ID: $goalId)');

      // バリデーション
      if (goalId.trim().isEmpty) {
        throw ArgumentError('目標IDが指定されていません');
      }

      // リポジトリ経由でデータベースから削除
      await _repository.deleteGoal(goalId);
      
      AppLogger.instance.i('目標の削除が完了しました: $goalTitle');
    } catch (e) {
      AppLogger.instance.e('目標の削除に失敗しました: $goalTitle', e);
      rethrow;
    }
  }
}