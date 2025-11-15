import '../entities/statistics.dart';
import '../entities/daily_stats.dart';

abstract class StatisticsRepository {
  Future<List<Statistics>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Statistics> getStatisticsById(String id);
  Future<DailyStats> getDailyStats(DateTime date);

  // バッチクエリメソッド（N+1問題解決用）
  Future<Map<DateTime, DailyStats>> getBatchDailyStats(List<DateTime> dates);

  // 統計データを一括取得する型安全なメソッド
  Future<StatisticsBundle> getCompleteStatistics({
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// 統計データをまとめて管理するクラス（型安全性向上）
class StatisticsBundle {
  final List<Statistics> statistics;
  final int consecutiveDays;
  final double achievementRate;
  final double averageSessionTime;
  final Map<String, dynamic> studyTimeComparison;
  final Map<String, dynamic> streakComparison;
  final Map<String, dynamic> achievementRateComparison;
  final Map<String, dynamic> averageTimeComparison;

  StatisticsBundle({
    required this.statistics,
    required this.consecutiveDays,
    required this.achievementRate,
    required this.averageSessionTime,
    required this.studyTimeComparison,
    required this.streakComparison,
    required this.achievementRateComparison,
    required this.averageTimeComparison,
  });
}
