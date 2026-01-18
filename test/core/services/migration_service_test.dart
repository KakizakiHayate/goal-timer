import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goal_timer/core/data/local/local_goals_datasource.dart';
import 'package:goal_timer/core/data/local/local_study_daily_logs_datasource.dart';
import 'package:goal_timer/core/data/local/local_users_datasource.dart';
import 'package:goal_timer/core/data/supabase/supabase_goals_datasource.dart';
import 'package:goal_timer/core/data/supabase/supabase_study_logs_datasource.dart';
import 'package:goal_timer/core/data/supabase/supabase_users_datasource.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/models/study_daily_logs/study_daily_logs_model.dart';
import 'package:goal_timer/core/services/migration_service.dart';

// モッククラス
class MockLocalGoalsDatasource extends Mock implements LocalGoalsDatasource {}

class MockLocalStudyLogsDatasource extends Mock
    implements LocalStudyDailyLogsDatasource {}

class MockLocalUsersDatasource extends Mock implements LocalUsersDatasource {}

class MockSupabaseGoalsDatasource extends Mock
    implements SupabaseGoalsDatasource {}

class MockSupabaseStudyLogsDatasource extends Mock
    implements SupabaseStudyLogsDatasource {}

class MockSupabaseUsersDatasource extends Mock
    implements SupabaseUsersDatasource {}

void main() {
  late MockLocalGoalsDatasource mockLocalGoals;
  late MockLocalStudyLogsDatasource mockLocalStudyLogs;
  late MockLocalUsersDatasource mockLocalUsers;
  late MockSupabaseGoalsDatasource mockSupabaseGoals;
  late MockSupabaseStudyLogsDatasource mockSupabaseStudyLogs;
  late MockSupabaseUsersDatasource mockSupabaseUsers;
  late MigrationService migrationService;

  // テスト用のモデル
  final testGoal = GoalsModel(
    id: 'goal-1',
    title: 'テスト目標',
    deadline: DateTime.now().add(const Duration(days: 30)),
    avoidMessage: 'テスト回避メッセージ',
    targetMinutes: 100,
  );

  final testLog = StudyDailyLogsModel(
    id: 'log-1',
    goalId: 'goal-1',
    studyDate: DateTime.now(),
    totalSeconds: 3600,
  );

  setUpAll(() {
    // SharedPreferencesのモック
    SharedPreferences.setMockInitialValues({});

    // registerFallbackValueを使用してモック引数を登録
    registerFallbackValue(<GoalsModel>[]);
    registerFallbackValue(<StudyDailyLogsModel>[]);
  });

  setUp(() {
    mockLocalGoals = MockLocalGoalsDatasource();
    mockLocalStudyLogs = MockLocalStudyLogsDatasource();
    mockLocalUsers = MockLocalUsersDatasource();
    mockSupabaseGoals = MockSupabaseGoalsDatasource();
    mockSupabaseStudyLogs = MockSupabaseStudyLogsDatasource();
    mockSupabaseUsers = MockSupabaseUsersDatasource();

    migrationService = MigrationService(
      localGoalsDatasource: mockLocalGoals,
      localStudyLogsDatasource: mockLocalStudyLogs,
      localUsersDatasource: mockLocalUsers,
      supabaseGoalsDatasource: mockSupabaseGoals,
      supabaseStudyLogsDatasource: mockSupabaseStudyLogs,
      supabaseUsersDatasource: mockSupabaseUsers,
    );
  });

  group('MigrationService', () {
    group('hasMigrated', () {
      test('移行前はfalseを返す', () async {
        SharedPreferences.setMockInitialValues({});
        final result = await migrationService.hasMigrated();
        expect(result, isFalse);
      });

      test('移行後はtrueを返す', () async {
        SharedPreferences.setMockInitialValues({
          'has_migrated_to_supabase': true,
        });
        final result = await migrationService.hasMigrated();
        expect(result, isTrue);
      });
    });

    group('hasLocalData', () {
      test('ローカルデータがある場合はtrueを返す', () async {
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testGoal]);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => []);

        final result = await migrationService.hasLocalData();
        expect(result, isTrue);
      });

      test('ローカルデータがない場合はfalseを返す', () async {
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => []);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => []);

        final result = await migrationService.hasLocalData();
        expect(result, isFalse);
      });
    });

    group('getDataCount', () {
      test('正しいデータ件数を返す', () async {
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testGoal, testGoal]);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => [testLog]);

        final result = await migrationService.getDataCount();

        expect(result.goalCount, 2);
        expect(result.studyLogCount, 1);
        expect(result.hasData, isTrue);
      });

      test('データがない場合は0を返す', () async {
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => []);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => []);

        final result = await migrationService.getDataCount();

        expect(result.goalCount, 0);
        expect(result.studyLogCount, 0);
        expect(result.hasData, isFalse);
      });
    });

    group('migrate', () {
      test('移行済みの場合はスキップされる', () async {
        SharedPreferences.setMockInitialValues({
          'has_migrated_to_supabase': true,
        });

        final result = await migrationService.migrate('user-id');

        expect(result.success, isTrue);
        expect(result.skipped, isTrue);
        verifyNever(() => mockLocalGoals.fetchAllGoalsIncludingDeleted());
      });

      test('ローカルデータがない場合はスキップされる', () async {
        SharedPreferences.setMockInitialValues({});
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => []);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => []);

        final result = await migrationService.migrate('user-id');

        expect(result.success, isTrue);
        expect(result.skipped, isTrue);
      });

      test('ローカルデータがSupabaseに移行される', () async {
        SharedPreferences.setMockInitialValues({});
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testGoal]);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => [testLog]);
        when(() => mockSupabaseGoals.insertGoals(any()))
            .thenAnswer((_) async {});
        when(() => mockSupabaseStudyLogs.insertLogs(any()))
            .thenAnswer((_) async {});

        final result = await migrationService.migrate('user-id');

        expect(result.success, isTrue);
        expect(result.skipped, isFalse);
        expect(result.goalCount, 1);
        expect(result.studyLogCount, 1);

        verify(() => mockSupabaseGoals.insertGoals(any())).called(1);
        verify(() => mockSupabaseStudyLogs.insertLogs(any())).called(1);
      });

      test('移行失敗時は例外情報を含むResultを返す', () async {
        SharedPreferences.setMockInitialValues({});
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testGoal]);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => [testLog]);
        when(() => mockSupabaseGoals.insertGoals(any()))
            .thenThrow(Exception('Supabase error'));

        final result = await migrationService.migrate('user-id');

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });
    });

    group('resetMigration', () {
      test('移行フラグがリセットされる', () async {
        SharedPreferences.setMockInitialValues({
          'has_migrated_to_supabase': true,
        });

        await migrationService.resetMigration();

        final hasMigrated = await migrationService.hasMigrated();
        expect(hasMigrated, isFalse);
      });
    });
  });
}
