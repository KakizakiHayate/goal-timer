import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/database_consts.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

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

      // ユーザーが存在するか確認
      final existingUsers = await db.query(
        DatabaseConsts.tableUsers,
        limit: 1,
      );

      if (existingUsers.isEmpty) {
        AppLogger.instance.w('ユーザーが存在しないため、最長ストリークを更新できません');
        return;
      }

      final userId = existingUsers.first[DatabaseConsts.columnId] as String;

      await db.update(
        DatabaseConsts.tableUsers,
        {
          DatabaseConsts.columnLongestStreak: streak,
          DatabaseConsts.columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseConsts.columnId} = ?',
        whereArgs: [userId],
      );

      AppLogger.instance.i('最長ストリークを更新しました: $streak');
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

      // ユーザーが存在するか確認
      final existingUsers = await db.query(
        DatabaseConsts.tableUsers,
        limit: 1,
      );

      if (existingUsers.isEmpty) {
        return false;
      }

      final longestStreak =
          (existingUsers.first[DatabaseConsts.columnLongestStreak] as int?) ??
              0;

      if (currentStreak > longestStreak) {
        await updateLongestStreak(currentStreak);
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.instance.e('最長ストリークの条件付き更新に失敗しました', e, stackTrace);
      return false;
    }
  }
}
