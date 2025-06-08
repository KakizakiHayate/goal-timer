import 'package:goal_timer/core/repositories/daily_study_log_repository.dart';
import 'package:goal_timer/features/statistics/domain/entities/daily_stats.dart';
import 'package:goal_timer/features/statistics/domain/entities/statistics.dart';
import 'package:goal_timer/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final DailyStudyLogRepository _dailyStudyLogRepository =
      DailyStudyLogRepository();
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Statistics>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
    final end = endDate ?? DateTime.now();

    try {
      // 日付範囲内の日々の学習記録を取得
      final dailyLogs = await _dailyStudyLogRepository.getLogsByDateRange(
        start,
        end,
      );

      // 日付ごとにグループ化
      final Map<String, List<Map<String, dynamic>>> logsByDate = {};
      for (var log in dailyLogs) {
        final dateStr = log['date'] as String;
        logsByDate.putIfAbsent(dateStr, () => []).add(log);
      }

      // 統計データに変換
      final List<Statistics> statistics = [];
      for (var entry in logsByDate.entries) {
        final date = DateTime.parse(entry.key);
        int totalMinutes = 0;
        int goalCount = 0;

        // 目標IDごとにユニークカウント
        final Set<String> uniqueGoalIds = {};

        for (var log in entry.value) {
          totalMinutes += log['minutes'] as int;
          uniqueGoalIds.add(log['goal_id'] as String);
        }

        goalCount = uniqueGoalIds.length;

        statistics.add(
          Statistics(
            id: entry.key,
            date: date,
            totalMinutes: totalMinutes,
            goalCount: goalCount,
          ),
        );
      }

      // 日付順にソート
      statistics.sort((a, b) => b.date.compareTo(a.date));

      return statistics;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getStatistics error', e, stackTrace);
      return [];
    }
  }

  @override
  Future<Statistics> getStatisticsById(String id) async {
    // IDは日付文字列を想定
    try {
      final date = DateTime.parse(id);
      final logs = await _dailyStudyLogRepository.getDailyLogs(date);

      if (logs.isEmpty) {
        return Statistics(id: id, date: date, totalMinutes: 0, goalCount: 0);
      }

      int totalMinutes = 0;
      final Set<String> uniqueGoalIds = {};

      for (var log in logs) {
        totalMinutes += log['minutes'] as int;
        uniqueGoalIds.add(log['goal_id'] as String);
      }

      return Statistics(
        id: id,
        date: date,
        totalMinutes: totalMinutes,
        goalCount: uniqueGoalIds.length,
      );
    } catch (e, stackTrace) {
      AppLogger.instance.e('getStatisticsById error', e, stackTrace);
      return Statistics(
        id: id,
        date: DateTime.now(),
        totalMinutes: 0,
        goalCount: 0,
      );
    }
  }

  @override
  Future<DailyStats> getDailyStats(DateTime date) async {
    try {
      // 指定日の学習ログを取得
      final logs = await _dailyStudyLogRepository.getDailyLogs(date);

      if (logs.isEmpty) {
        return DailyStats(
          date: date,
          totalMinutes: 0,
          goalMinutes: {},
          goalTitles: {},
        );
      }

      int totalMinutes = 0;
      final Map<String, int> goalMinutes = {};
      final Map<String, String> goalTitles = {};

      // 目標IDごとに学習時間を集計
      for (var log in logs) {
        final goalId = log['goal_id'] as String;
        final minutes = log['minutes'] as int;

        totalMinutes += minutes;
        goalMinutes[goalId] = (goalMinutes[goalId] ?? 0) + minutes;
      }

      // 目標名を取得
      final goalIds = goalMinutes.keys.toList();
      if (goalIds.isNotEmpty) {
        try {
          // 個別に目標情報を取得
          for (final goalId in goalIds) {
            final goalData =
                await _client
                    .from('goals')
                    .select('title')
                    .eq('id', goalId)
                    .single();

            if (goalData != null) {
              goalTitles[goalId] = goalData['title'] as String;
            }
          }
        } catch (e) {
          AppLogger.instance.e('目標名の取得に失敗しました', e);
        }
      }

      return DailyStats(
        date: date,
        totalMinutes: totalMinutes,
        goalMinutes: goalMinutes,
        goalTitles: goalTitles,
      );
    } catch (e, stackTrace) {
      AppLogger.instance.e('getDailyStats error', e, stackTrace);
      return DailyStats(
        date: date,
        totalMinutes: 0,
        goalMinutes: {},
        goalTitles: {},
      );
    }
  }
}
