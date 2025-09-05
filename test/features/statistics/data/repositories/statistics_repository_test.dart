import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:goal_timer/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:goal_timer/core/data/repositories/hybrid/daily_study_logs/hybrid_daily_study_logs_repository.dart';
import 'package:goal_timer/features/statistics/domain/entities/statistics.dart';
import 'package:goal_timer/features/statistics/domain/entities/daily_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../helpers/statistics_test_data.dart';

// モックの生成
@GenerateMocks([
  HybridDailyStudyLogsRepository,
  SupabaseClient,
  PostgrestFilterBuilder,
])
import 'statistics_repository_test.mocks.dart';

void main() {
  group('StatisticsRepositoryImpl', () {
    late StatisticsRepositoryImpl repository;
    late MockHybridDailyStudyLogsRepository mockDailyStudyLogRepository;
    late MockSupabaseClient mockSupabaseClient;

    setUp(() {
      mockDailyStudyLogRepository = MockHybridDailyStudyLogsRepository();
      mockSupabaseClient = MockSupabaseClient();
      repository = StatisticsRepositoryImpl(mockDailyStudyLogRepository);
    });

    group('getStatistics', () {
      test('TC001: 今週の統計データを正常に取得できること', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();
        final mockLogs = StatisticsTestData.thisWeekStudyLogs;
        
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenAnswer((_) async => mockLogs);

        // Act
        final result = await repository.getStatistics(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isA<List<Statistics>>());
        expect(result.isNotEmpty, isTrue);
        verify(mockDailyStudyLogRepository.getLogsByDateRange(startDate, endDate));
        
        // 総学習時間の検証
        final totalMinutes = result.fold<int>(0, (sum, stat) => sum + stat.totalMinutes);
        expect(totalMinutes, StatisticsTestData.expectedThisWeekTotalMinutes);
      });

      test('TC002: 学習記録がない期間の統計データは空リストを返すこと', () async {
        // Arrange
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now().subtract(const Duration(days: 20));
        
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenAnswer((_) async => StatisticsTestData.emptyStudyLogs);

        // Act
        final result = await repository.getStatistics(
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('TC003: デフォルトの期間（過去7日間）で統計データを取得できること', () async {
        // Arrange
        final mockLogs = StatisticsTestData.thisWeekStudyLogs;
        
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenAnswer((_) async => mockLogs);

        // Act
        final result = await repository.getStatistics();

        // Assert
        expect(result, isA<List<Statistics>>());
        verify(mockDailyStudyLogRepository.getLogsByDateRange(any, any));
        
        // 呼び出し時の引数を検証
        final captured = verify(mockDailyStudyLogRepository.getLogsByDateRange(captureAny, captureAny)).captured;
        final capturedStartDate = captured[0] as DateTime;
        final capturedEndDate = captured[1] as DateTime;
        
        expect(capturedStartDate.difference(DateTime.now()).inDays, closeTo(-7, 1));
        expect(capturedEndDate.difference(DateTime.now()).inMinutes, lessThan(5));
      });

      test('TC004: 日付ごとに正しくグループ化されること', () async {
        // Arrange
        final mockLogs = StatisticsTestData.thisWeekStudyLogs;
        
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenAnswer((_) async => mockLogs);

        // Act
        final result = await repository.getStatistics();

        // Assert
        // 日付順にソートされていることを確認
        for (int i = 0; i < result.length - 1; i++) {
          expect(result[i].date.isAfter(result[i + 1].date) || 
                result[i].date.isAtSameMomentAs(result[i + 1].date), isTrue);
        }
      });

      test('TC005: エラーハンドリング - 例外発生時は空リストを返すこと', () async {
        // Arrange
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getStatistics();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getStatisticsById', () {
      test('TC006: 指定IDの統計データを正常に取得できること', () async {
        // Arrange
        const id = '2025-01-04';
        final date = DateTime.parse(id);
        final mockLogs = StatisticsTestData.filterLogsByDateRange(
          StatisticsTestData.thisWeekStudyLogs,
          date,
          date,
        );
        
        when(mockDailyStudyLogRepository.getDailyLogs(any))
            .thenAnswer((_) async => mockLogs);

        // Act
        final result = await repository.getStatisticsById(id);

        // Assert
        expect(result, isA<Statistics>());
        expect(result.id, id);
        expect(result.date, date);
        verify(mockDailyStudyLogRepository.getDailyLogs(date));
      });

      test('TC007: 該当日の学習記録がない場合は0の統計データを返すこと', () async {
        // Arrange
        const id = '2025-01-01';
        final date = DateTime.parse(id);
        
        when(mockDailyStudyLogRepository.getDailyLogs(any))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getStatisticsById(id);

        // Assert
        expect(result.id, id);
        expect(result.totalMinutes, 0);
        expect(result.goalCount, 0);
      });

      test('TC008: 不正なID形式の場合はエラーハンドリングされること', () async {
        // Arrange
        const invalidId = 'invalid-date';

        // Act
        final result = await repository.getStatisticsById(invalidId);

        // Assert
        expect(result.id, invalidId);
        expect(result.totalMinutes, 0);
        expect(result.goalCount, 0);
      });
    });

    group('getDailyStats', () {
      test('TC009: 指定日の詳細統計データを正常に取得できること', () async {
        // Arrange
        final date = DateTime.now();
        final mockLogs = StatisticsTestData.thisWeekStudyLogs;
        final mockGoalsResponse = [
          {'title': '英語学習'},
          {'title': 'プログラミング'},
          {'title': '資格勉強'},
        ];
        
        when(mockDailyStudyLogRepository.getDailyLogs(any))
            .thenAnswer((_) async => mockLogs);

        // Supabaseクライアントのモック設定
        final mockFilterBuilder = MockPostgrestFilterBuilder();
        when(mockSupabaseClient.from('goals')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenAnswer((_) async => mockGoalsResponse.first);

        // Act
        final result = await repository.getDailyStats(date);

        // Assert
        expect(result, isA<DailyStats>());
        expect(result.date, date);
        expect(result.totalMinutes, greaterThan(0));
        expect(result.goalMinutes.isNotEmpty, isTrue);
        verify(mockDailyStudyLogRepository.getDailyLogs(date));
      });

      test('TC010: 該当日の学習記録がない場合は0の統計データを返すこと', () async {
        // Arrange
        final date = DateTime.now();
        
        when(mockDailyStudyLogRepository.getDailyLogs(any))
            .thenAnswer((_) async => []);

        // Act
        final result = await repository.getDailyStats(date);

        // Assert
        expect(result.date, date);
        expect(result.totalMinutes, 0);
        expect(result.goalMinutes, isEmpty);
        expect(result.goalTitles, isEmpty);
      });

      test('TC011: 目標名の取得に失敗してもエラーにならないこと', () async {
        // Arrange
        final date = DateTime.now();
        final mockLogs = [StatisticsTestData.thisWeekStudyLogs.first];
        
        when(mockDailyStudyLogRepository.getDailyLogs(any))
            .thenAnswer((_) async => mockLogs);

        // Supabaseクライアントのモック設定（エラーを発生させる）
        final mockFilterBuilder = MockPostgrestFilterBuilder();
        when(mockSupabaseClient.from('goals')).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select(any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single()).thenThrow(Exception('Goal not found'));

        // Act
        final result = await repository.getDailyStats(date);

        // Assert
        expect(result, isA<DailyStats>());
        expect(result.totalMinutes, greaterThan(0));
        expect(result.goalMinutes.isNotEmpty, isTrue);
        // 目標名の取得に失敗しても処理は継続される
      });

      test('TC012: エラーハンドリング - 例外発生時は0の統計データを返すこと', () async {
        // Arrange
        final date = DateTime.now();
        
        when(mockDailyStudyLogRepository.getDailyLogs(any))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getDailyStats(date);

        // Assert
        expect(result.date, date);
        expect(result.totalMinutes, 0);
        expect(result.goalMinutes, isEmpty);
        expect(result.goalTitles, isEmpty);
      });
    });

    group('計算ロジックのテスト', () {
      test('TC013: 複数の目標の学習時間が正しく合計されること', () async {
        // Arrange
        final mockLogs = [
          StatisticsTestData.thisWeekStudyLogs[0], // goal1: 60分
          StatisticsTestData.thisWeekStudyLogs[7], // goal2: 45分
          StatisticsTestData.thisWeekStudyLogs[12], // goal3: 30分
        ];
        
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenAnswer((_) async => mockLogs);

        // Act
        final result = await repository.getStatistics();

        // Assert
        expect(result.isNotEmpty, isTrue);
        final dayStats = result.first;
        expect(dayStats.totalMinutes, 135); // 60 + 45 + 30
        expect(dayStats.goalCount, 3); // 3つの異なる目標
      });

      test('TC014: 同じ目標の複数セッションが正しく処理されること', () async {
        // Arrange
        final today = DateTime.now();
        final mockLogs = [
          StatisticsTestData.thisWeekStudyLogs[0].copyWith(
            id: 'session1',
            minutes: 30,
            date: today,
          ),
          StatisticsTestData.thisWeekStudyLogs[0].copyWith(
            id: 'session2',
            minutes: 45,
            date: today,
          ),
        ];
        
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenAnswer((_) async => mockLogs);

        // Act
        final result = await repository.getStatistics();

        // Assert
        expect(result.isNotEmpty, isTrue);
        final dayStats = result.first;
        expect(dayStats.totalMinutes, 75); // 30 + 45
        expect(dayStats.goalCount, 1); // 同じ目標なので1
      });
    });

    group('パフォーマンステスト', () {
      test('TC015: 大量データでも適切に処理されること', () async {
        // Arrange
        final largeLogs = List.generate(1000, (index) => 
          StatisticsTestData.thisWeekStudyLogs[0].copyWith(
            id: 'large-log-$index',
            date: DateTime.now().subtract(Duration(days: index % 30)),
          )
        );
        
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenAnswer((_) async => largeLogs);

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await repository.getStatistics();
        stopwatch.stop();

        // Assert
        expect(result, isA<List<Statistics>>());
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1秒以内
      });
    });

    group('境界値テスト', () {
      test('TC016: 時間が0分の学習記録も正しく処理されること', () async {
        // Arrange
        final mockLogs = [
          StatisticsTestData.thisWeekStudyLogs[0].copyWith(minutes: 0),
        ];
        
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenAnswer((_) async => mockLogs);

        // Act
        final result = await repository.getStatistics();

        // Assert
        expect(result.isNotEmpty, isTrue);
        final dayStats = result.first;
        expect(dayStats.totalMinutes, 0);
        expect(dayStats.goalCount, 1); // 0分でも目標としてカウント
      });

      test('TC017: 非常に大きな学習時間も正しく処理されること', () async {
        // Arrange
        final mockLogs = [
          StatisticsTestData.thisWeekStudyLogs[0].copyWith(minutes: 999999),
        ];
        
        when(mockDailyStudyLogRepository.getLogsByDateRange(any, any))
            .thenAnswer((_) async => mockLogs);

        // Act
        final result = await repository.getStatistics();

        // Assert
        expect(result.isNotEmpty, isTrue);
        final dayStats = result.first;
        expect(dayStats.totalMinutes, 999999);
      });
    });
  });
}