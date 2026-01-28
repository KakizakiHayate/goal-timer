import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/local_users_datasource.dart';
import 'package:goal_timer/core/data/repositories/users_repository.dart';
import 'package:goal_timer/core/data/supabase/supabase_users_datasource.dart';
import 'package:goal_timer/core/models/users/users_model.dart';
import 'package:goal_timer/core/services/migration_service.dart';
import 'package:goal_timer/core/utils/user_consts.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalUsersDatasource extends Mock implements LocalUsersDatasource {}

class MockSupabaseUsersDatasource extends Mock
    implements SupabaseUsersDatasource {}

class MockMigrationService extends Mock implements MigrationService {}

class FakeUsersModel extends Fake implements UsersModel {}

void main() {
  late MockLocalUsersDatasource mockLocalDs;
  late MockSupabaseUsersDatasource mockSupabaseDs;
  late MockMigrationService mockMigrationService;
  late UsersRepository repository;

  final testUserId = 'test-user-id';

  final testUser = UsersModel(
    id: testUserId,
    displayName: 'テストユーザー',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeUsersModel());
  });

  setUp(() {
    mockLocalDs = MockLocalUsersDatasource();
    mockSupabaseDs = MockSupabaseUsersDatasource();
    mockMigrationService = MockMigrationService();

    repository = UsersRepository(
      localDs: mockLocalDs,
      supabaseDs: mockSupabaseDs,
      migrationService: mockMigrationService,
    );
  });

  group('UsersRepository', () {
    group('fetchUser', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchUser(testUserId))
            .thenAnswer((_) async => testUser);

        final result = await repository.fetchUser(testUserId);

        expect(result, testUser);
        verify(() => mockSupabaseDs.fetchUser(testUserId)).called(1);
      });

      test('マイグレーション未済の場合はnullを返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);

        final result = await repository.fetchUser(testUserId);

        expect(result, isNull);
        verifyNever(() => mockSupabaseDs.fetchUser(any()));
      });
    });

    group('upsertUser', () {
      test('マイグレーション済みの場合はSupabaseに保存する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.upsertUser(testUser))
            .thenAnswer((_) async => testUser);

        final result = await repository.upsertUser(testUser);

        expect(result, testUser);
        verify(() => mockSupabaseDs.upsertUser(testUser)).called(1);
      });

      test('マイグレーション未済でdisplayNameがある場合はローカルに保存する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateDisplayName('テストユーザー'))
            .thenAnswer((_) async {});

        final result = await repository.upsertUser(testUser);

        expect(result, testUser);
        verify(() => mockLocalDs.updateDisplayName('テストユーザー')).called(1);
      });

      test('マイグレーション未済でdisplayNameがnullの場合は保存しない', () async {
        final userWithoutName = UsersModel(
          id: testUserId,
          displayName: null,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);

        final result = await repository.upsertUser(userWithoutName);

        expect(result, userWithoutName);
        verifyNever(() => mockLocalDs.updateDisplayName(any()));
      });

      test('マイグレーション未済でdisplayNameが空の場合は保存しない', () async {
        final userWithEmptyName = UsersModel(
          id: testUserId,
          displayName: '',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);

        final result = await repository.upsertUser(userWithEmptyName);

        expect(result, userWithEmptyName);
        verifyNever(() => mockLocalDs.updateDisplayName(any()));
      });
    });

    group('getDisplayName', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.getDisplayName(testUserId))
            .thenAnswer((_) async => 'テストユーザー');

        final result = await repository.getDisplayName(testUserId);

        expect(result, 'テストユーザー');
        verify(() => mockSupabaseDs.getDisplayName(testUserId)).called(1);
      });

      test('マイグレーション済みでdisplayNameがnullの場合はデフォルト名を返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.getDisplayName(testUserId))
            .thenAnswer((_) async => null);

        final result = await repository.getDisplayName(testUserId);

        expect(result, UserConsts.defaultGuestName);
      });

      test('マイグレーション済みでdisplayNameが空の場合はデフォルト名を返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.getDisplayName(testUserId))
            .thenAnswer((_) async => '');

        final result = await repository.getDisplayName(testUserId);

        expect(result, UserConsts.defaultGuestName);
      });

      test('マイグレーション未済の場合はローカルから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.getDisplayName())
            .thenAnswer((_) async => 'ローカルユーザー');

        final result = await repository.getDisplayName(testUserId);

        expect(result, 'ローカルユーザー');
        verify(() => mockLocalDs.getDisplayName()).called(1);
      });
    });

    group('updateDisplayName', () {
      test('マイグレーション済みの場合はSupabaseを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.updateDisplayName(testUserId, '新しい名前'))
            .thenAnswer((_) async {});

        await repository.updateDisplayName(testUserId, '新しい名前');

        verify(() => mockSupabaseDs.updateDisplayName(testUserId, '新しい名前'))
            .called(1);
        verifyNever(() => mockLocalDs.updateDisplayName(any()));
      });

      test('マイグレーション未済の場合はローカルを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateDisplayName('新しい名前'))
            .thenAnswer((_) async {});

        await repository.updateDisplayName(testUserId, '新しい名前');

        verify(() => mockLocalDs.updateDisplayName('新しい名前')).called(1);
        verifyNever(() => mockSupabaseDs.updateDisplayName(any(), any()));
      });
    });

    group('updateLongestStreak', () {
      test('マイグレーション済みの場合はSupabaseを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.updateLongestStreak(testUserId, 15))
            .thenAnswer((_) async {});

        await repository.updateLongestStreak(testUserId, 15);

        verify(() => mockSupabaseDs.updateLongestStreak(testUserId, 15))
            .called(1);
        verifyNever(() => mockLocalDs.updateLongestStreak(any()));
      });

      test('マイグレーション未済の場合はローカルを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateLongestStreak(15))
            .thenAnswer((_) async {});

        await repository.updateLongestStreak(testUserId, 15);

        verify(() => mockLocalDs.updateLongestStreak(15)).called(1);
        verifyNever(() => mockSupabaseDs.updateLongestStreak(any(), any()));
      });
    });
  });
}
