import 'package:goal_timer/backup/core/models/daily_study_logs/daily_study_log_model.dart';
import 'package:goal_timer/backup/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseDailyStudyLogsDatasource {
  static const String _tableName = 'study_daily_logs';
  final SupabaseClient _client;

  SupabaseDailyStudyLogsDatasource(this._client);

  // 全学習記録を取得
  Future<List<DailyStudyLogModel>> getAllLogs() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('study_date');

      return response.map((log) => DailyStudyLogModel.fromMap(log)).toList();
    } catch (e, stackTrace) {
      AppLogger.instance.e('getAllLogs error', e, stackTrace);
      return [];
    }
  }

  // 特定の日付の学習記録を取得
  Future<List<DailyStudyLogModel>> getDailyLogs(DateTime date) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];

      final response = await _client
          .from(_tableName)
          .select()
          .eq('study_date', formattedDate)
          .order('goal_id');

      return response.map((log) => DailyStudyLogModel.fromMap(log)).toList();
    } catch (e, stackTrace) {
      AppLogger.instance.e('getDailyLogs error', e, stackTrace);
      return [];
    }
  }

  // 特定の期間の学習記録を取得
  Future<List<DailyStudyLogModel>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await _client
          .from(_tableName)
          .select()
          .gte('study_date', startDateStr)
          .lte('study_date', endDateStr)
          .order('study_date');

      return response.map((log) => DailyStudyLogModel.fromMap(log)).toList();
    } catch (e, stackTrace) {
      AppLogger.instance.e('getLogsByDateRange error', e, stackTrace);
      return [];
    }
  }

  // 特定の目標IDの学習記録を取得
  Future<List<DailyStudyLogModel>> getLogsByGoalId(String goalId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('goal_id', goalId)
          .order('study_date');

      return response.map((log) => DailyStudyLogModel.fromMap(log)).toList();
    } catch (e, stackTrace) {
      AppLogger.instance.e('getLogsByGoalId error', e, stackTrace);
      return [];
    }
  }

  // 特定のIDの学習記録を取得
  Future<DailyStudyLogModel?> getLogById(String id) async {
    try {
      final response =
          await _client.from(_tableName).select().eq('id', id).single();

      return DailyStudyLogModel.fromMap(response);
    } catch (e, stackTrace) {
      AppLogger.instance.e('getLogById error', e, stackTrace);
      return null;
    }
  }

  // 学習記録を作成
  Future<DailyStudyLogModel> createDailyLog(DailyStudyLogModel log) async {
    try {
      // IDが空の場合は新規生成
      final logWithId =
          log.id.isEmpty ? log.copyWith(id: const Uuid().v4()) : log;

      final map = logWithId.toMap();
      await _client.from(_tableName).insert(map);
      return logWithId;
    } catch (e, stackTrace) {
      AppLogger.instance.e('createDailyLog error', e, stackTrace);
      rethrow;
    }
  }

  // 学習記録を更新
  Future<DailyStudyLogModel> updateDailyLog(DailyStudyLogModel log) async {
    try {
      final map = log.toMap();
      await _client.from(_tableName).update(map).eq('id', log.id);
      return log;
    } catch (e, stackTrace) {
      AppLogger.instance.e('updateDailyLog error', e, stackTrace);
      rethrow;
    }
  }

  // 学習記録を追加または更新
  Future<DailyStudyLogModel> upsertDailyLog(DailyStudyLogModel log) async {
    try {
      // IDが空の場合は新規生成
      final logWithId =
          log.id.isEmpty ? log.copyWith(id: const Uuid().v4()) : log;

      final map = logWithId.toMap();
      await _client.from(_tableName).upsert(map, onConflict: 'id');
      return logWithId;
    } catch (e, stackTrace) {
      AppLogger.instance.e('upsertDailyLog error', e, stackTrace);
      rethrow;
    }
  }

  // 学習記録を削除
  Future<bool> deleteDailyLog(String id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.e('deleteDailyLog error', e, stackTrace);
      return false;
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
    } catch (e, stackTrace) {
      AppLogger.instance.e('リモート最終同期更新時刻の取得に失敗しました', e, stackTrace);
      return null;
    }
  }
}
