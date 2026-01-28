import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goal_timer/core/data/local/local_study_daily_logs_datasource.dart';
import 'package:goal_timer/core/data/repositories/study_logs_repository.dart';
import 'package:goal_timer/core/data/supabase/supabase_study_logs_datasource.dart';
import 'package:goal_timer/core/models/study_daily_logs/study_daily_logs_model.dart';
import 'package:goal_timer/core/services/migration_service.dart';

// モッククラス
class MockLocalStudyLogsDatasource extends Mock
    implements LocalStudyDailyLogsDatasource {}

class MockSupabaseStudyLogsDatasource extends Mock
    implements SupabaseStudyLogsDatasource {}

class MockMigrationService extends Mock implements MigrationService {}

void main() {
  late MockLocalStudyLogsDatasource mockLocalDs;
  late MockSupabaseStudyLogsDatasource mockSupabaseDs;
  late MockMigrationService mockMigrationService;
  late StudyLogsRepository repository;

  // テスト用のモデル
  final today = DateTime.now();
  final testLog = StudyDailyLogsModel(
    id: 'log-1',
    goalId: 'goal-1',
    studyDate: DateTime(today.year, today.month, today.day),
    totalSeconds: 3600,
  );

  final testLog2 = StudyDailyLogsModel(
    id: 'log-2',
    goalId: 'goal-1',
    studyDate:
        DateTime(today.year, today.month, today.day)
            .subtract(const Duration(days: 1)),
    totalSeconds: 1800,
  );

  final testLog3 = StudyDailyLogsModel(
    id: 'log-3',
    goalId: 'goal-2',
    studyDate: DateTime(today.year, today.month, today.day),
    totalSeconds: 7200,
  );

  const testUserId = 'user-123';

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(testLog);
  });

  setUp(() {
    mockLocalDs = MockLocalStudyLogsDatasource();
    mockSupabaseDs = MockSupabaseStudyLogsDatasource();
    mockMigrationService = MockMigrationService();

    repository = StudyLogsRepository.withDependencies(
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
            .thenAnswer((_) async => [testLog, testLog2]);

        final result = await repository.fetchAllLogs(testUserId);

        expect(result.length, 2);
        verify(() => mockSupabaseDs.fetchAllLogs(testUserId)).called(1);
        verifyNever(() => mockLocalDs.fetchAllLogs());
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchAllLogs())
            .thenAnswer((_) async => [testLog, testLog2]);

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
        when(() => mockSupabaseDs.fetchLogsByGoalId('goal-1'))
            .thenAnswer((_) async => [testLog, testLog2]);

        final result = await repository.fetchLogsByGoalId('goal-1');

        expect(result.length, 2);
        verify(() => mockSupabaseDs.fetchLogsByGoalId('goal-1')).called(1);
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchLogsByGoalId('goal-1'))
            .thenAnswer((_) async => [testLog, testLog2]);

        final result = await repository.fetchLogsByGoalId('goal-1');

        expect(result.length, 2);
        verify(() => mockLocalDs.fetchLogsByGoalId('goal-1')).called(1);
      });
    });

    group('fetchTotalSecondsByGoalId', () {
      test('マイグレーション済みの場合はSupabaseから取得して計算する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchLogsByGoalId('goal-1'))
            .thenAnswer((_) async => [testLog, testLog2]);

        final result = await repository.fetchTotalSecondsByGoalId('goal-1');

        // 3600 + 1800 = 5400
        expect(result, 5400);
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchTotalSecondsByGoalId('goal-1'))
            .thenAnswer((_) async => 5400);

        final result = await repository.fetchTotalSecondsByGoalId('goal-1');

        expect(result, 5400);
        verify(() => mockLocalDs.fetchTotalSecondsByGoalId('goal-1')).called(1);
      });
    });

    group('fetchTotalSecondsForAllGoals', () {
      test('マイグレーション済みの場合はSupabaseから取得して計算する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllLogs(testUserId))
            .thenAnswer((_) async => [testLog, testLog2, testLog3]);

        final result = await repository.fetchTotalSecondsForAllGoals(testUserId);

        // goal-1: 3600 + 1800 = 5400
        // goal-2: 7200
        expect(result['goal-1'], 5400);
        expect(result['goal-2'], 7200);
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchTotalSecondsForAllGoals())
            .thenAnswer((_) async => {'goal-1': 5400, 'goal-2': 7200});

        final result = await repository.fetchTotalSecondsForAllGoals(testUserId);

        expect(result['goal-1'], 5400);
        expect(result['goal-2'], 7200);
      });
    });

    group('upsertLog', () {
      test('マイグレーション済みの場合はSupabaseに保存する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.upsertLog(testLog))
            .thenAnswer((_) async => testLog);

        final result = await repository.upsertLog(testLog);

        expect(result, testLog);
        verify(() => mockSupabaseDs.upsertLog(testLog)).called(1);
      });

      test('マイグレーション未済の場合はローカルDBに保存する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.saveLog(testLog)).thenAnswer((_) async {});

        final result = await repository.upsertLog(testLog);

        expect(result, testLog);
        verify(() => mockLocalDs.saveLog(testLog)).called(1);
      });
    });

    group('deleteLog', () {
      test('マイグレーション済みの場合はSupabaseから削除する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.deleteLog('log-1')).thenAnswer((_) async {});

        await repository.deleteLog('log-1');

        verify(() => mockSupabaseDs.deleteLog('log-1')).called(1);
      });

      test('マイグレーション未済の場合はローカルDBから削除する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.deleteLog('log-1')).thenAnswer((_) async {});

        await repository.deleteLog('log-1');

        verify(() => mockLocalDs.deleteLog('log-1')).called(1);
      });
    });

    group('deleteLogsByGoalId', () {
      test('マイグレーション済みの場合はSupabaseから削除する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.deleteLogsByGoalId('goal-1'))
            .thenAnswer((_) async {});

        await repository.deleteLogsByGoalId('goal-1');

        verify(() => mockSupabaseDs.deleteLogsByGoalId('goal-1')).called(1);
      });

      test('マイグレーション未済の場合はローカルDBから削除する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.deleteLogsByGoalId('goal-1'))
            .thenAnswer((_) async {});

        await repository.deleteLogsByGoalId('goal-1');

        verify(() => mockLocalDs.deleteLogsByGoalId('goal-1')).called(1);
      });
    });

    group('calculateCurrentStreak', () {
      test('マイグレーション未済の場合はローカルDBから計算する', () async {
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
      test('マイグレーション未済の場合はローカルDBから計算する', () async {
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

    group('fetchStudyDatesInRange', () {
      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();

        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(
          () => mockLocalDs.fetchStudyDatesInRange(
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer((_) async => [DateTime.now()]);

        final result = await repository.fetchStudyDatesInRange(
          startDate: startDate,
          endDate: endDate,
          userId: testUserId,
        );

        expect(result.length, 1);
      });
    });

    group('fetchFirstStudyDate', () {
      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        final firstDate = DateTime(2024, 1, 1);
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchFirstStudyDate())
            .thenAnswer((_) async => firstDate);

        final result = await repository.fetchFirstStudyDate(testUserId);

        expect(result, firstDate);
        verify(() => mockLocalDs.fetchFirstStudyDate()).called(1);
      });
    });

    group('fetchDailyRecordsByDate', () {
      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        final date = DateTime.now();
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchDailyRecordsByDate(date))
            .thenAnswer((_) async => {'goal-1': 3600});

        final result = await repository.fetchDailyRecordsByDate(date, testUserId);

        expect(result['goal-1'], 3600);
        verify(() => mockLocalDs.fetchDailyRecordsByDate(date)).called(1);
      });
    });
  });
}
