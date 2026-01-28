import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/goals/goals_model.dart';
import '../../utils/app_logger.dart';

/// Supabase goalsテーブルを操作するDataSource
class SupabaseGoalsDatasource {
  final SupabaseClient _supabase;

  static const String _tableName = 'goals';

  SupabaseGoalsDatasource({required SupabaseClient supabase})
      : _supabase = supabase;

  /// ユーザーの全ての目標を取得（削除済みを除く）
  Future<List<GoalsModel>> fetchAllGoals(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GoalsModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標取得に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// ユーザーの全ての目標を取得（削除済みを含む）
  Future<List<GoalsModel>> fetchAllGoalsIncludingDeleted(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GoalsModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標取得（削除済み含む）に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 特定の目標を取得
  ///
  /// [goalId] 目標ID
  /// [userId] ユーザーID（IDOR防止のため、自身の目標のみ取得可能）
  Future<GoalsModel?> fetchGoalById(String goalId, String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', goalId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return GoalsModel.fromJson(response);
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標取得に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 目標を作成または更新
  Future<GoalsModel> upsertGoal(GoalsModel goal) async {
    try {
      final now = DateTime.now();
      final goalToUpsert = goal.copyWith(
        updatedAt: now,
        syncUpdatedAt: now,
      );

      final response = await _supabase
          .from(_tableName)
          .upsert(goalToUpsert.toJson())
          .select()
          .single();

      AppLogger.instance.i('目標をupsertしました: ${goal.id}');
      return GoalsModel.fromJson(response);
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標upsertに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 複数の目標を一括で挿入
  /// null値はDBのDEFAULT値を使用するため除外する
  Future<void> insertGoals(List<GoalsModel> goals) async {
    if (goals.isEmpty) return;

    try {
      final now = DateTime.now();
      final goalsToInsert = goals.map((goal) {
        final json = goal.copyWith(
          updatedAt: now,
          syncUpdatedAt: now,
        ).toJson();
        // null値を除外してDBのDEFAULT値を使用させる
        json.removeWhere((key, value) => value == null);
        return json;
      }).toList();

      await _supabase.from(_tableName).upsert(goalsToInsert);

      AppLogger.instance.i('${goals.length}件の目標を一括upsertしました');
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標一括upsertに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 目標を論理削除
  Future<void> deleteGoal(String goalId) async {
    try {
      final now = DateTime.now();
      await _supabase.from(_tableName).update({
        'deleted_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_updated_at': now.toIso8601String(),
      }).eq('id', goalId);

      AppLogger.instance.i('目標を削除しました: $goalId');
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標削除に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 目標を物理削除
  Future<void> hardDeleteGoal(String goalId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', goalId);

      AppLogger.instance.i('目標を物理削除しました: $goalId');
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標物理削除に失敗しました', error, stackTrace);
      rethrow;
    }
  }
}
