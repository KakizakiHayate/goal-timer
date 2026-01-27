import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goal_timer/core/data/local/local_users_datasource.dart';
import 'package:goal_timer/core/data/repositories/users_repository.dart';
import 'package:goal_timer/core/data/supabase/supabase_users_datasource.dart';
import 'package:goal_timer/core/models/users/users_model.dart';
import 'package:goal_timer/core/services/migration_service.dart';
import 'package:goal_timer/core/utils/streak_reminder_consts.dart';
import 'package:goal_timer/core/utils/user_consts.dart';

// モッククラス
class MockLocalUsersDatasource extends Mock implements LocalUsersDatasource {}

class MockSupabaseUsersDatasource extends Mock
    implements SupabaseUsersDatasource {}

class MockMigrationService extends Mock implements MigrationService {}

void main() {
  late MockLocalUsersDatasource mockLocalDs;
  late MockSupabaseUsersDatasource mockSupabaseDs;
  late MockMigrationService mockMigrationService;
  late UsersRepository repository;

  // テスト用のモデル
  final testUser = UsersModel(
    id: 'user-123',
    displayName: 'テストユーザー',
    createdAt: DateTime.now(),
  );

  const testUserId = 'user-123';

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(testUser);
  });

  setUp(() {
    mockLocalDs = MockLocalUsersDatasource();
    mockSupabaseDs = MockSupabaseUsersDatasource();
    mockMigrationService = MockMigrationService();

    repository = UsersRepository.withDependencies(
      localDs: mockLocalDs,
      supabaseDs: mockSupabaseDs,
      migrationService: mockMigrationService,
    );
  });

  group('UsersRepository', () {
    group('getLongestStreak', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.getLongestStreak(testUserId))
            .thenAnswer((_) async => 10);

        final result = await repository.getLongestStreak(testUserId);

        expect(result, 10);
        verify(() => mockSupabaseDs.getLongestStreak(testUserId)).called(1);
        verifyNever(() => mockLocalDs.getLongestStreak());
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.getLongestStreak()).thenAnswer((_) async => 5);

        final result = await repository.getLongestStreak(testUserId);

        expect(result, 5);
        verify(() => mockLocalDs.getLongestStreak()).called(1);
        verifyNever(() => mockSupabaseDs.getLongestStreak(any()));
      });
    });

    group('updateLongestStreak', () {
      test('マイグレーション済みの場合はSupabaseを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.updateLongestStreak(testUserId, 15))
            .thenAnswer((_) async {});

        await repository.updateLongestStreak(15, testUserId);

        verify(() => mockSupabaseDs.updateLongestStreak(testUserId, 15))
            .called(1);
      });

      test('マイグレーション未済の場合はローカルDBを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateLongestStreak(15))
            .thenAnswer((_) async {});

        await repository.updateLongestStreak(15, testUserId);

        verify(() => mockLocalDs.updateLongestStreak(15)).called(1);
      });
    });

    group('updateLongestStreakIfNeeded', () {
      test('マイグレーション済みで現在のストリークが最長を超えた場合はtrueを返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.getLongestStreak(testUserId))
            .thenAnswer((_) async => 10);
        when(() => mockSupabaseDs.updateLongestStreak(testUserId, 15))
            .thenAnswer((_) async {});

        final result =
            await repository.updateLongestStreakIfNeeded(15, testUserId);

        expect(result, isTrue);
        verify(() => mockSupabaseDs.updateLongestStreak(testUserId, 15))
            .called(1);
      });

      test('マイグレーション済みで現在のストリークが最長以下の場合はfalseを返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.getLongestStreak(testUserId))
            .thenAnswer((_) async => 10);

        final result =
            await repository.updateLongestStreakIfNeeded(5, testUserId);

        expect(result, isFalse);
        verifyNever(() => mockSupabaseDs.updateLongestStreak(any(), any()));
      });

      test('マイグレーション未済の場合はローカルDBで判定する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateLongestStreakIfNeeded(15))
            .thenAnswer((_) async => true);

        final result =
            await repository.updateLongestStreakIfNeeded(15, testUserId);

        expect(result, isTrue);
        verify(() => mockLocalDs.updateLongestStreakIfNeeded(15)).called(1);
      });
    });

    group('getStreakReminderEnabled', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.getStreakReminderEnabled(testUserId))
            .thenAnswer((_) async => true);

        final result = await repository.getStreakReminderEnabled(testUserId);

        expect(result, isTrue);
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.getStreakReminderEnabled())
            .thenAnswer((_) async => false);

        final result = await repository.getStreakReminderEnabled(testUserId);

        expect(result, isFalse);
      });
    });

    group('updateStreakReminderEnabled', () {
      test('マイグレーション済みの場合はSupabaseを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.updateStreakReminderEnabled(testUserId, false))
            .thenAnswer((_) async {});

        await repository.updateStreakReminderEnabled(false, testUserId);

        verify(() =>
                mockSupabaseDs.updateStreakReminderEnabled(testUserId, false))
            .called(1);
      });

      test('マイグレーション未済の場合はローカルDBを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateStreakReminderEnabled(false))
            .thenAnswer((_) async {});

        await repository.updateStreakReminderEnabled(false, testUserId);

        verify(() => mockLocalDs.updateStreakReminderEnabled(false)).called(1);
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
      });

      test('マイグレーション済みで名前がnullの場合はデフォルト値を返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.getDisplayName(testUserId))
            .thenAnswer((_) async => null);

        final result = await repository.getDisplayName(testUserId);

        expect(result, UserConsts.defaultGuestName);
      });

      test('マイグレーション未済の場合はローカルDBから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.getDisplayName())
            .thenAnswer((_) async => 'ローカルユーザー');

        final result = await repository.getDisplayName(testUserId);

        expect(result, 'ローカルユーザー');
      });
    });

    group('updateDisplayName', () {
      test('マイグレーション済みの場合はSupabaseを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.updateDisplayName(testUserId, '新しい名前'))
            .thenAnswer((_) async {});

        await repository.updateDisplayName('新しい名前', testUserId);

        verify(() => mockSupabaseDs.updateDisplayName(testUserId, '新しい名前'))
            .called(1);
      });

      test('マイグレーション未済の場合はローカルDBを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);
        when(() => mockLocalDs.updateDisplayName('新しい名前'))
            .thenAnswer((_) async {});

        await repository.updateDisplayName('新しい名前', testUserId);

        verify(() => mockLocalDs.updateDisplayName('新しい名前')).called(1);
      });
    });

    group('resetDisplayName', () {
      test('常にローカルDBをリセットする', () async {
        when(() => mockLocalDs.resetDisplayName()).thenAnswer((_) async {});

        await repository.resetDisplayName();

        verify(() => mockLocalDs.resetDisplayName()).called(1);
      });
    });

    group('fetchUser', () {
      test('マイグレーション済みの場合はSupabaseから取得する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.fetchUser(testUserId))
            .thenAnswer((_) async => testUser);

        final result = await repository.fetchUser(testUserId);

        expect(result, testUser);
      });

      test('マイグレーション未済の場合はnullを返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);

        final result = await repository.fetchUser(testUserId);

        expect(result, isNull);
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

      test('マイグレーション未済の場合はnullを返す', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);

        final result = await repository.upsertUser(testUser);

        expect(result, isNull);
      });
    });

    group('updateLastLogin', () {
      test('マイグレーション済みの場合はSupabaseを更新する', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => true);
        when(() => mockSupabaseDs.updateLastLogin(testUserId))
            .thenAnswer((_) async {});

        await repository.updateLastLogin(testUserId);

        verify(() => mockSupabaseDs.updateLastLogin(testUserId)).called(1);
      });

      test('マイグレーション未済の場合は何もしない', () async {
        when(() => mockMigrationService.isMigrated())
            .thenAnswer((_) async => false);

        await repository.updateLastLogin(testUserId);

        verifyNever(() => mockSupabaseDs.updateLastLogin(any()));
      });
    });
  });
}
