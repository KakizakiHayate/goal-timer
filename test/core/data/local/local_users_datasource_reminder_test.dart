import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/database_consts.dart';
import 'package:goal_timer/core/data/local/local_users_datasource.dart';
import 'package:goal_timer/core/utils/streak_reminder_consts.dart';
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
    final uniqueDbName = 'test_users_reminder_${DateTime.now().microsecondsSinceEpoch}.db';
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

  group('LocalUsersDatasource Streak Reminder Tests', () {
    group('getStreakReminderEnabled', () {
      test('ユーザーが存在しない場合はデフォルト値（true）を返すこと', () async {
        // Act
        final enabled = await datasource.getStreakReminderEnabled();

        // Assert
        expect(enabled, equals(StreakReminderConsts.defaultReminderEnabled));
      });

      test('ユーザーが存在し、リマインダーがONの場合はtrueを返すこと', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 0,
          DatabaseConsts.columnStreakReminderEnabled: 1, // true
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        final enabled = await datasource.getStreakReminderEnabled();

        // Assert
        expect(enabled, isTrue);
      });

      test('ユーザーが存在し、リマインダーがOFFの場合はfalseを返すこと', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 0,
          DatabaseConsts.columnStreakReminderEnabled: 0, // false
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        final enabled = await datasource.getStreakReminderEnabled();

        // Assert
        expect(enabled, isFalse);
      });

      test('streak_reminder_enabledがnullの場合はデフォルト値を返すこと', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 0,
          DatabaseConsts.columnStreakReminderEnabled: null,
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        final enabled = await datasource.getStreakReminderEnabled();

        // Assert
        expect(enabled, equals(StreakReminderConsts.defaultReminderEnabled));
      });
    });

    group('updateStreakReminderEnabled', () {
      test('ユーザーが存在しない場合は何もしないこと', () async {
        // Act & Assert - エラーが発生しないこと
        await datasource.updateStreakReminderEnabled(false);

        final enabled = await datasource.getStreakReminderEnabled();
        expect(enabled, equals(StreakReminderConsts.defaultReminderEnabled));
      });

      test('リマインダーをONからOFFに更新できること', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 0,
          DatabaseConsts.columnStreakReminderEnabled: 1,
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        await datasource.updateStreakReminderEnabled(false);

        // Assert
        final enabled = await datasource.getStreakReminderEnabled();
        expect(enabled, isFalse);
      });

      test('リマインダーをOFFからONに更新できること', () async {
        // Arrange
        final db = await database.database;
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: const Uuid().v4(),
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 0,
          DatabaseConsts.columnStreakReminderEnabled: 0,
          DatabaseConsts.columnCreatedAt: DateTime.now().toIso8601String(),
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        });

        // Act
        await datasource.updateStreakReminderEnabled(true);

        // Assert
        final enabled = await datasource.getStreakReminderEnabled();
        expect(enabled, isTrue);
      });

      test('更新時にupdated_atが更新されること', () async {
        // Arrange
        final db = await database.database;
        final userId = const Uuid().v4();
        final initialTime = DateTime.now().subtract(const Duration(hours: 1));
        await db.insert(DatabaseConsts.tableUsers, {
          DatabaseConsts.columnId: userId,
          DatabaseConsts.columnEmail: 'test@example.com',
          DatabaseConsts.columnDisplayName: 'Test User',
          DatabaseConsts.columnLongestStreak: 0,
          DatabaseConsts.columnStreakReminderEnabled: 1,
          DatabaseConsts.columnCreatedAt: initialTime.toIso8601String(),
          DatabaseConsts.columnUpdatedAt: initialTime.toIso8601String(),
        });

        // Act
        await datasource.updateStreakReminderEnabled(false);

        // Assert
        final result = await db.query(
          DatabaseConsts.tableUsers,
          where: '${DatabaseConsts.columnId} = ?',
          whereArgs: [userId],
        );
        final updatedAt = DateTime.parse(
          result.first[DatabaseConsts.columnUpdatedAt] as String,
        );
        expect(updatedAt.isAfter(initialTime), isTrue);
      });
    });
  });
}
