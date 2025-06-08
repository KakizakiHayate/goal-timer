import 'package:goal_timer/core/data/datasources/supabase/goals/supabase_goals_datasource.dart';
import 'package:goal_timer/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';

/// Supabaseを使用した目標データのリポジトリ実装
class GoalsRepositoryImpl implements GoalsRepository {
  final SupabaseGoalsDatasource _datasource;

  GoalsRepositoryImpl(this._datasource);

  @override
  Future<List<GoalsModel>> getGoals() async {
    return await _datasource.getGoals();
  }

  @override
  Future<GoalsModel?> getGoalById(String id) async {
    return await _datasource.getGoalById(id);
  }

  @override
  Future<GoalsModel> createGoal(GoalsModel goal) async {
    return await _datasource.createGoal(goal);
  }

  @override
  Future<GoalsModel> updateGoal(GoalsModel goal) async {
    return await _datasource.updateGoal(goal);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _datasource.deleteGoal(id);
  }
}
