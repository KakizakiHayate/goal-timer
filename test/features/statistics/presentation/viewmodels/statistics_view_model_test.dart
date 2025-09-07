import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/statistics/presentation/viewmodels/statistics_view_model.dart';
import 'package:goal_timer/features/statistics/domain/usecases/get_statistics_usecase.dart';
import 'package:goal_timer/features/statistics/domain/usecases/get_daily_stats_usecase.dart';
import 'package:goal_timer/features/statistics/domain/entities/daily_stats.dart';
import '../../helpers/statistics_test_data.dart';

// モックの生成
@GenerateMocks([
  GetStatisticsUseCase,
  GetDailyStatsUseCase,
])
import 'statistics_view_model_test.mocks.dart';

void main() {
  group('StatisticsViewModel Providers', () {
    late MockGetStatisticsUseCase mockGetStatisticsUseCase;
    late MockGetDailyStatsUseCase mockGetDailyStatsUseCase;
    late ProviderContainer container;

    setUp(() {
      mockGetStatisticsUseCase = MockGetStatisticsUseCase();
      mockGetDailyStatsUseCase = MockGetDailyStatsUseCase();
      
      container = ProviderContainer(
        overrides: [
          getStatisticsUseCaseProvider.overrideWithValue(mockGetStatisticsUseCase),
          getDailyStatsUseCaseProvider.overrideWithValue(mockGetDailyStatsUseCase),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('statisticsProvider', () {
      test('TC001: デフォルト期間での統計データ取得が成功すること', () async {
        // Arrange
        final expectedStatistics = [StatisticsTestData.expectedThisWeekStatistics];
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => expectedStatistics);

        // Act
        final result = await container.read(statisticsProvider.future);

        // Assert
        expect(result, equals(expectedStatistics));
        verify(mockGetStatisticsUseCase.execute()).called(1);
      });

      test('TC002: UseCaseでエラーが発生した場合例外が伝播されること', () async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          container.read(statisticsProvider.future),
          throwsA(isA<Exception>()),
        );
      });

      test('TC003: 空のデータが返された場合正しく処理されること', () async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        final result = await container.read(statisticsProvider.future);

        // Assert
        expect(result, isEmpty);
        verify(mockGetStatisticsUseCase.execute()).called(1);
      });
    });

    group('dateRangeProvider', () {
      test('TC004: 初期値は過去7日間に設定されること', () {
        // Act
        final dateRange = container.read(dateRangeProvider);

        // Assert
        final now = DateTime.now();
        final expectedStartDate = now.subtract(const Duration(days: 7));
        
        // 日付の差が1日以内であることを確認（時分秒の違いを許容）
        expect(
          dateRange.startDate.difference(expectedStartDate).inDays.abs(),
          lessThanOrEqualTo(1),
        );
        expect(
          dateRange.endDate.difference(now).inDays.abs(),
          lessThanOrEqualTo(1),
        );
      });

      test('TC005: 日付範囲を更新できること', () {
        // Arrange
        final newStartDate = DateTime(2025, 1, 1);
        final newEndDate = DateTime(2025, 1, 31);
        final newDateRange = DateRange(startDate: newStartDate, endDate: newEndDate);

        // Act
        container.read(dateRangeProvider.notifier).state = newDateRange;
        final result = container.read(dateRangeProvider);

        // Assert
        expect(result.startDate, equals(newStartDate));
        expect(result.endDate, equals(newEndDate));
      });
    });

    group('filteredStatisticsProvider', () {
      test('TC006: 日付範囲フィルターが適用された統計データを取得できること', () async {
        // Arrange
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);
        final dateRange = DateRange(startDate: startDate, endDate: endDate);
        final expectedStatistics = [StatisticsTestData.expectedThisWeekStatistics];
        
        container.read(dateRangeProvider.notifier).state = dateRange;
        when(mockGetStatisticsUseCase.execute(
          startDate: startDate,
          endDate: endDate,
        )).thenAnswer((_) async => expectedStatistics);

        // Act
        final result = await container.read(filteredStatisticsProvider.future);

        // Assert
        expect(result, equals(expectedStatistics));
        verify(mockGetStatisticsUseCase.execute(
          startDate: startDate,
          endDate: endDate,
        )).called(1);
      });

      test('TC007: 日付範囲が変更されると新しいデータが取得されること', () async {
        // Arrange
        final initialDateRange = DateRange(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 31),
        );
        final newDateRange = DateRange(
          startDate: DateTime(2025, 2, 1),
          endDate: DateTime(2025, 2, 28),
        );
        final initialStatistics = [StatisticsTestData.expectedLastWeekStatistics];
        final newStatistics = [StatisticsTestData.expectedThisWeekStatistics];

        // 初期設定
        container.read(dateRangeProvider.notifier).state = initialDateRange;
        when(mockGetStatisticsUseCase.execute(
          startDate: initialDateRange.startDate,
          endDate: initialDateRange.endDate,
        )).thenAnswer((_) async => initialStatistics);

        // 最初のデータ取得
        final initialResult = await container.read(filteredStatisticsProvider.future);
        expect(initialResult, equals(initialStatistics));

        // 日付範囲を変更
        container.read(dateRangeProvider.notifier).state = newDateRange;
        when(mockGetStatisticsUseCase.execute(
          startDate: newDateRange.startDate,
          endDate: newDateRange.endDate,
        )).thenAnswer((_) async => newStatistics);

        // Act - 新しいコンテナで再取得
        final newContainer = ProviderContainer(
          overrides: [
            getStatisticsUseCaseProvider.overrideWithValue(mockGetStatisticsUseCase),
            dateRangeProvider.overrideWith((ref) => newDateRange),
          ],
        );

        final newResult = await newContainer.read(filteredStatisticsProvider.future);

        // Assert
        expect(newResult, equals(newStatistics));
        verify(mockGetStatisticsUseCase.execute(
          startDate: newDateRange.startDate,
          endDate: newDateRange.endDate,
        )).called(1);

        newContainer.dispose();
      });

      test('TC008: フィルター適用時にエラーが発生した場合例外が伝播されること', () async {
        // Arrange
        final dateRange = DateRange(
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 31),
        );
        container.read(dateRangeProvider.notifier).state = dateRange;
        when(mockGetStatisticsUseCase.execute(
          startDate: dateRange.startDate,
          endDate: dateRange.endDate,
        )).thenThrow(Exception('Filter error'));

        // Act & Assert
        expect(
          container.read(filteredStatisticsProvider.future),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('selectedDateProvider', () {
      test('TC009: 初期値は現在日時に設定されること', () {
        // Act
        final selectedDate = container.read(selectedDateProvider);

        // Assert
        final now = DateTime.now();
        expect(
          selectedDate.difference(now).inMinutes.abs(),
          lessThan(5), // 5分以内の差を許容
        );
      });

      test('TC010: 選択日付を更新できること', () {
        // Arrange
        final newDate = DateTime(2025, 1, 15);

        // Act
        container.read(selectedDateProvider.notifier).state = newDate;
        final result = container.read(selectedDateProvider);

        // Assert
        expect(result, equals(newDate));
      });
    });

    group('dailyStatsProvider', () {
      test('TC011: 選択された日付の詳細統計データを取得できること', () async {
        // Arrange
        final selectedDate = DateTime(2025, 1, 15);
        final expectedDailyStats = StatisticsTestData.expectedThisWeekDailyStats;
        
        container.read(selectedDateProvider.notifier).state = selectedDate;
        when(mockGetDailyStatsUseCase.execute(selectedDate))
            .thenAnswer((_) async => expectedDailyStats);

        // Act
        final result = await container.read(dailyStatsProvider.future);

        // Assert
        expect(result, equals(expectedDailyStats));
        verify(mockGetDailyStatsUseCase.execute(selectedDate)).called(1);
      });

      test('TC012: 選択日付が変更されると新しいデータが取得されること', () async {
        // Arrange
        final initialDate = DateTime(2025, 1, 15);
        final newDate = DateTime(2025, 1, 20);
        final initialStats = DailyStats(
          date: initialDate,
          totalMinutes: 100,
          goalMinutes: {'goal1': 100},
          goalTitles: {'goal1': 'Initial Goal'},
        );
        final newStats = StatisticsTestData.expectedThisWeekDailyStats;

        // 初期設定
        container.read(selectedDateProvider.notifier).state = initialDate;
        when(mockGetDailyStatsUseCase.execute(initialDate))
            .thenAnswer((_) async => initialStats);

        // 最初のデータ取得
        final initialResult = await container.read(dailyStatsProvider.future);
        expect(initialResult, equals(initialStats));

        // 選択日付を変更
        container.read(selectedDateProvider.notifier).state = newDate;
        when(mockGetDailyStatsUseCase.execute(newDate))
            .thenAnswer((_) async => newStats);

        // Act - 新しいコンテナで再取得
        final newContainer = ProviderContainer(
          overrides: [
            getDailyStatsUseCaseProvider.overrideWithValue(mockGetDailyStatsUseCase),
            selectedDateProvider.overrideWith((ref) => newDate),
          ],
        );

        final newResult = await newContainer.read(dailyStatsProvider.future);

        // Assert
        expect(newResult, equals(newStats));
        verify(mockGetDailyStatsUseCase.execute(newDate)).called(1);

        newContainer.dispose();
      });

      test('TC013: 詳細統計データ取得でエラーが発生した場合例外が伝播されること', () async {
        // Arrange
        final selectedDate = DateTime(2025, 1, 15);
        container.read(selectedDateProvider.notifier).state = selectedDate;
        when(mockGetDailyStatsUseCase.execute(selectedDate))
            .thenThrow(Exception('DailyStats error'));

        // Act & Assert
        expect(
          container.read(dailyStatsProvider.future),
          throwsA(isA<Exception>()),
        );
      });

      test('TC014: 学習記録がない日付でも正しく処理されること', () async {
        // Arrange
        final selectedDate = DateTime(2025, 1, 1);
        final emptyStats = DailyStats(
          date: selectedDate,
          totalMinutes: 0,
          goalMinutes: {},
          goalTitles: {},
        );
        
        container.read(selectedDateProvider.notifier).state = selectedDate;
        when(mockGetDailyStatsUseCase.execute(selectedDate))
            .thenAnswer((_) async => emptyStats);

        // Act
        final result = await container.read(dailyStatsProvider.future);

        // Assert
        expect(result.totalMinutes, equals(0));
        expect(result.goalMinutes, isEmpty);
        expect(result.goalTitles, isEmpty);
        verify(mockGetDailyStatsUseCase.execute(selectedDate)).called(1);
      });
    });

    group('DateRangeクラス', () {
      test('TC015: DateRangeコンストラクタが正しく動作すること', () {
        // Arrange
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);

        // Act
        final dateRange = DateRange(startDate: startDate, endDate: endDate);

        // Assert
        expect(dateRange.startDate, equals(startDate));
        expect(dateRange.endDate, equals(endDate));
      });

      test('TC016: 同じ日付のDateRangeが作成できること', () {
        // Arrange
        final date = DateTime(2025, 1, 15);

        // Act
        final dateRange = DateRange(startDate: date, endDate: date);

        // Assert
        expect(dateRange.startDate, equals(date));
        expect(dateRange.endDate, equals(date));
      });
    });

    group('プロバイダーの依存関係テスト', () {
      test('TC017: 統計関連プロバイダーが正しく依存関係を持っていること', () {
        // Act & Assert - プロバイダーが正常に作成されることを確認
        expect(() => container.read(statisticsProvider), isNot(throwsA(anything)));
        expect(() => container.read(dateRangeProvider), isNot(throwsA(anything)));
        expect(() => container.read(filteredStatisticsProvider), isNot(throwsA(anything)));
        expect(() => container.read(selectedDateProvider), isNot(throwsA(anything)));
        expect(() => container.read(dailyStatsProvider), isNot(throwsA(anything)));
      });

      test('TC018: autoDispose プロバイダーが適切に破棄されること', () {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => [StatisticsTestData.expectedThisWeekStatistics]);

        // Act - プロバイダーを読み込み
        container.read(statisticsProvider);
        container.read(filteredStatisticsProvider);
        container.read(dailyStatsProvider);

        // コンテナを破棄してautoDisposeが動作することを確認
        container.dispose();

        // Assert - 新しいコンテナでプロバイダーが再作成されることを確認
        final newContainer = ProviderContainer(
          overrides: [
            getStatisticsUseCaseProvider.overrideWithValue(mockGetStatisticsUseCase),
            getDailyStatsUseCaseProvider.overrideWithValue(mockGetDailyStatsUseCase),
          ],
        );

        expect(() => newContainer.read(statisticsProvider), isNot(throwsA(anything)));
        newContainer.dispose();
      });
    });

    group('エラーハンドリングテスト', () {
      test('TC019: 複数のプロバイダーで同時にエラーが発生した場合', () async {
        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenThrow(Exception('Statistics error'));
        when(mockGetDailyStatsUseCase.execute(any))
            .thenThrow(Exception('DailyStats error'));

        // Act & Assert
        expect(
          container.read(statisticsProvider.future),
          throwsA(isA<Exception>()),
        );
        expect(
          container.read(dailyStatsProvider.future),
          throwsA(isA<Exception>()),
        );
      });

      test('TC020: null値が返された場合の処理', () async {
        // Note: この実装では null は返されないが、将来的な拡張性のためのテスト
        // UseCaseの実装上、nullは返されないがエラーハンドリングとして記述

        // Arrange
        when(mockGetStatisticsUseCase.execute())
            .thenAnswer((_) async => []);

        // Act
        final result = await container.read(statisticsProvider.future);

        // Assert
        expect(result, isNotNull);
        expect(result, isEmpty);
      });
    });
  });
}