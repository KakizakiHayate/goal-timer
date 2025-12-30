import 'package:goal_timer/backup/core/data/local/database/app_database.dart';
import 'package:goal_timer/backup/core/models/daily_study_logs/daily_study_log_model.dart';
import 'package:uuid/uuid.dart';
import 'package:goal_timer/backup/core/utils/app_logger.dart';

class LocalDailyStudyLogsDatasource {
  final AppDatabase _database = AppDatabase.instance;
  static const String _tableName = 'daily_study_logs';

  // 全学習記録を取得
  Future<List<DailyStudyLogModel>> getAllLogs() async {
    try {
      final db = await _database.database;
      final maps = await db.query(_tableName);

      return maps.map((map) => _convertToDailyStudyLogModel(map)).toList();
    } catch (e) {
      AppLogger.instance.e('ローカルからの学習記録取得に失敗しました: $e');
      return [];
    }
  }

  // 特定の日付の学習記録を取得
  Future<List<DailyStudyLogModel>> getDailyLogs(DateTime date) async {
    try {
      final db = await _database.database;
      final formattedDate = date.toIso8601String().split('T')[0];

      final maps = await db.query(
        _tableName,
        where: 'date = ?',
        whereArgs: [formattedDate],
        orderBy: 'goal_id',
      );

      return maps.map((map) => _convertToDailyStudyLogModel(map)).toList();
    } catch (e) {
      AppLogger.instance.e('ローカルからの日付別学習記録取得に失敗しました: $e');
      return [];
    }
  }

  // 特定の期間の学習記録を取得
  Future<List<DailyStudyLogModel>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _database.database;
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final maps = await db.query(
        _tableName,
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDateStr, endDateStr],
        orderBy: 'date',
      );

      return maps.map((map) => _convertToDailyStudyLogModel(map)).toList();
    } catch (e) {
      AppLogger.instance.e('ローカルからの期間別学習記録取得に失敗しました: $e');
      return [];
    }
  }

  // 特定の目標IDの学習記録を取得
  Future<List<DailyStudyLogModel>> getLogsByGoalId(String goalId) async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        _tableName,
        where: 'goal_id = ?',
        whereArgs: [goalId],
        orderBy: 'date',
      );

      return maps.map((map) => _convertToDailyStudyLogModel(map)).toList();
    } catch (e) {
      AppLogger.instance.e('ローカルからの目標別学習記録取得に失敗しました: $e');
      return [];
    }
  }

  // 特定のIDの学習記録を取得
  Future<DailyStudyLogModel?> getLogById(String id) async {
    try {
      final db = await _database.database;
      final maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);

      if (maps.isEmpty) return null;
      return _convertToDailyStudyLogModel(maps.first);
    } catch (e) {
      AppLogger.instance.e('ローカルからの学習記録取得に失敗しました: $id, $e');
      return null;
    }
  }

  // 学習記録を追加または更新
  Future<DailyStudyLogModel> upsertDailyLog(DailyStudyLogModel log) async {
    try {
      final db = await _database.database;
      final now = DateTime.now().toUtc();

      // データ検証
      if (log.goalId.isEmpty) {
        throw Exception('目標IDが指定されていません');
      }
      if (log.totalSeconds < 0) {
        throw Exception('学習時間が不正です: ${log.totalSeconds}秒');
      }

      // 新しいログの場合はIDを生成
      final newLog =
          log.id.isEmpty
              ? DailyStudyLogModel(
                id: const Uuid().v4(),
                goalId: log.goalId,
                date: log.date,
                totalSeconds: log.totalSeconds,
              )
              : log;

      // ログが既に存在するか確認
      final existingLog = await getLogById(newLog.id);

      // SQLiteに保存するマップデータを作成
      final map = {
        'id': newLog.id,
        'goal_id': newLog.goalId,
        'date': newLog.date.toIso8601String().split('T')[0],
        'total_seconds': newLog.totalSeconds,
        'updated_at': now.toIso8601String(),
        'sync_updated_at': now.toIso8601String(),
        'is_synced': 0,
      };

      if (existingLog == null) {
        // 新規作成
        await db.insert(_tableName, map);
      } else {
        // 更新
        await db.update(
          _tableName,
          map,
          where: 'id = ?',
          whereArgs: [newLog.id],
        );
      }

      // オフライン操作を記録
      final operationType = existingLog == null ? 'create' : 'update';
      await _recordOfflineOperation(operationType, newLog.id);

      return _convertToDailyStudyLogModel(map);
    } catch (e) {
      if (e.toString().contains('no column named total_seconds')) {
        AppLogger.instance.e(
          'データベーススキーマが古い可能性があります。アプリを再起動してマイグレーションを実行してください。',
          e,
        );
        throw Exception('データベースの構造が古いため、学習記録を保存できません。アプリを再起動してください。');
      } else if (e.toString().contains('FOREIGN KEY constraint failed')) {
        AppLogger.instance.e('指定された目標IDが存在しません: ${log.goalId}', e);
        throw Exception('指定された目標が見つかりません。目標を確認してください。');
      } else {
        AppLogger.instance.e('ローカルでの学習記録作成/更新に失敗しました: $e');
        throw Exception('学習記録の保存に失敗しました。しばらく時間をおいて再試行してください。');
      }
    }
  }

  // 学習記録を削除
  Future<bool> deleteDailyLog(String id) async {
    try {
      final db = await _database.database;
      final rowsDeleted = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      // オフライン操作を記録
      if (rowsDeleted > 0) {
        await _recordOfflineOperation('delete', id);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.instance.e('ローカルでの学習記録削除に失敗しました: $id, $e');
      return false;
    }
  }

  // 未同期の学習記録を取得
  Future<List<DailyStudyLogModel>> getUnsyncedLogs() async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        _tableName,
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      return maps.map((map) => _convertToDailyStudyLogModel(map)).toList();
    } catch (e) {
      AppLogger.instance.e('未同期の学習記録の取得に失敗しました: $e');
      return [];
    }
  }

  // 同期フラグを更新
  Future<void> markAsSynced(String id) async {
    try {
      final db = await _database.database;
      await db.update(
        _tableName,
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      AppLogger.instance.e('同期フラグの更新に失敗しました: $id, $e');
      rethrow;
    }
  }

  // オフライン操作を記録
  Future<void> _recordOfflineOperation(
    String operationType,
    String recordId,
  ) async {
    try {
      final db = await _database.database;
      await db.insert('offline_operations', {
        'table_name': _tableName,
        'operation_type': operationType,
        'record_id': recordId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      AppLogger.instance.e('オフライン操作の記録に失敗しました: $e');
    }
  }

  // SQLiteのマップからDailyStudyLogModelに変換
  DailyStudyLogModel _convertToDailyStudyLogModel(Map<String, dynamic> map) {
    try {
      // 必須フィールドの存在チェック
      if (!map.containsKey('id') || map['id'] == null) {
        throw Exception('学習記録のIDが見つかりません');
      }
      if (!map.containsKey('goal_id') || map['goal_id'] == null) {
        throw Exception('目標IDが見つかりません');
      }
      if (!map.containsKey('date') || map['date'] == null) {
        throw Exception('日付情報が見つかりません');
      }

      // 学習時間の取得（後方互換性対応）
      int totalSeconds = 0;
      if (map.containsKey('total_seconds') && map['total_seconds'] != null) {
        totalSeconds = map['total_seconds'] as int;
      } else if (map.containsKey('minutes') && map['minutes'] != null) {
        // 古いデータ形式からの変換
        totalSeconds = (map['minutes'] as int) * 60;
        AppLogger.instance.d(
          '古いminutes形式から変換: ${map['minutes']}分 → ${totalSeconds}秒',
        );
      }

      // 追加フィールドの取得
      DateTime? createdAt;
      if (map.containsKey('created_at') && map['created_at'] != null) {
        createdAt =
            map['created_at'] is String
                ? DateTime.parse(map['created_at'])
                : (map['created_at'] as DateTime?);
      }

      DateTime? updatedAt;
      if (map.containsKey('updated_at') && map['updated_at'] != null) {
        updatedAt =
            map['updated_at'] is String
                ? DateTime.parse(map['updated_at'])
                : (map['updated_at'] as DateTime?);
      }

      DateTime? syncUpdatedAt;
      if (map.containsKey('sync_updated_at') &&
          map['sync_updated_at'] != null) {
        syncUpdatedAt =
            map['sync_updated_at'] is String
                ? DateTime.parse(map['sync_updated_at'])
                : (map['sync_updated_at'] as DateTime?);
      }

      bool isSynced = false;
      if (map.containsKey('is_synced') && map['is_synced'] != null) {
        if (map['is_synced'] is bool) {
          isSynced = map['is_synced'];
        } else if (map['is_synced'] is int) {
          isSynced = map['is_synced'] == 1;
        }
      }

      bool isTemp = false;
      if (map.containsKey('is_temp') && map['is_temp'] != null) {
        if (map['is_temp'] is bool) {
          isTemp = map['is_temp'];
        } else if (map['is_temp'] is int) {
          isTemp = map['is_temp'] == 1;
        }
      }

      String? tempUserId;
      if (map.containsKey('temp_user_id')) {
        tempUserId = map['temp_user_id'] as String?;
      }

      return DailyStudyLogModel(
        id: map['id'] as String,
        goalId: map['goal_id'] as String,
        date:
            map['date'] is String
                ? DateTime.parse(map['date'])
                : (map['date'] as DateTime),
        totalSeconds: totalSeconds,
        createdAt: createdAt,
        updatedAt: updatedAt,
        syncUpdatedAt: syncUpdatedAt,
        isSynced: isSynced,
        isTemp: isTemp,
        tempUserId: tempUserId,
      );
    } catch (e) {
      AppLogger.instance.e('学習記録データの変換に失敗しました: $map', e);
      rethrow;
    }
  }
}
