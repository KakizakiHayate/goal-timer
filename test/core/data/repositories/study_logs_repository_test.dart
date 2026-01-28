import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/local_study_daily_logs_datasource.dart';
import 'package:goal_timer/core/data/repositories/study_logs_repository.dart';
import 'package:goal_timer/core/data/supabase/supabase_study_logs_datasource.dart';
import 'package:goal_timer/core/models/study_daily_logs/study_daily_logs_model.dart';
import 'package:goal_timer/core/services/migration_service.dart';
import 'package:goal_timer/core/utils/streak_consts.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStudyLogsDatasource extends Mock
    implements LocalStudyDailyLogsDatasource {}

class MockSupabaseStudyLogsDatasource extends Mock
    implements SupabaseStudyLogsDatasource {}

class MockMigrationService extends Mock implements MigrationService {}

class FakeStudyDailyLogsModel extends Fake implements StudyDailyLogsModel {}

void main() {
  late MockLocalStudyLogsDatasource mockLocalDs;
  late MockSupabaseStudyLogsDatasource mockSupabaseDs;
  late MockMigrationService mockMigrationService;
  late StudyLogsRepository repository;

  final testUserId = 'test-user-id';
  final testGoalId = 'goal-1';

  final testLog1 = StudyDailyLogsModel(
    id: 'log-1',
    goalId: testGoalId,
    studyDate: DateTime(2025, 1, 15),
    totalSeconds: 3600,
    createdAt: DateTime(2025, 1, 15),
  );

  final testLog2 = StudyDailyLogsModel(
    id: 'log-2',
    goalId: testGoalId,
    studyDate: DateTime(2025, 1, 16),
    totalSeconds: 1800,
    createdAt: DateTime(2025, 1, 16),
  );

  final testLog3 = StudyDailyLogsModel(
    id: 'log-3',
    goalId: 'goal-2',
    studyDate: DateTime(2025, 1, 15),
    totalSeconds: 7200,
    createdAt: DateTime(2025, 1, 15),
  );

  setUpAll(() {
    registerFallbackValue(FakeStudyDailyLogsModel());
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockLocalDs = MockLocalStudyLogsDatasource();
    mockSupabaseDs = MockSupabaseStudyLogsDatasource();
    mockMigrationService = MockMigrationService();

    repository = StudyLogsRepository(
      localDs: mockLocalDs,
      supabaseDs: mockSupabaseDs,
      migrationService: mockMigrationService,
    );
  });

  group('StudyLogsRepository', () {
    group('fetchAllLogs', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllLogs(testUserId))
            .thenAnswer((_) async => [testLog1, testLog2]);

        final result = await repository.fetchAllLogs(testUserId);

        expect(result.length, 2);
        verify(() => mockSupabaseDs.fetchAllLogs(testUserId)).called(1);
        verifyNever(() => mockLocalDs.fetchAllLogs());
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchAllLogs())
            .thenAnswer((_) async => [testLog1, testLog2]);

        final result = await repository.fetchAllLogs(testUserId);

        expect(result.length, 2);
        verify(() => mockLocalDs.fetchAllLogs()).called(1);
        verifyNever(() => mockSupabaseDs.fetchAllLogs(any()));
      });
    });

    group('fetchLogsByGoalId', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchLogsByGoalId(testGoalId))
            .thenAnswer((_) async => [testLog1, testLog2]);

        final result =
            await repository.fetchLogsByGoalId(testGoalId, testUserId);

        expect(result.length, 2);
        verify(() => mockSupabaseDs.fetchLogsByGoalId(testGoalId)).called(1);
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchLogsByGoalId(testGoalId))
            .thenAnswer((_) async => [testLog1, testLog2]);

        final result =
            await repository.fetchLogsByGoalId(testGoalId, testUserId);

        expect(result.length, 2);
        verify(() => mockLocalDs.fetchLogsByGoalId(testGoalId)).called(1);
      });
    });

    group('fetchTotalSecondsForAllGoals', () {
      test('マイグレーション済みの場合はSupabaseから取得して集計する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllLogs(testUserId))
            .thenAnswer((_) async => [testLog1, testLog2, testLog3]);

        final result = await repository.fetchTotalSecondsForAllGoals(testUserId);

        expect(result[testGoalId], 5400); // 3600 + 1800
        expect(result['goal-2'], 7200);
        verify(() => mockSupabaseDs.fetchAllLogs(testUserId)).called(1);
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchTotalSecondsForAllGoals())
            .thenAnswer((_) async => {testGoalId: 5400, 'goal-2': 7200});

        final result = await repository.fetchTotalSecondsForAllGoals(testUserId);

        expect(result[testGoalId], 5400);
        expect(result['goal-2'], 7200);
        verify(() => mockLocalDs.fetchTotalSecondsForAllGoals()).called(1);
      });
    });

    group('fetchStudyDatesInRange', () {
      test('マイグレーション済みの場合はSupabaseから取得してフィルタリングする', () async {
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);

        // StreakConsts.minStudySeconds以上の記録を作成
        final logWithEnoughTime = StudyDailyLogsModel(
          id: 'log-enough',
          goalId: testGoalId,
          studyDate: DateTime(2025, 1, 15),
          totalSeconds: StreakConsts.minStudySeconds,
          createdAt: DateTime(2025, 1, 15),
        );

        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllLogs(testUserId))
            .thenAnswer((_) async => [logWithEnoughTime]);

        final result = await repository.fetchStudyDatesInRange(
          startDate: startDate,
          endDate: endDate,
          userId: testUserId,
        );

        expect(result.length, 1);
        expect(result.first, DateTime(2025, 1, 15));
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        final startDate = DateTime(2025, 1, 1);
        final endDate = DateTime(2025, 1, 31);

        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchStudyDatesInRange(
              startDate: startDate,
              endDate: endDate,
            )).thenAnswer((_) async => [DateTime(2025, 1, 15)]);

        final result = await repository.fetchStudyDatesInRange(
          startDate: startDate,
          endDate: endDate,
          userId: testUserId,
        );

        expect(result.length, 1);
        verify(() => mockLocalDs.fetchStudyDatesInRange(
              startDate: startDate,
              endDate: endDate,
            )).called(1);
      });
    });

    group('calculateCurrentStreak', () {
      test('マイグレーション未済の場合はローカルで計算する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.calculateCurrentStreak())
            .thenAnswer((_) async => 5);

        final result = await repository.calculateCurrentStreak(testUserId);

        expect(result, 5);
        verify(() => mockLocalDs.calculateCurrentStreak()).called(1);
      });
    });

    group('calculateHistoricalLongestStreak', () {
      test('マイグレーション未済の場合はローカルで計算する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.calculateHistoricalLongestStreak())
            .thenAnswer((_) async => 10);

        final result =
            await repository.calculateHistoricalLongestStreak(testUserId);

        expect(result, 10);
        verify(() => mockLocalDs.calculateHistoricalLongestStreak()).called(1);
      });
    });

    group('fetchFirstStudyDate', () {
      test('マイグレーション済みの場合はSupabaseから取得して最初の日付を返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllLogs(testUserId))
            .thenAnswer((_) async => [testLog2, testLog1]); // log2が後の日付

        final result = await repository.fetchFirstStudyDate(testUserId);

        expect(result, DateTime(2025, 1, 15)); // log1の日付
      });

      test('マイグレーション済みでログがない場合はnullを返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllLogs(testUserId))
            .thenAnswer((_) async => []);

        final result = await repository.fetchFirstStudyDate(testUserId);

        expect(result, isNull);
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchFirstStudyDate())
            .thenAnswer((_) async => DateTime(2025, 1, 15));

        final result = await repository.fetchFirstStudyDate(testUserId);

        expect(result, DateTime(2025, 1, 15));
        verify(() => mockLocalDs.fetchFirstStudyDate()).called(1);
      });
    });

    group('fetchDailyRecordsByDate', () {
      test('マイグレーション済みの場合はSupabaseから取得して日付でフィルタリングする', () async {
        final targetDate = DateTime(2025, 1, 15);

        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllLogs(testUserId))
            .thenAnswer((_) async => [testLog1, testLog2, testLog3]);

        final result =
            await repository.fetchDailyRecordsByDate(targetDate, testUserId);

        // 2025/1/15のログのみ: testLog1(3600) + testLog3(7200)
        expect(result[testGoalId], 3600);
        expect(result['goal-2'], 7200);
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        final targetDate = DateTime(2025, 1, 15);

        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchDailyRecordsByDate(targetDate))
            .thenAnswer((_) async => {testGoalId: 3600, 'goal-2': 7200});

        final result =
            await repository.fetchDailyRecordsByDate(targetDate, testUserId);

        expect(result[testGoalId], 3600);
        verify(() => mockLocalDs.fetchDailyRecordsByDate(targetDate)).called(1);
      });
    });

    group('upsertLog', () {
      test('マイグレーション済みの場合はSupabaseに保存する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.upsertLog(testLog1))
            .thenAnswer((_) async => testLog1);

        final result = await repository.upsertLog(testLog1);

        expect(result, testLog1);
        verify(() => mockSupabaseDs.upsertLog(testLog1)).called(1);
      });

      test('マイグレーション未済の場合はローカルに保存する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.saveLog(testLog1)).thenAnswer((_) async {});

        final result = await repository.upsertLog(testLog1);

        expect(result, testLog1);
        verify(() => mockLocalDs.saveLog(testLog1)).called(1);
      });
    });
  });
}
