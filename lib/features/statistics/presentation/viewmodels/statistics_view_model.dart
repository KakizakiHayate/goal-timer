import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/features/auth/domain/entities/auth_state.dart';
import 'package:goal_timer/features/auth/provider/auth_provider.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/entities/daily_stats.dart';
import '../../domain/repositories/statistics_repository.dart';
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

/// Issue #52: 最適化されたローカル優先統計メトリクスプロバイダー
final optimizedStatisticsMetricsProvider = StateNotifierProvider.autoDispose<OptimizedStatisticsNotifier, AsyncValue<StatisticsMetrics>>(
  (ref) => OptimizedStatisticsNotifier(ref),
);

/// Issue #52: 最適化統計データ管理用StateNotifier
class OptimizedStatisticsNotifier extends StateNotifier<AsyncValue<StatisticsMetrics>> {
  final AutoDisposeRef _ref;
  Timer? _syncTimer;

  OptimizedStatisticsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initializeOptimizedStatistics();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  /// Issue #52: 最適化統計データの初期化
  Future<void> _initializeOptimizedStatistics() async {
    try {
      AppLogger.instance.i('🚀 最適化統計データ初期化開始');
      
      // 1. ローカルデータを即座に取得・表示
      final dateRange = _ref.read(dateRangeProvider);
      final repository = _ref.read(statisticsRepositoryProvider);
      
      final localData = await repository.getLocalCompleteStatistics(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
      
      // ローカルデータを即座に表示
      state = AsyncValue.data(_buildStatisticsMetrics(localData));
      AppLogger.instance.i('✅ ローカルデータ表示完了');
      
      // 2. 並行処理でバックグラウンド同期チェック
      _startBackgroundSyncCheck();
      
    } catch (e, stackTrace) {
      AppLogger.instance.e('❌ 最適化統計データ初期化エラー', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Issue #52: バックグラウンド同期チェック開始
  void _startBackgroundSyncCheck() {
    // 認証状態を確認
    final authState = _ref.read(authViewModelProvider);
    final isAuthenticated = !authState.isGuest && authState.isAuthenticated;
    
    if (!isAuthenticated) {
      AppLogger.instance.i('👤 ゲストユーザーのため同期チェックをスキップ');
      return;
    }
    
    // マイクロタスクで並行処理実行
    Future.microtask(() async {
      try {
        final dateRange = _ref.read(dateRangeProvider);
        final repository = _ref.read(statisticsRepositoryProvider);
        
        final syncedData = await repository.checkAndSyncIfNeeded(
          startDate: dateRange.startDate,
          endDate: dateRange.endDate,
          isAuthenticatedUser: isAuthenticated,
        );
        
        // 同期されたデータがある場合のみUI更新
        if (syncedData != null && mounted) {
          state = AsyncValue.data(_buildStatisticsMetrics(syncedData));
          AppLogger.instance.i('🔄 バックグラウンド同期によりUI更新');
        }
      } catch (e, stackTrace) {
        AppLogger.instance.e('❌ バックグラウンド同期エラー', e, stackTrace);
        // エラーの場合はローカルデータを維持（stateは更新しない）
      }
    });
  }

  /// Issue #52: StatisticsBundleからStatisticsMetricsを構築
  StatisticsMetrics _buildStatisticsMetrics(StatisticsBundle bundle) {
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
  }

  /// Issue #52: 期間変更時の処理
  void onDateRangeChanged() {
    AppLogger.instance.i('📅 期間変更により統計データを更新');
    _initializeOptimizedStatistics();
  }
}
