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

// 統計メトリクスのプロバイダー（型安全性向上）
final statisticsMetricsProvider = FutureProvider.autoDispose<StatisticsMetrics>(
  (ref) async {
    final dateRange = ref.watch(dateRangeProvider);
    final repository = ref.watch(statisticsRepositoryProvider);

    // 型安全な一括取得メソッドを使用
    final bundle = await repository.getCompleteStatistics(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
    );

    final totalMinutes = bundle.statistics.fold<int>(
      0,
      (sum, stat) => sum + stat.totalMinutes,
    );

    return StatisticsMetrics(
      totalHours: (totalMinutes / 60).toStringAsFixed(1),
      consecutiveDays: bundle.consecutiveDays.toString(),
      achievementRate: bundle.achievementRate.toStringAsFixed(0),
      averageSessionTime: bundle.averageSessionTime.toStringAsFixed(0),
      studyTimeComparison: bundle.studyTimeComparison,
      streakComparison: bundle.streakComparison,
      achievementRateComparison: bundle.achievementRateComparison,
      averageTimeComparison: bundle.averageTimeComparison,
    );
  },
);

// 目標別統計データのプロバイダー（N+1クエリ問題解決）
final goalStatisticsProvider = FutureProvider.autoDispose<List<GoalStatistic>>((
  ref,
) async {
  final dateRange = ref.watch(dateRangeProvider);
  final repository = ref.watch(statisticsRepositoryProvider);

  final statistics = await repository.getStatistics(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  );

  if (statistics.isEmpty) {
    return [];
  }

  // 全ての日付を収集してバッチクエリを実行
  final dates = statistics.map((stat) => stat.date).toList();
  final batchDailyStats = await repository.getBatchDailyStats(dates);

  // 目標IDごとの学習時間を集計
  final Map<String, int> goalMinutes = {};
  final Map<String, String> goalTitles = {};

  for (final dailyStats in batchDailyStats.values) {
    for (final entry in dailyStats.goalMinutes.entries) {
      goalMinutes[entry.key] = (goalMinutes[entry.key] ?? 0) + entry.value;
      if (dailyStats.goalTitles.containsKey(entry.key)) {
        goalTitles[entry.key] = dailyStats.goalTitles[entry.key]!;
      }
    }
  }

  // 学習時間順にソートして目標統計リストを作成
  final sortedGoals =
      goalMinutes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  return sortedGoals
      .map(
        (entry) => GoalStatistic(
          goalId: entry.key,
          goalTitle: goalTitles[entry.key] ?? 'Unknown Goal',
          totalMinutes: entry.value,
        ),
      )
      .toList();
});

// 統計メトリクスデータクラス
class StatisticsMetrics {
  final String totalHours;
  final String consecutiveDays;
  final String achievementRate;
  final String averageSessionTime;
  final Map<String, dynamic> studyTimeComparison;
  final Map<String, dynamic> streakComparison;
  final Map<String, dynamic> achievementRateComparison;
  final Map<String, dynamic> averageTimeComparison;

  StatisticsMetrics({
    required this.totalHours,
    required this.consecutiveDays,
    required this.achievementRate,
    required this.averageSessionTime,
    required this.studyTimeComparison,
    required this.streakComparison,
    required this.achievementRateComparison,
    required this.averageTimeComparison,
  });
}

// 目標統計データクラス
class GoalStatistic {
  final String goalId;
  final String goalTitle;
  final int totalMinutes;

  GoalStatistic({
    required this.goalId,
    required this.goalTitle,
    required this.totalMinutes,
  });
}
