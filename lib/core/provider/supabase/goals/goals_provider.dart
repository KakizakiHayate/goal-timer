import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/data/repositories/supabase/goals/supabase_goals_repository.dart';
import 'package:goal_timer/core/data/datasources/supabase/goals/supabase_goals_datasource.dart';
import 'package:goal_timer/core/usecases/supabase/goals/fetch_goals_usecase.dart';

// MARK: - Provider

final goalsRepositoryProvider = Provider<SupabaseGoalsDatasource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseGoalsDatasource(client);
});

final fetchGoalsUsecaseProvider = Provider<FetchGoalsUsecase>((ref) {
  return FetchGoalsUsecase();
});

// MARK: - FutureProvider

/// 全目標リストを取得するFutureProvider
final goalsListProvider = FutureProvider<List<GoalsModel>>((ref) async {
  final repository = ref.watch(goalsRepositoryProvider);
  return repository.getGoals();
});

/// 特定のIDの目標を取得するFutureProvider
final goalByIdProvider = FutureProvider.family<GoalsModel?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(goalsRepositoryProvider);
  return repository.getGoalById(id);
});

// MARK: - StateNotifierProvider

/// 目標操作用のStateNotifierProvider
final goalsNotifierProvider =
    StateNotifierProvider<GoalsNotifier, AsyncValue<List<GoalsModel>>>((ref) {
      final repository = ref.watch(goalsRepositoryProvider);
      return GoalsNotifier(repository);
    });

/// 目標データの操作を担当するStateNotifier
class GoalsNotifier extends StateNotifier<AsyncValue<List<GoalsModel>>> {
  final SupabaseGoalsRepository _repository;

  GoalsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  /// 全目標を読み込む
  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repository.getGoals();
      state = AsyncValue.data(goals);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 新しい目標を作成
  Future<void> createGoal(GoalsModel goal) async {
    try {
      await _repository.createGoal(goal);
      loadGoals(); // 目標リストを再読み込み
    } catch (e) {
      // エラー処理
      rethrow;
    }
  }

  /// 目標を更新
  Future<void> updateGoal(GoalsModel goal) async {
    try {
      await _repository.updateGoal(goal);
      loadGoals(); // 目標リストを再読み込み
    } catch (e) {
      // エラー処理
      rethrow;
    }
  }

  /// 目標を削除
  Future<void> deleteGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      loadGoals(); // 目標リストを再読み込み
    } catch (e) {
      // エラー処理
      rethrow;
    }
  }
}
