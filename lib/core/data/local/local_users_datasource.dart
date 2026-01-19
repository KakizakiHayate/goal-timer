import '../../utils/app_logger.dart';
import '../../utils/streak_reminder_consts.dart';
import 'app_database.dart';
import 'database_consts.dart';

/// ユーザーデータのローカルデータソース
class LocalUsersDatasource {
  final AppDatabase _database;

  LocalUsersDatasource({required AppDatabase database}) : _database = database;

  /// 最長ストリークを取得
  /// ユーザーが存在しない場合は0を返す
  Future<int> getLongestStreak() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        DatabaseConsts.tableUsers,
        columns: [DatabaseConsts.columnLongestStreak],
        limit: 1,
      );

      if (result.isEmpty) {
        return 0;
      }

      return (result.first[DatabaseConsts.columnLongestStreak] as int?) ?? 0;
    } catch (e, stackTrace) {
      AppLogger.instance.e('最長ストリークの取得に失敗しました', e, stackTrace);
      return 0;
    }
  }

  /// 最長ストリークを更新
  /// ユーザーが存在しない場合は何もしない
  Future<void> updateLongestStreak(int streak) async {
    try {
      final db = await _database.database;

      // updateは更新した行数を返すため、事前にSELECTする必要はない
      // usersテーブルには単一のユーザーしか存在しない前提
      final count = await db.update(DatabaseConsts.tableUsers, {
        DatabaseConsts.columnLongestStreak: streak,
        DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
      });

      if (count > 0) {
        AppLogger.instance.i('最長ストリークを更新しました: $streak');
      } else {
        AppLogger.instance.w('ユーザーが存在しないため、最長ストリークを更新できません');
      }
    } catch (e, stackTrace) {
      AppLogger.instance.e('最長ストリークの更新に失敗しました', e, stackTrace);
      rethrow;
    }
  }

  /// 現在のストリークが最長を超えていれば更新
  /// 更新した場合はtrueを返す
  /// ユーザーが存在しない場合はfalseを返す
  Future<bool> updateLongestStreakIfNeeded(int currentStreak) async {
    try {
      final db = await _database.database;

      // ユーザー情報を取得
      final existingUsers = await db.query(DatabaseConsts.tableUsers, limit: 1);

      if (existingUsers.isEmpty) {
        return false;
      }

      final userData = existingUsers.first;
      final longestStreak =
          (userData[DatabaseConsts.columnLongestStreak] as int?) ?? 0;

      if (currentStreak > longestStreak) {
        // 直接更新することでDBアクセスを削減
        final userId = userData[DatabaseConsts.columnId] as String;
        await db.update(
          DatabaseConsts.tableUsers,
          {
            DatabaseConsts.columnLongestStreak: currentStreak,
            DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
          },
          where: '${DatabaseConsts.columnId} = ?',
          whereArgs: [userId],
        );
        AppLogger.instance.i('最長ストリークを更新しました: $currentStreak');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.instance.e('最長ストリークの条件付き更新に失敗しました', e, stackTrace);
      return false;
    }
  }

  /// ストリークリマインダー通知の有効/無効を取得
  /// ユーザーが存在しない場合はデフォルト値（有効）を返す
  Future<bool> getStreakReminderEnabled() async {
    try {
      final db = await _database.database;
      final result = await db.query(
        DatabaseConsts.tableUsers,
        columns: [DatabaseConsts.columnStreakReminderEnabled],
        limit: 1,
      );

      if (result.isEmpty) {
        return StreakReminderConsts.defaultReminderEnabled;
      }

      final value =
          result.first[DatabaseConsts.columnStreakReminderEnabled] as int?;
      if (value == null) {
        return StreakReminderConsts.defaultReminderEnabled;
      }
      return value == 1;
    } catch (e, stackTrace) {
      AppLogger.instance.e('ストリークリマインダー設定の取得に失敗しました', e, stackTrace);
      return StreakReminderConsts.defaultReminderEnabled;
    }
  }

  /// ストリークリマインダー通知の有効/無効を更新
  /// ユーザーが存在しない場合は何もしない
  Future<void> updateStreakReminderEnabled(bool enabled) async {
    try {
      final db = await _database.database;

      final count = await db.update(DatabaseConsts.tableUsers, {
        DatabaseConsts.columnStreakReminderEnabled: enabled ? 1 : 0,
        DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
      });

      if (count > 0) {
        AppLogger.instance.i('ストリークリマインダー設定を更新しました: ${enabled ? "有効" : "無効"}');
      } else {
        AppLogger.instance.w('ユーザーが存在しないため、ストリークリマインダー設定を更新できません');
      }
    } catch (e, stackTrace) {
      AppLogger.instance.e('ストリークリマインダー設定の更新に失敗しました', e, stackTrace);
      rethrow;
    }
  }
}
