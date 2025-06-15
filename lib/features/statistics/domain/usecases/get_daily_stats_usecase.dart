import '../entities/daily_stats.dart';
import '../repositories/statistics_repository.dart';

/// 特定の日の統計情報を取得するユースケース
class GetDailyStatsUseCase {
  final StatisticsRepository repository;

  GetDailyStatsUseCase(this.repository);

  /// 指定した日付の統計情報を取得する
  Future<DailyStats> execute(DateTime date) {
    return repository.getDailyStats(date);
  }
}
