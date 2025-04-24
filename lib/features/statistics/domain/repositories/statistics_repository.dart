import '../entities/statistics.dart';

abstract class StatisticsRepository {
  Future<List<Statistics>> getStatistics(
      {DateTime? startDate, DateTime? endDate});
  Future<Statistics> getStatisticsById(String id);
}
