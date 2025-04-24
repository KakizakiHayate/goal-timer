import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/usecases/get_statistics_usecase.dart';
import '../../data/repositories/statistics_repository_impl.dart';

// 統計データの状態管理プロバイダー
final statisticsProvider =
    FutureProvider.autoDispose<List<Statistics>>((ref) async {
  final useCase = GetStatisticsUseCase(StatisticsRepositoryImpl());
  return useCase.execute();
});

// 日付フィルタの状態管理
final dateRangeProvider = StateProvider<DateRange>((ref) => DateRange(
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    ));

// 日付範囲のクラス
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({required this.startDate, required this.endDate});
}

// フィルタリングされた統計データのプロバイダー
final filteredStatisticsProvider =
    FutureProvider.autoDispose<List<Statistics>>((ref) async {
  final dateRange = ref.watch(dateRangeProvider);
  final useCase = GetStatisticsUseCase(StatisticsRepositoryImpl());
  return useCase.execute(
      startDate: dateRange.startDate, endDate: dateRange.endDate);
});
