import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/features/goal_detail_setting/data/repositories/goal_detail_repository_impl.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/repositories/goal_detail_repository.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/usecases/get_goal_details_usecase.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/usecases/get_goal_detail_usecase.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/usecases/update_goal_progress_usecase.dart';
import 'package:goal_timer/features/goal_detail_setting/domain/usecases/update_goal_spent_time_usecase.dart';

// リポジトリプロバイダー
final goalDetailRepositoryProvider = Provider<GoalDetailRepository>((ref) {
  return GoalDetailRepositoryImpl();
});

// 全目標詳細取得ユースケースプロバイダー
final getGoalDetailsUseCaseProvider = Provider<GetGoalDetailsUseCase>((ref) {
  final repository = ref.watch(goalDetailRepositoryProvider);
  return GetGoalDetailsUseCase(repository);
});

// 特定目標詳細取得ユースケースプロバイダー
final getGoalDetailUseCaseProvider = Provider<GetGoalDetailUseCase>((ref) {
  final repository = ref.watch(goalDetailRepositoryProvider);
  return GetGoalDetailUseCase(repository);
});

// 目標進捗更新ユースケースプロバイダー
final updateGoalProgressUseCaseProvider = Provider<UpdateGoalProgressUseCase>((
  ref,
) {
  final repository = ref.watch(goalDetailRepositoryProvider);
  return UpdateGoalProgressUseCase(repository);
});

// 目標費やし時間更新ユースケースプロバイダー
final updateGoalSpentTimeUseCaseProvider = Provider<UpdateGoalSpentTimeUseCase>(
  (ref) {
    final repository = ref.watch(goalDetailRepositoryProvider);
    return UpdateGoalSpentTimeUseCase(repository);
  },
);

// 目標詳細リストプロバイダー
final goalDetailListProvider = FutureProvider<List<GoalsModel>>((ref) async {
  final useCase = ref.watch(getGoalDetailsUseCaseProvider);
  return await useCase.execute();
});

// 特定目標詳細プロバイダー
final goalDetailProvider = FutureProvider.family<GoalsModel?, String>((
  ref,
  id,
) async {
  final useCase = ref.watch(getGoalDetailUseCaseProvider);
  return await useCase.execute(id);
});

// 目標進捗更新関数プロバイダー
final updateGoalProgressProvider =
    Provider<Future<void> Function(String, double)>((ref) {
      final useCase = ref.watch(updateGoalProgressUseCaseProvider);
      return (String id, double progressPercent) =>
          useCase.execute(id, progressPercent);
    });

// 目標時間更新関数プロバイダー
final updateGoalSpentTimeProvider =
    Provider<Future<void> Function(String, int)>((ref) {
      final useCase = ref.watch(updateGoalSpentTimeUseCaseProvider);
      return (String id, int additionalMinutes) =>
          useCase.execute(id, additionalMinutes);
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
      _ref.invalidate(goalDetailProvider(goalId));
      _ref.invalidate(goalDetailListProvider);
    } catch (e) {
      // エラー処理
      print('目標の学習時間更新に失敗しました: $e');
    }
  }
}
