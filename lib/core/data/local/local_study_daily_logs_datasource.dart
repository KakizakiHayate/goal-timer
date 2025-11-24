import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/database_consts.dart';
import 'package:goal_timer/core/models/study_daily_logs/study_daily_logs_model.dart';
import 'package:sqflite/sqflite.dart';

class LocalStudyDailyLogsDatasource {
  final AppDatabase _database;

  LocalStudyDailyLogsDatasource({required AppDatabase database})
      : _database = database;

  /// 全ての学習ログを取得
  Future<List<StudyDailyLogsModel>> fetchAllLogs() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps =
        await db.query(DatabaseConsts.tableStudyDailyLogs);

    return maps.map((map) => _mapToModel(map)).toList();
  }

  /// 特定の目標の学習ログを取得
  Future<List<StudyDailyLogsModel>> fetchLogsByGoalId(String goalId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConsts.tableStudyDailyLogs,
      where: '${DatabaseConsts.columnGoalId} = ?',
      whereArgs: [goalId],
    );

    return maps.map((map) => _mapToModel(map)).toList();
  }

  /// 学習ログを保存
  Future<void> saveLog(StudyDailyLogsModel log) async {
    final db = await _database.database;
    await db.insert(
      DatabaseConsts.tableStudyDailyLogs,
      _modelToMap(log),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 学習ログを削除
  Future<void> deleteLog(String id) async {
    final db = await _database.database;
    await db.delete(
      DatabaseConsts.tableStudyDailyLogs,
      where: '${DatabaseConsts.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 未同期のログを取得
  Future<List<StudyDailyLogsModel>> fetchUnsyncedLogs() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConsts.tableStudyDailyLogs,
      where: '${DatabaseConsts.columnSyncUpdatedAt} IS NULL',
    );

    return maps.map((map) => _mapToModel(map)).toList();
  }

  /// 同期済みフラグを更新
  Future<void> markAsSynced(String id) async {
    final db = await _database.database;
    await db.update(
      DatabaseConsts.tableStudyDailyLogs,
      {DatabaseConsts.columnSyncUpdatedAt: DateTime.now().toIso8601String()},
      where: '${DatabaseConsts.columnId} = ?',
      whereArgs: [id],
    );
  }

  // ヘルパーメソッド: Map → Model
  StudyDailyLogsModel _mapToModel(Map<String, dynamic> map) {
    try {
      return StudyDailyLogsModel(
        id: map[DatabaseConsts.columnId] as String,
        goalId: map[DatabaseConsts.columnGoalId] as String,
        studyDate: DateTime.parse(map[DatabaseConsts.columnStudyDate] as String),
        totalSeconds: map[DatabaseConsts.columnTotalSeconds] as int,
        userId: map[DatabaseConsts.columnUserId] as String?,
        createdAt: map[DatabaseConsts.columnCreatedAt] != null
            ? DateTime.parse(map[DatabaseConsts.columnCreatedAt] as String)
            : null,
        updatedAt: map[DatabaseConsts.columnUpdatedAt] != null
            ? DateTime.parse(map[DatabaseConsts.columnUpdatedAt] as String)
            : null,
        syncUpdatedAt: map[DatabaseConsts.columnSyncUpdatedAt] != null
            ? DateTime.parse(map[DatabaseConsts.columnSyncUpdatedAt] as String)
            : null,
      );
    } catch (e) {
      throw Exception('データベースからのモデル変換に失敗しました: $e');
    }
  }

  // ヘルパーメソッド: Model → Map
  Map<String, dynamic> _modelToMap(StudyDailyLogsModel model) {
    return {
      DatabaseConsts.columnId: model.id,
      DatabaseConsts.columnGoalId: model.goalId,
      DatabaseConsts.columnStudyDate: model.studyDate.toIso8601String(),
      DatabaseConsts.columnTotalSeconds: model.totalSeconds,
      DatabaseConsts.columnUserId: model.userId,
      DatabaseConsts.columnCreatedAt: model.createdAt?.toIso8601String(),
      DatabaseConsts.columnUpdatedAt: model.updatedAt?.toIso8601String(),
      DatabaseConsts.columnSyncUpdatedAt: model.syncUpdatedAt?.toIso8601String(),
    };
  }
}
