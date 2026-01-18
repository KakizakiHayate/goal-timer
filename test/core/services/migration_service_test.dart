import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goal_timer/core/data/local/local_goals_datasource.dart';
import 'package:goal_timer/core/data/local/local_study_daily_logs_datasource.dart';
import 'package:goal_timer/core/data/supabase/supabase_goals_datasource.dart';
import 'package:goal_timer/core/data/supabase/supabase_study_logs_datasource.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/models/study_daily_logs/study_daily_logs_model.dart';
import 'package:goal_timer/core/services/migration_service.dart';

// モッククラス
class MockLocalGoalsDatasource extends Mock implements LocalGoalsDatasource {}

class MockLocalStudyLogsDatasource extends Mock
    implements LocalStudyDailyLogsDatasource {}

class MockSupabaseGoalsDatasource extends Mock
    implements SupabaseGoalsDatasource {}

class MockSupabaseStudyLogsDatasource extends Mock
    implements SupabaseStudyLogsDatasource {}

void main() {
  late MockLocalGoalsDatasource mockLocalGoals;
  late MockLocalStudyLogsDatasource mockLocalStudyLogs;
  late MockSupabaseGoalsDatasource mockSupabaseGoals;
  late MockSupabaseStudyLogsDatasource mockSupabaseStudyLogs;
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
    mockSupabaseGoals = MockSupabaseGoalsDatasource();
    mockSupabaseStudyLogs = MockSupabaseStudyLogsDatasource();

    migrationService = MigrationService(
      localGoalsDatasource: mockLocalGoals,
      localStudyLogsDatasource: mockLocalStudyLogs,
      supabaseGoalsDatasource: mockSupabaseGoals,
      supabaseStudyLogsDatasource: mockSupabaseStudyLogs,
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
      test('ローカルデータがない場合はfalseを返す', () async {
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => []);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => []);

        final result = await migrationService.hasLocalData();

        expect(result, isFalse);
      });

      test('目標がある場合はtrueを返す', () async {
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testGoal]);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => []);

        final result = await migrationService.hasLocalData();

        expect(result, isTrue);
      });

      test('学習ログがある場合はtrueを返す', () async {
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => []);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => [testLog]);

        final result = await migrationService.hasLocalData();

        expect(result, isTrue);
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
      test('既に移行済みの場合はスキップする', () async {
        SharedPreferences.setMockInitialValues({
          'has_migrated_to_supabase': true,
        });

        final result = await migrationService.migrate('user-123');

        expect(result.success, isTrue);
        expect(result.skipped, isTrue);
        expect(result.message, '既に移行済みです');
      });

      test('ローカルデータがない場合はスキップする', () async {
        SharedPreferences.setMockInitialValues({});
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => []);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => []);

        final result = await migrationService.migrate('user-123');

        expect(result.success, isTrue);
        expect(result.skipped, isTrue);
        expect(result.message, 'ローカルデータがありません');
      });

      test('目標と学習ログを正常に移行する', () async {
        SharedPreferences.setMockInitialValues({});

        // hasLocalDataのためのモック設定
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testGoal]);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => [testLog]);

        // 移行処理のモック設定
        when(() => mockSupabaseGoals.insertGoals(any()))
            .thenAnswer((_) async {});
        when(() => mockSupabaseStudyLogs.insertLogs(any()))
            .thenAnswer((_) async {});

        final result = await migrationService.migrate('user-123');

        expect(result.success, isTrue);
        expect(result.skipped, isFalse);
        expect(result.goalCount, 1);
        expect(result.studyLogCount, 1);

        // Supabaseへの挿入が呼ばれたことを確認
        verify(() => mockSupabaseGoals.insertGoals(any())).called(1);
        verify(() => mockSupabaseStudyLogs.insertLogs(any())).called(1);
      });

      test('移行後は移行済みフラグが設定される', () async {
        SharedPreferences.setMockInitialValues({});
        when(() => mockLocalGoals.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testGoal]);
        when(() => mockLocalStudyLogs.fetchAllLogs())
            .thenAnswer((_) async => [testLog]);
        when(() => mockSupabaseGoals.insertGoals(any()))
            .thenAnswer((_) async {});
        when(() => mockSupabaseStudyLogs.insertLogs(any()))
            .thenAnswer((_) async {});

        await migrationService.migrate('user-123');

        // 移行後は移行済みと判定される
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_migrated_to_supabase'), isTrue);
      });
    });

    group('resetMigration', () {
      test('移行フラグをリセットする', () async {
        SharedPreferences.setMockInitialValues({
          'has_migrated_to_supabase': true,
        });

        await migrationService.resetMigration();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('has_migrated_to_supabase'), isNull);
      });
    });
  });
}
