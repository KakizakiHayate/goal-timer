import 'dart:async';
import 'package:goal_timer/core/data/repositories/hybrid/daily_study_logs/hybrid_daily_study_logs_repository.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';
import 'package:goal_timer/features/statistics/domain/entities/daily_stats.dart';
import 'package:goal_timer/features/statistics/domain/entities/statistics.dart';
import 'package:goal_timer/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final HybridDailyStudyLogsRepository _dailyStudyLogRepository;
  final SupabaseClient _client;

  StatisticsRepositoryImpl(
    this._dailyStudyLogRepository, {
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

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
      final Map<String, List<DailyStudyLogModel>> logsByDate = {};
      for (var log in dailyLogs) {
        final dateStr = log.date.toIso8601String().split('T')[0];
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
          totalMinutes += log.minutes;
          uniqueGoalIds.add(log.goalId);
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
        totalMinutes += log.minutes;
        uniqueGoalIds.add(log.goalId);
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
        final goalId = log.goalId;
        final minutes = log.minutes;

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

            goalTitles[goalId] = goalData['title'] as String;
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

  /// 継続日数を計算する
  Future<int> getConsecutiveStudyDays({DateTime? endDate}) async {
    try {
      final end = endDate ?? DateTime.now();
      int consecutiveDays = 0;
      DateTime currentDate = end;

      // 今日から過去に遡って連続学習日を計算
      while (true) {
        final logs = await _dailyStudyLogRepository.getDailyLogs(currentDate);

        if (logs.isEmpty) {
          // 学習記録がない日があれば継続中断
          break;
        }

        consecutiveDays++;
        currentDate = currentDate.subtract(const Duration(days: 1));

        // 365日以上の計算は避ける（パフォーマンス対策）
        if (consecutiveDays >= 365) break;
      }

      return consecutiveDays;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getConsecutiveStudyDays error', e, stackTrace);
      return 0;
    }
  }

  /// 目標達成率を計算する
  Future<double> getGoalAchievementRate({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();

      // 期間内の未完了な目標を取得（進行中の目標）
      final goalsResponse = await _client
          .from('goals')
          .select('id')
          .eq('is_completed', false);

      if (goalsResponse.isEmpty) return 0.0;

      final totalGoals = (goalsResponse as List).length;

      // 期間内に学習記録がある目標を取得
      final logs = await _dailyStudyLogRepository.getLogsByDateRange(
        start,
        end,
      );
      final studiedGoalIds = logs.map((log) => log.goalId).toSet();

      return (studiedGoalIds.length / totalGoals) * 100;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getGoalAchievementRate error', e, stackTrace);
      return 0.0;
    }
  }

  /// 平均集中時間を計算する
  Future<double> getAverageSessionTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();

      final logs = await _dailyStudyLogRepository.getLogsByDateRange(
        start,
        end,
      );

      if (logs.isEmpty) return 0.0;

      final totalMinutes = logs.fold<int>(0, (sum, log) => sum + log.minutes);
      return totalMinutes / logs.length;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getAverageSessionTime error', e, stackTrace);
      return 0.0;
    }
  }

  /// 期間の学習時間比較
  Future<Map<String, dynamic>> getStudyTimeComparison({
    DateTime? currentStartDate,
    DateTime? currentEndDate,
  }) async {
    try {
      final currentStart =
          currentStartDate ?? DateTime.now().subtract(const Duration(days: 7));
      final currentEnd = currentEndDate ?? DateTime.now();
      final periodDays = currentEnd.difference(currentStart).inDays;

      // 前期間の設定
      final previousEnd = currentStart.subtract(const Duration(days: 1));
      final previousStart = previousEnd.subtract(Duration(days: periodDays));

      // 現在期間のデータ取得
      final currentLogs = await _dailyStudyLogRepository.getLogsByDateRange(
        currentStart,
        currentEnd,
      );
      final currentTotalMinutes = currentLogs.fold<int>(
        0,
        (sum, log) => sum + log.minutes,
      );

      // 前期間のデータ取得
      final previousLogs = await _dailyStudyLogRepository.getLogsByDateRange(
        previousStart,
        previousEnd,
      );
      final previousTotalMinutes = previousLogs.fold<int>(
        0,
        (sum, log) => sum + log.minutes,
      );

      final difference = currentTotalMinutes - previousTotalMinutes;

      return {
        'current': currentTotalMinutes,
        'previous': previousTotalMinutes,
        'difference': difference,
        'changeText':
            difference >= 0
                ? '+${(difference / 60).toStringAsFixed(1)}h'
                : '${(difference / 60).toStringAsFixed(1)}h',
      };
    } catch (e, stackTrace) {
      AppLogger.instance.e('getStudyTimeComparison error', e, stackTrace);
      return {
        'current': 0,
        'previous': 0,
        'difference': 0,
        'changeText': '+0.0h',
      };
    }
  }

  /// 継続日数の比較
  Future<Map<String, dynamic>> getStreakComparison({DateTime? endDate}) async {
    try {
      final end = endDate ?? DateTime.now();
      final currentStreak = await getConsecutiveStudyDays(endDate: end);

      // 7日前の継続日数を計算
      final previousEnd = end.subtract(const Duration(days: 7));
      final previousStreak = await getConsecutiveStudyDays(
        endDate: previousEnd,
      );

      final difference = currentStreak - previousStreak;

      return {
        'current': currentStreak,
        'previous': previousStreak,
        'difference': difference,
        'changeText': difference >= 0 ? '+$difference日' : '$difference日',
      };
    } catch (e, stackTrace) {
      AppLogger.instance.e('getStreakComparison error', e, stackTrace);
      return {
        'current': 0,
        'previous': 0,
        'difference': 0,
        'changeText': '+0日',
      };
    }
  }

  /// 達成率の比較
  Future<Map<String, dynamic>> getAchievementRateComparison({
    DateTime? currentStartDate,
    DateTime? currentEndDate,
  }) async {
    try {
      final currentStart =
          currentStartDate ?? DateTime.now().subtract(const Duration(days: 7));
      final currentEnd = currentEndDate ?? DateTime.now();
      final periodDays = currentEnd.difference(currentStart).inDays;

      // 前期間の設定
      final previousEnd = currentStart.subtract(const Duration(days: 1));
      final previousStart = previousEnd.subtract(Duration(days: periodDays));

      final currentRate = await getGoalAchievementRate(
        startDate: currentStart,
        endDate: currentEnd,
      );
      final previousRate = await getGoalAchievementRate(
        startDate: previousStart,
        endDate: previousEnd,
      );

      final difference = currentRate - previousRate;

      return {
        'current': currentRate,
        'previous': previousRate,
        'difference': difference,
        'changeText':
            difference >= 0
                ? '+${difference.toStringAsFixed(0)}%'
                : '${difference.toStringAsFixed(0)}%',
      };
    } catch (e, stackTrace) {
      AppLogger.instance.e('getAchievementRateComparison error', e, stackTrace);
      return {
        'current': 0.0,
        'previous': 0.0,
        'difference': 0.0,
        'changeText': '+0%',
      };
    }
  }

  /// 平均時間の比較
  Future<Map<String, dynamic>> getAverageTimeComparison({
    DateTime? currentStartDate,
    DateTime? currentEndDate,
  }) async {
    try {
      final currentStart =
          currentStartDate ?? DateTime.now().subtract(const Duration(days: 7));
      final currentEnd = currentEndDate ?? DateTime.now();
      final periodDays = currentEnd.difference(currentStart).inDays;

      // 前期間の設定
      final previousEnd = currentStart.subtract(const Duration(days: 1));
      final previousStart = previousEnd.subtract(Duration(days: periodDays));

      final currentAvg = await getAverageSessionTime(
        startDate: currentStart,
        endDate: currentEnd,
      );
      final previousAvg = await getAverageSessionTime(
        startDate: previousStart,
        endDate: previousEnd,
      );

      final difference = currentAvg - previousAvg;

      return {
        'current': currentAvg,
        'previous': previousAvg,
        'difference': difference,
        'changeText':
            difference >= 0
                ? '+${difference.toStringAsFixed(0)}分'
                : '${difference.toStringAsFixed(0)}分',
      };
    } catch (e, stackTrace) {
      AppLogger.instance.e('getAverageTimeComparison error', e, stackTrace);
      return {
        'current': 0.0,
        'previous': 0.0,
        'difference': 0.0,
        'changeText': '+0分',
      };
    }
  }

  @override
  Future<Map<DateTime, DailyStats>> getBatchDailyStats(
    List<DateTime> dates,
  ) async {
    try {
      if (dates.isEmpty) return {};

      final Map<DateTime, DailyStats> result = {};

      // 日付範囲を取得
      final startDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
      final endDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);

      // 指定期間の全ての学習ログを一括取得
      final allLogs = await _dailyStudyLogRepository.getLogsByDateRange(
        startDate,
        endDate,
      );

      // 日付ごとにログをグループ化
      final Map<String, List<DailyStudyLogModel>> logsByDate = {};
      for (var log in allLogs) {
        final dateStr = log.date.toIso8601String().split('T')[0];
        logsByDate.putIfAbsent(dateStr, () => []).add(log);
      }

      // 全ての目標IDを収集
      final allGoalIds = allLogs.map((log) => log.goalId).toSet().toList();

      // 目標タイトルを一括取得（N+1問題解決）
      final Map<String, String> goalTitles = {};
      if (allGoalIds.isNotEmpty) {
        try {
          final goalsResponse = await _client
              .from('goals')
              .select('id, title')
              .inFilter('id', allGoalIds);

          for (final goalData in goalsResponse) {
            goalTitles[goalData['id'] as String] = goalData['title'] as String;
          }
        } catch (e) {
          AppLogger.instance.e('目標名の一括取得に失敗しました', e);
        }
      }

      // 各日付のDailyStatsを構築
      for (final date in dates) {
        final dateStr = date.toIso8601String().split('T')[0];
        final logsForDate = logsByDate[dateStr] ?? [];

        if (logsForDate.isEmpty) {
          result[date] = DailyStats(
            date: date,
            totalMinutes: 0,
            goalMinutes: {},
            goalTitles: {},
          );
          continue;
        }

        int totalMinutes = 0;
        final Map<String, int> goalMinutes = {};

        // 目標IDごとに学習時間を集計
        for (var log in logsForDate) {
          final goalId = log.goalId;
          final minutes = log.minutes;

          totalMinutes += minutes;
          goalMinutes[goalId] = (goalMinutes[goalId] ?? 0) + minutes;
        }

        // その日に使用された目標のタイトルだけを抽出
        final dayGoalTitles = <String, String>{};
        for (final goalId in goalMinutes.keys) {
          if (goalTitles.containsKey(goalId)) {
            dayGoalTitles[goalId] = goalTitles[goalId]!;
          }
        }

        result[date] = DailyStats(
          date: date,
          totalMinutes: totalMinutes,
          goalMinutes: goalMinutes,
          goalTitles: dayGoalTitles,
        );
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.instance.e('getBatchDailyStats error', e, stackTrace);
      return {};
    }
  }

  @override
  Future<StatisticsBundle> getCompleteStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 全ての統計データを並行取得（型安全）
      final futures = await Future.wait([
        getStatistics(startDate: startDate, endDate: endDate),
        getConsecutiveStudyDays(),
        getGoalAchievementRate(startDate: startDate, endDate: endDate),
        getAverageSessionTime(startDate: startDate, endDate: endDate),
        getStudyTimeComparison(
          currentStartDate: startDate,
          currentEndDate: endDate,
        ),
        getStreakComparison(),
        getAchievementRateComparison(
          currentStartDate: startDate,
          currentEndDate: endDate,
        ),
        getAverageTimeComparison(
          currentStartDate: startDate,
          currentEndDate: endDate,
        ),
      ]);

      return StatisticsBundle(
        statistics: futures[0] as List<Statistics>,
        consecutiveDays: futures[1] as int,
        achievementRate: futures[2] as double,
        averageSessionTime: futures[3] as double,
        studyTimeComparison: futures[4] as Map<String, dynamic>,
        streakComparison: futures[5] as Map<String, dynamic>,
        achievementRateComparison: futures[6] as Map<String, dynamic>,
        averageTimeComparison: futures[7] as Map<String, dynamic>,
      );
    } catch (e, stackTrace) {
      AppLogger.instance.e('getCompleteStatistics error', e, stackTrace);
      // エラー時のデフォルト値を返す
      return StatisticsBundle(
        statistics: [],
        consecutiveDays: 0,
        achievementRate: 0.0,
        averageSessionTime: 0.0,
        studyTimeComparison: {
          'current': 0,
          'previous': 0,
          'difference': 0,
          'changeText': '+0.0h',
        },
        streakComparison: {
          'current': 0,
          'previous': 0,
          'difference': 0,
          'changeText': '+0日',
        },
        achievementRateComparison: {
          'current': 0.0,
          'previous': 0.0,
          'difference': 0.0,
          'changeText': '+0%',
        },
        averageTimeComparison: {
          'current': 0.0,
          'previous': 0.0,
          'difference': 0.0,
          'changeText': '+0分',
        },
      );
    }
  }

  /// Issue #52: ローカルDB優先でデータを取得
  Future<List<Statistics>> getLocalStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.instance.i('🏠 統計データをローカルDBから取得開始');
      
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();

      // ローカルDBから直接取得（Supabaseへの通信なし）
      final dailyLogs = await _dailyStudyLogRepository.getLogsByDateRange(
        start,
        end,
      );

      // 日付ごとにグループ化
      final Map<String, List<DailyStudyLogModel>> logsByDate = {};
      for (var log in dailyLogs) {
        final dateStr = log.date.toIso8601String().split('T')[0];
        logsByDate.putIfAbsent(dateStr, () => []).add(log);
      }

      // 統計データに変換
      final List<Statistics> statistics = [];
      for (var entry in logsByDate.entries) {
        final date = DateTime.parse(entry.key);
        int totalMinutes = 0;
        final Set<String> uniqueGoalIds = {};

        for (var log in entry.value) {
          totalMinutes += log.minutes;
          uniqueGoalIds.add(log.goalId);
        }

        statistics.add(
          Statistics(
            id: entry.key,
            date: date,
            totalMinutes: totalMinutes,
            goalCount: uniqueGoalIds.length,
          ),
        );
      }

      // 日付順にソート
      statistics.sort((a, b) => b.date.compareTo(a.date));

      AppLogger.instance.i('✅ ローカル統計データ取得完了: ${statistics.length}件');
      return statistics;
    } catch (e, stackTrace) {
      AppLogger.instance.e('❌ ローカル統計データ取得エラー', e, stackTrace);
      return [];
    }
  }

  /// Issue #52: ローカルDB優先で完全統計データを取得
  Future<StatisticsBundle> getLocalCompleteStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.instance.i('🏠 完全統計データをローカルDBから取得開始');

      // ローカルデータのみを使用して統計計算
      final statistics = await getLocalStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      // 継続日数計算（ローカルのみ）
      int consecutiveDays = 0;
      try {
        consecutiveDays = await _calculateLocalConsecutiveDays();
      } catch (e) {
        AppLogger.instance.w('継続日数計算エラー（ローカル）: $e');
      }

      // 簡易的な達成率・平均時間計算
      double achievementRate = 0.0;
      double averageSessionTime = 0.0;
      if (statistics.isNotEmpty) {
        final totalMinutes = statistics.fold<int>(0, (sum, stat) => sum + stat.totalMinutes);
        final daysWithData = statistics.where((stat) => stat.totalMinutes > 0).length;
        achievementRate = daysWithData / statistics.length * 100;
        averageSessionTime = daysWithData > 0 ? totalMinutes / daysWithData : 0.0;
      }

      AppLogger.instance.i('✅ ローカル完全統計データ取得完了');
      
      return StatisticsBundle(
        statistics: statistics,
        consecutiveDays: consecutiveDays,
        achievementRate: achievementRate,
        averageSessionTime: averageSessionTime,
        studyTimeComparison: {'current': 0, 'previous': 0, 'difference': 0, 'changeText': '+0.0h'},
        streakComparison: {'current': 0, 'previous': 0, 'difference': 0, 'changeText': '+0日'},
        achievementRateComparison: {'current': 0.0, 'previous': 0.0, 'difference': 0.0, 'changeText': '+0%'},
        averageTimeComparison: {'current': 0.0, 'previous': 0.0, 'difference': 0.0, 'changeText': '+0分'},
      );
    } catch (e, stackTrace) {
      AppLogger.instance.e('❌ ローカル完全統計データ取得エラー', e, stackTrace);
      return StatisticsBundle(
        statistics: [],
        consecutiveDays: 0,
        achievementRate: 0.0,
        averageSessionTime: 0.0,
        studyTimeComparison: {'current': 0, 'previous': 0, 'difference': 0, 'changeText': '+0.0h'},
        streakComparison: {'current': 0, 'previous': 0, 'difference': 0, 'changeText': '+0日'},
        achievementRateComparison: {'current': 0.0, 'previous': 0.0, 'difference': 0.0, 'changeText': '+0%'},
        averageTimeComparison: {'current': 0.0, 'previous': 0.0, 'difference': 0.0, 'changeText': '+0分'},
      );
    }
  }

  /// Issue #52: バックグラウンド同期チェックとデータ更新
  Future<StatisticsBundle?> checkAndSyncIfNeeded({
    required DateTime startDate,
    required DateTime endDate,
    bool isAuthenticatedUser = false,
  }) async {
    try {
      // ゲストユーザーの場合は同期をスキップ
      if (!isAuthenticatedUser) {
        AppLogger.instance.i('👤 ゲストユーザー: 同期チェックをスキップ');
        return null;
      }

      AppLogger.instance.i('🔄 バックグラウンド同期チェック開始');

      // 簡易的な同期判定（実際の実装ではより詳細な更新日時比較を行う）
      final needsSync = await _needsSynchronization(startDate, endDate);
      
      if (!needsSync) {
        AppLogger.instance.i('✅ 同期不要: データが最新です');
        return null;
      }

      AppLogger.instance.i('🔄 同期が必要: データ同期を実行');
      
      // 実際の同期処理を実行
      final syncedData = await getCompleteStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      AppLogger.instance.i('✅ バックグラウンド同期完了');
      return syncedData;
    } catch (e, stackTrace) {
      AppLogger.instance.e('❌ バックグラウンド同期エラー', e, stackTrace);
      // エラーの場合はnullを返してローカルデータを維持
      return null;
    }
  }

  /// Issue #52: 同期が必要かどうかを判定
  Future<bool> _needsSynchronization(DateTime startDate, DateTime endDate) async {
    try {
      // TODO: 実際の実装では最終更新日時の比較を行う
      // 現在は簡易的にランダムで判定（デモ用）
      await Future.delayed(const Duration(milliseconds: 500)); // 通信のシミュレーション
      return DateTime.now().millisecond % 3 == 0; // 約1/3の確率で同期が必要
    } catch (e) {
      AppLogger.instance.w('同期判定エラー: $e');
      return false;
    }
  }

  /// Issue #52: ローカルの継続日数計算
  Future<int> _calculateLocalConsecutiveDays() async {
    try {
      final today = DateTime.now();
      int consecutiveDays = 0;
      
      // 今日から遡って継続日数をカウント
      for (int i = 0; i < 365; i++) { // 最大365日遡る
        final checkDate = today.subtract(Duration(days: i));
        final logs = await _dailyStudyLogRepository.getDailyLogs(checkDate);
        
        if (logs.isNotEmpty) {
          consecutiveDays++;
        } else {
          break; // 学習記録がない日で継続が途切れる
        }
      }
      
      return consecutiveDays;
    } catch (e) {
      AppLogger.instance.w('ローカル継続日数計算エラー: $e');
      return 0;
    }
  }
}
