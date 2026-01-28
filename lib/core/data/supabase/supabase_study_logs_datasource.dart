import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/study_daily_logs/study_daily_logs_model.dart';
import '../../utils/app_logger.dart';

/// Supabase study_daily_logsテーブルを操作するDataSource
class SupabaseStudyLogsDatasource {
  final SupabaseClient _supabase;

  static const String _tableName = 'study_daily_logs';

  SupabaseStudyLogsDatasource({required SupabaseClient supabase})
      : _supabase = supabase;

  /// ユーザーの全ての学習ログを取得
  Future<List<StudyDailyLogsModel>> fetchAllLogs(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('study_date', ascending: false);

      return (response as List)
          .map((json) =>
              StudyDailyLogsModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.instance.e('学習ログ取得に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 特定の目標の学習ログを取得
  Future<List<StudyDailyLogsModel>> fetchLogsByGoalId(String goalId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('goal_id', goalId)
          .order('study_date', ascending: false);

      return (response as List)
          .map((json) =>
              StudyDailyLogsModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標別学習ログ取得に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 学習ログを作成または更新
  /// null値はDBのDEFAULT値を使用するため除外する
  Future<StudyDailyLogsModel> upsertLog(StudyDailyLogsModel log) async {
    try {
      final now = DateTime.now();
      final json = log.copyWith(
        updatedAt: now,
        syncUpdatedAt: now,
      ).toJson();
      // null値を除外してDBのDEFAULT値を使用させる
      json.removeWhere((key, value) => value == null);

      final response = await _supabase
          .from(_tableName)
          .upsert(json)
          .select()
          .single();

      AppLogger.instance.i('学習ログをupsertしました: ${log.id}');
      return StudyDailyLogsModel.fromJson(response);
    } catch (error, stackTrace) {
      AppLogger.instance.e('学習ログupsertに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 複数の学習ログを一括で挿入
  /// null値はDBのDEFAULT値を使用するため除外する
  Future<void> insertLogs(List<StudyDailyLogsModel> logs) async {
    if (logs.isEmpty) return;

    try {
      final now = DateTime.now();
      final logsToInsert = logs.map((log) {
        final json = log.copyWith(
          updatedAt: now,
          syncUpdatedAt: now,
        ).toJson();
        // null値を除外してDBのDEFAULT値を使用させる
        json.removeWhere((key, value) => value == null);
        return json;
      }).toList();

      await _supabase.from(_tableName).upsert(logsToInsert);

      AppLogger.instance.i('${logs.length}件の学習ログを一括upsertしました');
    } catch (error, stackTrace) {
      AppLogger.instance.e('学習ログ一括upsertに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 学習ログを削除
  Future<void> deleteLog(String logId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', logId);

      AppLogger.instance.i('学習ログを削除しました: $logId');
    } catch (error, stackTrace) {
      AppLogger.instance.e('学習ログ削除に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 特定の目標に紐づく学習ログをすべて削除
  Future<void> deleteLogsByGoalId(String goalId) async {
    try {
      await _supabase.from(_tableName).delete().eq('goal_id', goalId);

      AppLogger.instance.i('目標に紐づく学習ログを削除しました: $goalId');
    } catch (error, stackTrace) {
      AppLogger.instance.e('目標別学習ログ削除に失敗しました', error, stackTrace);
      rethrow;
    }
  }
}
