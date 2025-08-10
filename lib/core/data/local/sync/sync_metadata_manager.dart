import 'package:goal_timer/core/data/local/database/app_database.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';

class SyncMetadataManager {
  final AppDatabase _database = AppDatabase.instance;
  static const String _tableName = 'sync_metadata';

  /// 最終同期時刻を取得
  Future<DateTime?> getLastSyncTime(String tableName) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        _tableName,
        where: 'table_name = ?',
        whereArgs: [tableName],
      );

      if (result.isNotEmpty) {
        final lastSyncTimeStr = result.first['last_sync_time'] as String;
        return DateTime.parse(lastSyncTimeStr);
      }
      return null;
    } catch (e) {
      AppLogger.instance.e('最終同期時刻の取得に失敗しました: $tableName', e);
      return null;
    }
  }

  /// 最終同期時刻を更新
  Future<void> updateLastSyncTime(String tableName, DateTime syncTime) async {
    try {
      final db = await _database.database;
      await db.insert(_tableName, {
        'table_name': tableName,
        'last_sync_time': syncTime.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      AppLogger.instance.i('最終同期時刻を更新しました: $tableName -> $syncTime');
    } catch (e) {
      AppLogger.instance.e('最終同期時刻の更新に失敗しました: $tableName', e);
      rethrow;
    }
  }

  /// ローカルとリモートの最終更新時刻を比較して同期が必要かどうかを判定
  Future<bool> needsSync(
    String tableName,
    DateTime? localSyncUpdatedAt,
    DateTime? remoteSyncUpdatedAt,
  ) async {
    // ✅ 両方nullなら同期不要（データなし状態）
    if (localSyncUpdatedAt == null && remoteSyncUpdatedAt == null) {
      AppLogger.instance.i('両方にデータなし - 同期不要');
      return false;
    }
    
    // ✅ 片方だけnullなら同期必要（全件同期）
    if (localSyncUpdatedAt == null || remoteSyncUpdatedAt == null) {
      AppLogger.instance.i('片方にデータなし - 全件同期が必要');
      return true;
    }
    
    // ✅ 両方存在する場合は時刻比較（差分同期）
    final needsSync = remoteSyncUpdatedAt.isAfter(localSyncUpdatedAt);
    AppLogger.instance.i('時刻比較結果: $needsSync (local: $localSyncUpdatedAt, remote: $remoteSyncUpdatedAt)');
    return needsSync;
  }

  /// 初回同期かどうかを判定
  Future<bool> isFirstSync(String tableName) async {
    final lastSyncTime = await getLastSyncTime(tableName);
    return lastSyncTime == null;
  }

  /// 全ての同期メタデータを取得（デバッグ用）
  Future<Map<String, DateTime?>> getAllSyncMetadata() async {
    try {
      final db = await _database.database;
      final result = await db.query(_tableName);

      final metadata = <String, DateTime?>{};
      for (final row in result) {
        final tableName = row['table_name'] as String;
        final lastSyncTimeStr = row['last_sync_time'] as String;
        metadata[tableName] = DateTime.parse(lastSyncTimeStr);
      }

      return metadata;
    } catch (e) {
      AppLogger.instance.e('同期メタデータの取得に失敗しました', e);
      return {};
    }
  }

  /// ローカルデータの最終同期更新時刻を取得
  Future<DateTime?> getLocalLastModified(String tableName) async {
    try {
      final db = await _database.database;

      // sync_updated_atカラムを使用して正確な同期時刻を取得
      final result = await db.rawQuery(
        'SELECT MAX(sync_updated_at) as last_modified FROM $tableName',
      );

      if (result.isNotEmpty && result.first['last_modified'] != null) {
        final lastModifiedStr = result.first['last_modified'] as String;
        return DateTime.parse(lastModifiedStr);
      }
      return null;
    } catch (e) {
      AppLogger.instance.e('ローカル最終同期更新時刻の取得に失敗しました: $tableName', e);
      return null;
    }
  }

  /// リモートデータの最終更新時刻を保存
  Future<void> saveRemoteLastModified(
    String tableName,
    DateTime lastModified,
  ) async {
    try {
      final db = await _database.database;
      await db.insert('remote_last_modified', {
        'table_name': tableName,
        'last_modified': lastModified.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      AppLogger.instance.i('リモート最終更新時刻を保存しました: $tableName -> $lastModified');
    } catch (e) {
      AppLogger.instance.e('リモート最終更新時刻の保存に失敗しました: $tableName', e);
      rethrow;
    }
  }

  /// リモートデータの最終更新時刻を取得
  Future<DateTime?> getRemoteLastModified(String tableName) async {
    try {
      final db = await _database.database;
      final result = await db.query(
        'remote_last_modified',
        where: 'table_name = ?',
        whereArgs: [tableName],
      );

      if (result.isNotEmpty) {
        final lastModifiedStr = result.first['last_modified'] as String;
        return DateTime.parse(lastModifiedStr);
      }
      return null;
    } catch (e) {
      AppLogger.instance.e('リモート最終更新時刻の取得に失敗しました: $tableName', e);
      return null;
    }
  }

  /// 同期メタデータをリセット（デバッグ用）
  Future<void> resetSyncMetadata(String tableName) async {
    try {
      final db = await _database.database;
      await db.delete(
        _tableName,
        where: 'table_name = ?',
        whereArgs: [tableName],
      );
      await db.delete(
        'remote_last_modified',
        where: 'table_name = ?',
        whereArgs: [tableName],
      );
      AppLogger.instance.i('同期メタデータをリセットしました: $tableName');
    } catch (e) {
      AppLogger.instance.e('同期メタデータのリセットに失敗しました: $tableName', e);
      rethrow;
    }
  }
}
