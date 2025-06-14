import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/provider/providers.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/entities/daily_stats.dart';
import '../../domain/usecases/get_statistics_usecase.dart';
import '../../domain/usecases/get_daily_stats_usecase.dart';
import '../../data/repositories/statistics_repository_impl.dart';

// リポジトリプロバイダー
final statisticsRepositoryProvider = Provider<StatisticsRepositoryImpl>((ref) {
  final dailyStudyLogsRepository = ref.watch(
    hybridDailyStudyLogsRepositoryProvider,
  );
  return StatisticsRepositoryImpl(dailyStudyLogsRepository);
});

// ユースケースプロバイダー
final getStatisticsUseCaseProvider = Provider<GetStatisticsUseCase>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return GetStatisticsUseCase(repository);
});

final getDailyStatsUseCaseProvider = Provider<GetDailyStatsUseCase>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return GetDailyStatsUseCase(repository);
});

// 統計データの状態管理プロバイダー
final statisticsProvider = FutureProvider.autoDispose<List<Statistics>>((
  ref,
) async {
  final useCase = ref.watch(getStatisticsUseCaseProvider);
  return useCase.execute();
});

// 日付フィルタの状態管理
final dateRangeProvider = StateProvider<DateRange>(
  (ref) => DateRange(
    startDate: DateTime.now().subtract(const Duration(days: 7)),
    endDate: DateTime.now(),
  ),
);

// 日付範囲のクラス
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({required this.startDate, required this.endDate});
}

// フィルタリングされた統計データのプロバイダー
final filteredStatisticsProvider = FutureProvider.autoDispose<List<Statistics>>(
  (ref) async {
    final dateRange = ref.watch(dateRangeProvider);
    final useCase = ref.watch(getStatisticsUseCaseProvider);
    return useCase.execute(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
    );
  },
);

// 選択された日付の状態管理
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 選択された日付の詳細統計データのプロバイダー
final dailyStatsProvider = FutureProvider.autoDispose<DailyStats>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final useCase = ref.watch(getDailyStatsUseCaseProvider);
  return useCase.execute(selectedDate);
});
