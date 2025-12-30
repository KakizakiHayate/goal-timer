import 'package:goal_timer/backup/core/data/repositories/hybrid/goals/hybrid_goals_repository.dart';
import 'package:goal_timer/backup/core/utils/app_logger.dart';

/// 目標データ同期のユースケース
/// 手動同期や強制全件同期などの同期関連操作を提供
class SyncGoalsUseCase {
  final HybridGoalsRepository _repository;

  SyncGoalsUseCase(this._repository);

  /// リモートとの同期を実行する（差分同期）
  Future<void> syncWithRemote() async {
    try {
      AppLogger.instance.i('目標データの同期を開始します');
      await _repository.syncWithRemote();
      AppLogger.instance.i('目標データの同期が完了しました');
    } catch (e) {
      AppLogger.instance.e('目標データの同期に失敗しました', e);
      rethrow;
    }
  }

  /// 強制的に全件同期を実行する
  Future<void> forceFullSync() async {
    try {
      AppLogger.instance.i('目標データの強制全件同期を開始します');
      await _repository.forceFullSync();
      AppLogger.instance.i('目標データの強制全件同期が完了しました');
    } catch (e) {
      AppLogger.instance.e('目標データの強制全件同期に失敗しました', e);
      rethrow;
    }
  }
}
