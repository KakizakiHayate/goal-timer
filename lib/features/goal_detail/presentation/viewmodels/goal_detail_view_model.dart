import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/provider/supabase/goals/goals_provider.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

// 目標詳細リストプロバイダー - Supabaseのデータを使用
final goalDetailListProvider = FutureProvider<List<GoalsModel>>((ref) async {
  final goalsAsync = ref.watch(goalsListProvider);
  return goalsAsync.when(
    data: (goals) => goals,
    error: (_, __) => [],
    loading: () => [],
  );
});

// 特定目標詳細プロバイダー - Supabaseのデータを使用
final goalDetailProvider = FutureProvider.family<GoalsModel?, String>((
  ref,
  id,
) async {
  final goalAsync = ref.watch(goalByIdProvider(id));
  return goalAsync.when(
    data: (goal) => goal,
    error: (_, __) => null,
    loading: () => null,
  );
});

// 目標時間更新関数プロバイダー
final updateGoalSpentTimeProvider =
    Provider<Future<void> Function(String, int)>((ref) {
      final goalsNotifier = ref.watch(goalsNotifierProvider.notifier);

      return (String id, int additionalMinutes) async {
        try {
          // 現在の目標を取得
          final goalAsync = await ref.read(goalByIdProvider(id).future);
          if (goalAsync == null) {
            throw Exception('目標が見つかりませんでした');
          }

          // 学習時間を追加して更新
          final newSpentMinutes = goalAsync.spentMinutes + additionalMinutes;
          final updatedGoal = goalAsync.copyWith(spentMinutes: newSpentMinutes);

          await goalsNotifier.updateGoal(updatedGoal);
        } catch (e) {
          AppLogger.instance.e('目標の学習時間更新に失敗しました: $e');
          rethrow;
        }
      };
    });

// 目標詳細ビューモデルプロバイダー
final goalDetailViewModelProvider =
    StateNotifierProvider<GoalDetailViewModel, void>((ref) {
      return GoalDetailViewModel(ref);
    });

// 目標詳細を操作するビューモデル
class GoalDetailViewModel extends StateNotifier<void> {
  final Ref _ref;

  GoalDetailViewModel(this._ref) : super(null);

  // 目標の学習時間を追加する
  Future<void> addStudyTime(String goalId, int minutes) async {
    try {
      // 学習時間の更新
      final updateSpentTime = _ref.read(updateGoalSpentTimeProvider);
      await updateSpentTime(goalId, minutes);

      // 更新後に目標詳細を再取得するためにキャッシュを無効化
      _ref.invalidate(goalByIdProvider(goalId));
      _ref.invalidate(goalsListProvider);
      _ref.invalidate(goalDetailProvider(goalId));
      _ref.invalidate(goalDetailListProvider);
    } catch (e) {
      // エラー処理
      AppLogger.instance.e('目標の学習時間更新に失敗しました: $e');
    }
  }
}
