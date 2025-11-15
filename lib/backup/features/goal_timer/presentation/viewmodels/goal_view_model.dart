import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/backup/features/goal_timer/data/repositories/goal_repository_impl.dart';
import 'package:goal_timer/backup/features/goal_timer/domain/entities/goal.dart';
import 'package:goal_timer/backup/features/goal_timer/domain/usecases/get_goals_usecase.dart';

// リポジトリのプロバイダー
final goalRepositoryProvider = Provider((ref) => GoalRepositoryImpl());

// ユースケースのプロバイダー
final getGoalsUseCaseProvider = Provider((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GetGoalsUseCase(repository);
});

// ゴール一覧を提供するプロバイダー
final goalListProvider = FutureProvider<List<Goal>>((ref) async {
  final useCase = ref.watch(getGoalsUseCaseProvider);
  return await useCase.execute();
});
