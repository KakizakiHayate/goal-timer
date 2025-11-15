import '../entities/statistics.dart';
import '../repositories/statistics_repository.dart';

class GetStatisticsUseCase {
  final StatisticsRepository repository;

  GetStatisticsUseCase(this.repository);

  Future<List<Statistics>> execute({DateTime? startDate, DateTime? endDate}) {
    return repository.getStatistics(startDate: startDate, endDate: endDate);
  }
}
