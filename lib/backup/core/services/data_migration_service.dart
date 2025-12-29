import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/database/app_database.dart';
import '../utils/app_logger.dart';

/// Service for migrating temporary user data to authenticated user
class DataMigrationService {
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Migrate all temporary user data to real user account
  Future<bool> migrateTempUserData(String tempUserId, String realUserId) async {
    if (!validateTempUserId(tempUserId) || !validateRealUserId(realUserId)) {
      return false;
    }

    try {
      return await executeMigrationTransaction(tempUserId, realUserId);
    } catch (e, stackTrace) {
      // Log error for debugging
      AppLogger.instance.e(
        'Migration failed for $tempUserId -> $realUserId',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Execute migration with retry mechanism
  Future<bool> retryMigration(
    String tempUserId,
    String realUserId, {
    int attempt = 1,
  }) async {
    if (attempt > _maxRetryAttempts) {
      return false;
    }

    try {
      return await migrateTempUserData(tempUserId, realUserId);
    } catch (e) {
      if (attempt < _maxRetryAttempts) {
        await Future.delayed(_retryDelay);
        return await retryMigration(
          tempUserId,
          realUserId,
          attempt: attempt + 1,
        );
      }
      return false;
    }
  }

  /// Validate temporary user ID format
  bool validateTempUserId(String? tempUserId) {
    if (tempUserId == null || tempUserId.isEmpty) return false;
    return tempUserId.startsWith('local_user_temp_') && tempUserId.length > 18;
  }

  /// Validate real user ID format
  bool validateRealUserId(String? realUserId) {
    if (realUserId == null || realUserId.isEmpty) return false;
    return realUserId.isNotEmpty;
  }

  /// Migrate goal data from temp user to real user
  Future<bool> migrateGoalData(String tempUserId, String realUserId) async {
    try {
      final db = await AppDatabase.instance.database;

      // Update goals table
      await db.update(
        'goals',
        {
          'user_id': realUserId,
          'is_temp': 0,
          'temp_user_id': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'temp_user_id = ? AND is_temp = 1',
        whereArgs: [tempUserId],
      );

      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.e('Goal data migration failed', e, stackTrace);
      return false;
    }
  }

  /// Migrate study log data from temp user to real user
  Future<bool> migrateStudyLogData(String tempUserId, String realUserId) async {
    try {
      final db = await AppDatabase.instance.database;

      // Update study_logs table
      await db.update(
        'study_logs',
        {
          'user_id': realUserId,
          'is_temp': 0,
          'temp_user_id': null,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'temp_user_id = ? AND is_temp = 1',
        whereArgs: [tempUserId],
      );

      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.e('Study log data migration failed', e, stackTrace);
      return false;
    }
  }

  /// Clean up temporary data after successful migration
  Future<bool> cleanupTempData(String tempUserId) async {
    if (!validateTempUserId(tempUserId)) {
      return false;
    }

    try {
      final db = await AppDatabase.instance.database;

      // Delete all temp user data
      // Use user_id instead of temp_user_id for consistent cleanup
      await db.delete('goals', where: 'user_id = ?', whereArgs: [tempUserId]);

      await db.delete(
        'daily_study_logs',
        where: 'user_id = ?',
        whereArgs: [tempUserId],
      );

      // Delete the temp user record
      await db.delete('users', where: 'id = ?', whereArgs: [tempUserId]);

      // Clear SharedPreferences temp data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('temp_user_id');
      await prefs.remove('temp_user_created_at');
      await prefs.remove('temp_onboarding_step');

      AppLogger.instance.i('一時ユーザーデータの削除が完了しました: $tempUserId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.e('一時ユーザーデータの削除に失敗しました', e, stackTrace);
      return false;
    }
  }

  /// Execute complete migration in a database transaction
  Future<bool> executeMigrationTransaction(
    String tempUserId,
    String realUserId,
  ) async {
    final db = await AppDatabase.instance.database;

    try {
      await db.transaction((txn) async {
        // Migrate goals
        await txn.update(
          'goals',
          {
            'user_id': realUserId,
            'is_temp': 0,
            'temp_user_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'user_id = ?',
          whereArgs: [tempUserId],
        );

        // Migrate study logs
        await txn.update(
          'daily_study_logs',
          {
            'user_id': realUserId,
            'is_temp': 0,
            'temp_user_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'user_id = ?',
          whereArgs: [tempUserId],
        );
      });

      // Clear SharedPreferences after successful database migration
      await _clearTempUserSharedPreferences();

      AppLogger.instance.i('データ移行が完了しました: $tempUserId → $realUserId');
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.e('データ移行に失敗しました', e, stackTrace);
      return false;
    }
  }

  /// Get count of temp data to be migrated
  Future<Map<String, int>> getTempDataCounts(String tempUserId) async {
    try {
      final db = await AppDatabase.instance.database;

      final goalCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM goals WHERE user_id = ?', [
              tempUserId,
            ]),
          ) ??
          0;

      final studyLogCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM daily_study_logs WHERE user_id = ?',
              [tempUserId],
            ),
          ) ??
          0;

      return {'goals': goalCount, 'study_logs': studyLogCount};
    } catch (e, stackTrace) {
      AppLogger.instance.e('一時データ件数の取得に失敗しました', e, stackTrace);
      return {'goals': 0, 'study_logs': 0};
    }
  }

  /// Check if temp user has any data to migrate
  Future<bool> hasTempDataToMigrate(String tempUserId) async {
    final counts = await getTempDataCounts(tempUserId);
    return counts['goals']! > 0 || counts['study_logs']! > 0;
  }

  /// Clear temporary user data from SharedPreferences
  Future<void> _clearTempUserSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_user_id');
    await prefs.remove('temp_user_created_at');
    await prefs.remove('temp_onboarding_step');
  }

  /// Get migration summary for user confirmation
  Future<Map<String, dynamic>> getMigrationSummary(String tempUserId) async {
    final counts = await getTempDataCounts(tempUserId);
    final prefs = await SharedPreferences.getInstance();
    final createdAt = prefs.getInt('temp_user_created_at');

    return {
      'temp_user_id': tempUserId,
      'created_at':
          createdAt != null
              ? DateTime.fromMillisecondsSinceEpoch(createdAt)
              : null,
      'goal_count': counts['goals'],
      'study_log_count': counts['study_logs'],
      'has_data': counts['goals']! > 0 || counts['study_logs']! > 0,
    };
  }
}
