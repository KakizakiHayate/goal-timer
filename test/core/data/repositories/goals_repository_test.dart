import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/local_goals_datasource.dart';
import 'package:goal_timer/core/data/repositories/goals_repository.dart';
import 'package:goal_timer/core/data/supabase/supabase_goals_datasource.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/services/migration_service.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalGoalsDatasource extends Mock implements LocalGoalsDatasource {}

class MockSupabaseGoalsDatasource extends Mock
    implements SupabaseGoalsDatasource {}

class MockMigrationService extends Mock implements MigrationService {}

class FakeGoalsModel extends Fake implements GoalsModel {}

void main() {
  late MockLocalGoalsDatasource mockLocalDs;
  late MockSupabaseGoalsDatasource mockSupabaseDs;
  late MockMigrationService mockMigrationService;
  late GoalsRepository repository;

  final testUserId = 'test-user-id';

  final testGoal = GoalsModel(
    id: 'goal-1',
    userId: testUserId,
    title: 'テスト目標',
    description: 'テスト説明',
    deadline: DateTime(2025, 12, 31),
    avoidMessage: 'テスト回避メッセージ',
    targetMinutes: 100,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final testGoal2 = GoalsModel(
    id: 'goal-2',
    userId: testUserId,
    title: 'テスト目標2',
    description: 'テスト説明2',
    deadline: DateTime(2025, 12, 31),
    avoidMessage: 'テスト回避メッセージ2',
    targetMinutes: 200,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final deletedGoal = GoalsModel(
    id: 'goal-3',
    userId: testUserId,
    title: '削除済み目標',
    description: 'テスト説明3',
    deadline: DateTime(2025, 12, 31),
    avoidMessage: 'テスト回避メッセージ3',
    targetMinutes: 300,
    deletedAt: DateTime(2025, 1, 15),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final expiredGoal = GoalsModel(
    id: 'goal-4',
    userId: testUserId,
    title: '期限切れ目標',
    description: 'テスト説明4',
    deadline: DateTime(2025, 12, 31),
    avoidMessage: 'テスト回避メッセージ4',
    targetMinutes: 400,
    expiredAt: DateTime(2025, 1, 1),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeGoalsModel());
  });

  setUp(() {
    mockLocalDs = MockLocalGoalsDatasource();
    mockSupabaseDs = MockSupabaseGoalsDatasource();
    mockMigrationService = MockMigrationService();

    repository = GoalsRepository(
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
            .thenAnswer((_) async => [testGoal, testGoal2]);

        final result = await repository.fetchAllGoals(testUserId);

        expect(result.length, 2);
        verify(() => mockSupabaseDs.fetchAllGoals(testUserId)).called(1);
        verifyNever(() => mockLocalDs.fetchAllGoals());
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchAllGoals())
            .thenAnswer((_) async => [testGoal, testGoal2]);

        final result = await repository.fetchAllGoals(testUserId);

        expect(result.length, 2);
        verify(() => mockLocalDs.fetchAllGoals()).called(1);
        verifyNever(() => mockSupabaseDs.fetchAllGoals(any()));
      });
    });

    group('fetchActiveGoals', () {
      test('マイグレーション済みの場合はSupabaseから取得してフィルタリングする', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchAllGoals(testUserId))
            .thenAnswer((_) async => [testGoal, deletedGoal, expiredGoal]);

        final result = await repository.fetchActiveGoals(testUserId);

        expect(result.length, 1);
        expect(result.first.id, testGoal.id);
        verify(() => mockSupabaseDs.fetchAllGoals(testUserId)).called(1);
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchActiveGoals())
            .thenAnswer((_) async => [testGoal]);

        final result = await repository.fetchActiveGoals(testUserId);

        expect(result.length, 1);
        verify(() => mockLocalDs.fetchActiveGoals()).called(1);
      });
    });

    group('fetchGoalById', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchGoalById(testGoal.id))
            .thenAnswer((_) async => testGoal);

        final result = await repository.fetchGoalById(testGoal.id, testUserId);

        expect(result, testGoal);
        verify(() => mockSupabaseDs.fetchGoalById(testGoal.id)).called(1);
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchGoalById(testGoal.id))
            .thenAnswer((_) async => testGoal);

        final result = await repository.fetchGoalById(testGoal.id, testUserId);

        expect(result, testGoal);
        verify(() => mockLocalDs.fetchGoalById(testGoal.id)).called(1);
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

      test('マイグレーション未済で新規の場合はローカルに保存する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchGoalById(testGoal.id))
            .thenAnswer((_) async => null);
        when(() => mockLocalDs.saveGoal(testGoal)).thenAnswer((_) async {});

        final result = await repository.upsertGoal(testGoal);

        expect(result, testGoal);
        verify(() => mockLocalDs.saveGoal(testGoal)).called(1);
        verifyNever(() => mockLocalDs.updateGoal(any()));
      });

      test('マイグレーション未済で既存の場合はローカルを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.fetchGoalById(testGoal.id))
            .thenAnswer((_) async => testGoal);
        when(() => mockLocalDs.updateGoal(testGoal)).thenAnswer((_) async {});

        final result = await repository.upsertGoal(testGoal);

        expect(result, testGoal);
        verify(() => mockLocalDs.updateGoal(testGoal)).called(1);
        verifyNever(() => mockLocalDs.saveGoal(any()));
      });
    });

    group('deleteGoal', () {
      test('マイグレーション済みの場合はSupabaseから削除する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.deleteGoal(testGoal.id))
            .thenAnswer((_) async {});

        await repository.deleteGoal(testGoal.id);

        verify(() => mockSupabaseDs.deleteGoal(testGoal.id)).called(1);
        verifyNever(() => mockLocalDs.deleteGoal(any()));
      });

      test('マイグレーション未済の場合はローカルから削除する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.deleteGoal(testGoal.id))
            .thenAnswer((_) async {});

        await repository.deleteGoal(testGoal.id);

        verify(() => mockLocalDs.deleteGoal(testGoal.id)).called(1);
        verifyNever(() => mockSupabaseDs.deleteGoal(any()));
      });
    });

    group('updateExpiredGoals', () {
      test('マイグレーション未済の場合はローカルで更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateExpiredGoals()).thenAnswer((_) async {});

        await repository.updateExpiredGoals(testUserId);

        verify(() => mockLocalDs.updateExpiredGoals()).called(1);
        verifyNever(() => mockSupabaseDs.fetchAllGoals(any()));
      });
    });

    group('populateMissingTotalTargetMinutes', () {
      test('マイグレーション未済の場合はローカルで更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.populateMissingTotalTargetMinutes())
            .thenAnswer((_) async {});

        await repository.populateMissingTotalTargetMinutes(testUserId);

        verify(() => mockLocalDs.populateMissingTotalTargetMinutes()).called(1);
        verifyNever(() => mockSupabaseDs.fetchAllGoals(any()));
      });
    });
  });
}
