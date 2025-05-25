import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:goal_timer/core/data/repositories/supabase/goals/supabase_goals_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabaseを使用したGoalsRepositoryの実装
class SupabaseGoalsDatasource implements SupabaseGoalsRepository {
  final SupabaseClient _client;
  static const String _tableName = 'goals';

  SupabaseGoalsDatasource(this._client);

  @override
  Future<List<GoalsModel>> getGoals() async {
    try {
      final data = await _client.from(_tableName).select();
      return data.map((json) => GoalsModel.fromMap(json)).toList();
    } catch (e) {
      AppLogger.instance.e('目標データの取得に失敗しました', e);
      return [];
    }
  }

  @override
  Future<GoalsModel?> getGoalById(String id) async {
    try {
      final data =
          await _client.from(_tableName).select().eq('id', id).single();
      return GoalsModel.fromMap(data);
    } catch (e) {
      AppLogger.instance.e('目標データの取得に失敗しました: $id', e);
      return null;
    }
  }

  @override
  Future<GoalsModel> createGoal(GoalsModel goal) async {
    try {
      final data =
          await _client.from(_tableName).insert(goal.toMap()).select().single();
      return GoalsModel.fromMap(data);
    } catch (e) {
      AppLogger.instance.e('目標の作成に失敗しました', e);
      rethrow;
    }
  }

  @override
  Future<GoalsModel> updateGoal(GoalsModel goal) async {
    try {
      final data =
          await _client
              .from(_tableName)
              .update(goal.toMap())
              .eq('id', goal.id)
              .select()
              .single();
      return GoalsModel.fromMap(data);
    } catch (e) {
      AppLogger.instance.e('目標の更新に失敗しました: ${goal.id}', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
    } catch (e) {
      AppLogger.instance.e('目標の削除に失敗しました: $id', e);
      rethrow;
    }
  }
}
