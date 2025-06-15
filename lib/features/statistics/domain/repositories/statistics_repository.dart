import '../entities/statistics.dart';
import '../entities/daily_stats.dart';

abstract class StatisticsRepository {
  Future<List<Statistics>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Statistics> getStatisticsById(String id);
  Future<DailyStats> getDailyStats(DateTime date);
}
