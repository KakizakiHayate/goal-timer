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
      final goalMap = goal.toMap();
      AppLogger.instance.i(
        '🚀 [SupabaseGoalsDatasource] CREATE: Supabase作成データ: $goalMap',
      );
      AppLogger.instance.i(
        '🚀 [SupabaseGoalsDatasource] CREATE: 作成対象ID: ${goal.id}',
      );

      final data =
          await _client.from(_tableName).insert(goalMap).select().single();

      AppLogger.instance.i(
        '✅ [SupabaseGoalsDatasource] CREATE: Supabase作成成功: $data',
      );
      return GoalsModel.fromMap(data);
    } catch (e) {
      AppLogger.instance.e(
        '❌ [SupabaseGoalsDatasource] CREATE: 目標の作成に失敗しました: ${goal.id}',
        e,
      );
      AppLogger.instance.e(
        '❌ [SupabaseGoalsDatasource] CREATE: 送信データ: ${goal.toMap()}',
      );
      AppLogger.instance.e(
        '❌ [SupabaseGoalsDatasource] CREATE: エラー詳細: ${e.toString()}',
      );
      AppLogger.instance.e(
        '❌ [SupabaseGoalsDatasource] CREATE: エラータイプ: ${e.runtimeType}',
      );
      rethrow;
    }
  }

  @override
  Future<GoalsModel> updateGoal(GoalsModel goal) async {
    try {
      final updateData = goal.toMap();
      AppLogger.instance.i(
        '🚀 [SupabaseGoalsDatasource] Supabase更新データ: $updateData',
      );
      AppLogger.instance.i('🚀 [SupabaseGoalsDatasource] 更新対象ID: ${goal.id}');

      final data =
          await _client
              .from(_tableName)
              .update(updateData)
              .eq('id', goal.id)
              .select()
              .single();

      AppLogger.instance.i('✅ [SupabaseGoalsDatasource] Supabase更新成功: $data');
      return GoalsModel.fromMap(data);
    } catch (e) {
      AppLogger.instance.e(
        '❌ [SupabaseGoalsDatasource] 目標の更新に失敗しました: ${goal.id}',
        e,
      );
      AppLogger.instance.e(
        '❌ [SupabaseGoalsDatasource] 送信データ: ${goal.toMap()}',
      );
      AppLogger.instance.e(
        '❌ [SupabaseGoalsDatasource] エラー詳細: ${e.toString()}',
      );
      AppLogger.instance.e(
        '❌ [SupabaseGoalsDatasource] エラータイプ: ${e.runtimeType}',
      );
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

  /// 指定した日時以降に同期更新された目標を取得（差分同期用）
  Future<List<GoalsModel>> getGoalsUpdatedAfter(DateTime lastSyncTime) async {
    try {
      final data = await _client
          .from(_tableName)
          .select()
          .gte('sync_updated_at', lastSyncTime.toIso8601String());
      return data.map((json) => GoalsModel.fromMap(json)).toList();
    } catch (e) {
      AppLogger.instance.e('差分目標データの取得に失敗しました', e);
      return [];
    }
  }

  /// リモートデータの最終同期更新時刻を取得
  Future<DateTime?> getLastModified() async {
    try {
      final data = await _client
          .from(_tableName)
          .select('sync_updated_at')
          .order('sync_updated_at', ascending: false)
          .limit(1);

      if (data.isNotEmpty) {
        final syncUpdatedAtStr = data.first['sync_updated_at'] as String;
        return DateTime.parse(syncUpdatedAtStr);
      }
      return null;
    } catch (e) {
      AppLogger.instance.e('リモート最終同期更新時刻の取得に失敗しました', e);
      return null;
    }
  }
}
