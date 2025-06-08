import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 日々の学習記録のリポジトリ
class DailyStudyLogRepository {
  static const String tableName = 'daily_study_logs';
  final SupabaseClient _client = Supabase.instance.client;

  /// 指定した日付の学習記録を取得する
  Future<List<Map<String, dynamic>>> getDailyLogs(DateTime date) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];

      final response = await _client
          .from(tableName)
          .select()
          .eq('date', formattedDate)
          .order('goal_id');

      return response;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getDailyLogs error', e, stackTrace);
      return [];
    }
  }

  /// 指定した期間の学習記録を取得する
  Future<List<Map<String, dynamic>>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await _client
          .from(tableName)
          .select()
          .gte('date', startDateStr)
          .lte('date', endDateStr)
          .order('date');

      return response;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getLogsByDateRange error', e, stackTrace);
      return [];
    }
  }

  /// 指定した目標の学習記録を取得する
  Future<List<Map<String, dynamic>>> getLogsByGoalId(String goalId) async {
    try {
      final response = await _client
          .from(tableName)
          .select()
          .eq('goal_id', goalId)
          .order('date');

      return response;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getLogsByGoalId error', e, stackTrace);
      return [];
    }
  }

  /// 学習記録を追加または更新する
  Future<bool> upsertDailyLog(Map<String, dynamic> log) async {
    try {
      await _client.from(tableName).upsert(log, onConflict: 'goal_id,date');
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.e('upsertDailyLog error', e, stackTrace);
      return false;
    }
  }

  /// 学習記録を削除する
  Future<bool> deleteDailyLog(String id) async {
    try {
      await _client.from(tableName).delete().eq('id', id);
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.e('deleteDailyLog error', e, stackTrace);
      return false;
    }
  }

  /// 特定の日付の目標別総学習時間を集計する
  Future<Map<String, int>> getTotalMinutesByDate(DateTime date) async {
    try {
      final logs = await getDailyLogs(date);
      final Map<String, int> result = {};

      for (var log in logs) {
        final goalId = log['goal_id'] as String;
        final minutes = log['minutes'] as int;
        result[goalId] = (result[goalId] ?? 0) + minutes;
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getTotalMinutesByDate error', e, stackTrace);
      return {};
    }
  }

  /// 日付ごとの総学習時間を集計する
  Future<Map<DateTime, int>> getTotalMinutesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final logs = await getLogsByDateRange(startDate, endDate);
      final Map<DateTime, int> result = {};

      for (var log in logs) {
        // 日付文字列をDateTimeに変換
        final dateStr = log['date'] as String;
        final date = DateTime.parse(dateStr);
        // 時間部分を切り捨てて日付のみで比較
        final dateKey = DateTime(date.year, date.month, date.day);
        final minutes = log['minutes'] as int;

        result[dateKey] = (result[dateKey] ?? 0) + minutes;
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getTotalMinutesByDateRange error', e, stackTrace);
      return {};
    }
  }
}
