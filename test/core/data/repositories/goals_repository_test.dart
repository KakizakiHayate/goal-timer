import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goal_timer/core/data/local/local_goals_datasource.dart';
import 'package:goal_timer/core/data/repositories/goals_repository.dart';
import 'package:goal_timer/core/data/supabase/supabase_goals_datasource.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/services/migration_service.dart';

// モッククラス
class MockLocalGoalsDatasource extends Mock implements LocalGoalsDatasource {}

class MockSupabaseGoalsDatasource extends Mock
    implements SupabaseGoalsDatasource {}

class MockMigrationService extends Mock implements MigrationService {}

void main() {
  late MockLocalGoalsDatasource mockLocalDs;
  late MockSupabaseGoalsDatasource mockSupabaseDs;
  late MockMigrationService mockMigrationService;
  late GoalsRepository repository;

  // テスト用のモデル
  final testGoal = GoalsModel(
    id: 'goal-1',
    title: 'テスト目標',
    deadline: DateTime.now().add(const Duration(days: 30)),
    avoidMessage: 'テスト回避メッセージ',
    targetMinutes: 100,
  );

  final testGoalWithExpired = GoalsModel(
    id: 'goal-2',
    title: '期限切れ目標',
    deadline: DateTime.now().subtract(const Duration(days: 1)),
    avoidMessage: 'テスト回避メッセージ',
    targetMinutes: 50,
    expiredAt: DateTime.now(),
  );

  final testGoalWithDeleted = GoalsModel(
    id: 'goal-3',
    title: '削除済み目標',
    deadline: DateTime.now().add(const Duration(days: 10)),
    avoidMessage: 'テスト回避メッセージ',
    targetMinutes: 30,
    deletedAt: DateTime.now(),
  );

  const testUserId = 'user-123';

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(testGoal);
  });

  setUp(() {
    mockLocalDs = MockLocalGoalsDatasource();
    mockSupabaseDs = MockSupabaseGoalsDatasource();
    mockMigrationService = MockMigrationService();

    repository = GoalsRepository.withDependencies(
      localDs: mockLocalDs,
      supabaseDs: mockSupabaseDs,
      migrationService: mockMigrationService,
    );
  });

  group('GoalsRepository', () {
    group('fetchAllGoals', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllGoals(testUserId))
            .thenAnswer((_) async => [testGoal]);

        final result = await repository.fetchAllGoals(testUserId);

        expect(result, [testGoal]);
        verify(() => mockSupabaseDs.fetchAllGoals(testUserId)).called(1);
        verifyNever(() => mockLocalDs.fetchAllGoals());
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchAllGoals())
            .thenAnswer((_) async => [testGoal]);

        final result = await repository.fetchAllGoals(testUserId);

        expect(result, [testGoal]);
        verify(() => mockLocalDs.fetchAllGoals()).called(1);
        verifyNever(() => mockSupabaseDs.fetchAllGoals(any()));
      });
    });

    group('fetchActiveGoals', () {
      test('マイグレーション済みの場合はSupabaseから取得してフィルタリングする', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllGoals(testUserId)).thenAnswer(
          (_) async => [testGoal, testGoalWithExpired, testGoalWithDeleted],
        );

        final result = await repository.fetchActiveGoals(testUserId);

        expect(result.length, 1);
        expect(result.first.id, 'goal-1');
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchActiveGoals())
            .thenAnswer((_) async => [testGoal]);

        final result = await repository.fetchActiveGoals(testUserId);

        expect(result, [testGoal]);
        verify(() => mockLocalDs.fetchActiveGoals()).called(1);
      });
    });

    group('fetchGoalById', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchGoalById('goal-1'))
            .thenAnswer((_) async => testGoal);

        final result = await repository.fetchGoalById('goal-1', testUserId);

        expect(result, testGoal);
        verify(() => mockSupabaseDs.fetchGoalById('goal-1')).called(1);
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchGoalById('goal-1'))
            .thenAnswer((_) async => testGoal);

        final result = await repository.fetchGoalById('goal-1', testUserId);

        expect(result, testGoal);
        verify(() => mockLocalDs.fetchGoalById('goal-1')).called(1);
      });
    });

    group('upsertGoal', () {
      test('マイグレーション済みの場合はSupabaseに保存する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.upsertGoal(testGoal))
            .thenAnswer((_) async => testGoal);

        final result = await repository.upsertGoal(testGoal);

        expect(result, testGoal);
        verify(() => mockSupabaseDs.upsertGoal(testGoal)).called(1);
      });

      test('マイグレーション未済の場合はローカルDBに保存する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.saveGoal(testGoal)).thenAnswer((_) async {});

        final result = await repository.upsertGoal(testGoal);

        expect(result, testGoal);
        verify(() => mockLocalDs.saveGoal(testGoal)).called(1);
      });
    });

    group('updateGoal', () {
      test('マイグレーション済みの場合はSupabaseを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.upsertGoal(testGoal))
            .thenAnswer((_) async => testGoal);

        final result = await repository.updateGoal(testGoal);

        expect(result, testGoal);
        verify(() => mockSupabaseDs.upsertGoal(testGoal)).called(1);
      });

      test('マイグレーション未済の場合はローカルDBを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateGoal(testGoal)).thenAnswer((_) async {});

        final result = await repository.updateGoal(testGoal);

        expect(result, testGoal);
        verify(() => mockLocalDs.updateGoal(testGoal)).called(1);
      });
    });

    group('deleteGoal', () {
      test('マイグレーション済みの場合はSupabaseから削除する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.deleteGoal('goal-1'))
            .thenAnswer((_) async {});

        await repository.deleteGoal('goal-1');

        verify(() => mockSupabaseDs.deleteGoal('goal-1')).called(1);
      });

      test('マイグレーション未済の場合はローカルDBから削除する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.deleteGoal('goal-1')).thenAnswer((_) async {});

        await repository.deleteGoal('goal-1');

        verify(() => mockLocalDs.deleteGoal('goal-1')).called(1);
      });
    });

    group('updateExpiredGoals', () {
      test('マイグレーション未済の場合はローカルDBを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateExpiredGoals()).thenAnswer((_) async {});

        await repository.updateExpiredGoals(testUserId);

        verify(() => mockLocalDs.updateExpiredGoals()).called(1);
      });
    });

    group('populateMissingTotalTargetMinutes', () {
      test('マイグレーション未済の場合はローカルDBを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.populateMissingTotalTargetMinutes())
            .thenAnswer((_) async {});

        await repository.populateMissingTotalTargetMinutes(testUserId);

        verify(() => mockLocalDs.populateMissingTotalTargetMinutes()).called(1);
      });
    });

    group('fetchAllGoalsIncludingDeleted', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllGoalsIncludingDeleted(testUserId))
            .thenAnswer(
          (_) async => [testGoal, testGoalWithDeleted],
        );

        final result =
            await repository.fetchAllGoalsIncludingDeleted(testUserId);

        expect(result.length, 2);
        verify(() => mockSupabaseDs.fetchAllGoalsIncludingDeleted(testUserId))
            .called(1);
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testGoal, testGoalWithDeleted]);

        final result =
            await repository.fetchAllGoalsIncludingDeleted(testUserId);

        expect(result.length, 2);
        verify(() => mockLocalDs.fetchAllGoalsIncludingDeleted()).called(1);
      });
    });
  });
}
