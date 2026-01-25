import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/database_consts.dart';
import 'package:goal_timer/core/data/local/local_users_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  late LocalUsersDatasource datasource;
  late AppDatabase database;

  setUpAll(() {
    // sqflite_ffiを初期化（テスト環境用）
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // テスト用に一意のデータベースを作成（並列実行時の競合を回避）
    final uniqueDbName = 'test_users_${DateTime.now().microsecondsSinceEpoch}.db';
    database = AppDatabase.forTesting(uniqueDbName);
    datasource = LocalUsersDatasource(database: database);

    // テストごとにusersテーブルをクリア
    final db = await database.database;
    await db.delete(DatabaseConsts.tableUsers);
  });

  tearDown(() async {
    // テスト終了時にデータベースを閉じる
    await database.close();
  });

  group('LocalUsersDatasource Tests', () {
    group('getLongestStreak', () {
      test('ユーザーが存在しない場合は0を返すこと', () async {
        // Act
        final streak = await datasource.getLongestStreak();

        // Assert
        expect(streak, equals(0));
      });

      test('ユーザーが存在する場合は最長ストリークを返すこと', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 15,
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        final streak = await datasource.getLongestStreak();

        // Assert
        expect(streak, equals(15));
      });

      test('longest_streakがnullの場合は0を返すこと', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: null,
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        final streak = await datasource.getLongestStreak();

        // Assert
        expect(streak, equals(0));
      });
    });

    group('updateLongestStreak', () {
      test('ユーザーが存在しない場合は何もしないこと', () async {
        // Act & Assert - エラーが発生しないこと
        await datasource.updateLongestStreak(10);

        final streak = await datasource.getLongestStreak();
        expect(streak, equals(0));
      });

      test('ユーザーが存在する場合は最長ストリークを更新できること', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 5,
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        await datasource.updateLongestStreak(20);

        // Assert
        final streak = await datasource.getLongestStreak();
        expect(streak, equals(20));
      });
    });

    group('updateLongestStreakIfNeeded', () {
      test('現在のストリークが最長を超えた場合に更新されること', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 5,
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        final updated = await datasource.updateLongestStreakIfNeeded(10);

        // Assert
        expect(updated, isTrue);
        final streak = await datasource.getLongestStreak();
        expect(streak, equals(10));
      });

      test('現在のストリークが最長以下の場合は更新されないこと', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 15,
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        final updated = await datasource.updateLongestStreakIfNeeded(10);

        // Assert
        expect(updated, isFalse);
        final streak = await datasource.getLongestStreak();
        expect(streak, equals(15));
      });

      test('現在のストリークが最長と同じ場合は更新されないこと', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 10,
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        final updated = await datasource.updateLongestStreakIfNeeded(10);

        // Assert
        expect(updated, isFalse);
        final streak = await datasource.getLongestStreak();
        expect(streak, equals(10));
      });

      test('ユーザーが存在しない場合はfalseを返すこと', () async {
        // Act
        final updated = await datasource.updateLongestStreakIfNeeded(10);

        // Assert
        expect(updated, isFalse);
      });
    });
  });
}
