import '../../domain/entities/statistics.dart';
import '../../domain/repositories/statistics_repository.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  @override
  Future<List<Statistics>> getStatistics(
      {DateTime? startDate, DateTime? endDate}) async {
    // TODO: 実際のデータソースからデータを取得する実装
    // 仮のデータを返す
    return [
      Statistics(
        id: '1',
        date: DateTime.now().subtract(const Duration(days: 1)),
        totalMinutes: 120,
        goalCount: 3,
      ),
      Statistics(
        id: '2',
        date: DateTime.now().subtract(const Duration(days: 2)),
        totalMinutes: 90,
        goalCount: 2,
      ),
    ];
  }

  @override
  Future<Statistics> getStatisticsById(String id) async {
    // TODO: 実際のデータソースからデータを取得する実装
    return Statistics(
      id: id,
      date: DateTime.now(),
      totalMinutes: 60,
      goalCount: 1,
    );
  }
}
