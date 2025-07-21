import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

// 目標詳細リストプロバイダー - HybridRepositoryのデータを使用
final goalDetailListProvider = FutureProvider<List<GoalsModel>>((ref) async {
  try {
    // HybridGoalsRepositoryを使用してローカル優先でデータを取得
    final fetchGoalsUseCase = ref.watch(fetchGoalsUseCaseProvider);
    final goals = await fetchGoalsUseCase.call();
    return goals;
  } catch (e) {
    AppLogger.instance.e('目標リスト取得に失敗しました', e);
    return [];
  }
});

// 特定目標詳細プロバイダー - 一時的にコメントアウト（HybridRepository版のプロバイダーが必要）
/*
final goalDetailProvider = FutureProvider.family<GoalsModel?, String>((
  ref,
  id,
) async {
  // TODO: HybridRepository版の個別目標取得プロバイダーを実装する必要がある
  return null;
});
*/

// 目標時間更新関数プロバイダー - 一時的にコメントアウト（HybridRepository対応が必要）
/*
final updateGoalSpentTimeProvider =
    Provider<Future<void> Function(String, int)>((ref) {
      // TODO: HybridRepository版のupdateGoalUseCaseProviderを使用する必要がある
      return (String id, int additionalMinutes) async {
        // 実装は後で追加
      };
    });
*/

// 目標詳細ビューモデルプロバイダー - 一時的にコメントアウト
/*
final goalDetailViewModelProvider =
    StateNotifierProvider<GoalDetailViewModel, void>((ref) {
      return GoalDetailViewModel(ref);
    });

// 目標詳細を操作するビューモデル - 一時的にコメントアウト
class GoalDetailViewModel extends StateNotifier<void> {
  final Ref _ref;

  GoalDetailViewModel(this._ref) : super(null);

  // 目標の学習時間を追加する
  Future<void> addStudyTime(String goalId, int minutes) async {
    try {
      // TODO: HybridRepository対応の実装が必要
      AppLogger.instance.i('学習時間追加機能は一時的に無効化されています');
    } catch (e) {
      // エラー処理
      AppLogger.instance.e('目標の学習時間更新に失敗しました: $e');
    }
  }
}
*/
