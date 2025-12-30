import 'package:goal_timer/backup/core/data/local/database/app_database.dart';
import 'package:goal_timer/backup/core/models/goals/goals_model.dart';
import 'package:uuid/uuid.dart';
import 'package:goal_timer/backup/core/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';

class LocalGoalsDatasource {
  final AppDatabase _database = AppDatabase.instance;
  static const String _tableName = 'goals';

  // 全目標を取得
  Future<List<GoalsModel>> getGoals() async {
    try {
      final db = await _database.database;
      final maps = await db.query(_tableName);

      return maps.map((map) => _convertToGoalsModel(map)).toList();
    } catch (e) {
      AppLogger.instance.e('ローカルからの目標データ取得に失敗しました: $e');
      return [];
    }
  }

  // 特定のIDの目標を取得
  Future<GoalsModel?> getGoalById(String id) async {
    try {
      final db = await _database.database;
      final maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);

      if (maps.isEmpty) return null;
      return _convertToGoalsModel(maps.first);
    } catch (e) {
      AppLogger.instance.e('ローカルからの目標データ取得に失敗しました: $id, $e');
      return null;
    }
  }

  // 新しい目標を作成
  Future<GoalsModel> createGoal(GoalsModel goal) async {
    try {
      final db = await _database.database;
      final now = DateTime.now().toUtc();

      // 新しいゴールの場合はIDを生成
      final newGoal =
          goal.id.isEmpty
              ? goal.copyWith(
                id: const Uuid().v4(),
                updatedAt: now,
                isSynced: false,
              )
              : goal.copyWith(updatedAt: now, isSynced: false);

      final map = _convertToMap(newGoal);

      await db.insert(_tableName, map);

      // オフライン操作を記録
      await _recordOfflineOperation('create', newGoal.id);

      return newGoal;
    } catch (e) {
      AppLogger.instance.e('ローカルでの目標作成に失敗しました: $e');
      rethrow;
    }
  }

  // 既存の目標を更新
  Future<GoalsModel> updateGoal(GoalsModel goal) async {
    try {
      final db = await _database.database;

      final now = DateTime.now().toUtc();
      final updatedGoal = goal.copyWith(updatedAt: now, isSynced: false);

      final map = _convertToMap(updatedGoal);

      await db.update(_tableName, map, where: 'id = ?', whereArgs: [goal.id]);

      // オフライン操作を記録
      await _recordOfflineOperation('update', goal.id);

      return updatedGoal;
    } catch (e) {
      AppLogger.instance.e('ローカルでの目標更新に失敗しました: ${goal.id}, $e');
      rethrow;
    }
  }

  // 目標を削除
  Future<void> deleteGoal(String id) async {
    try {
      final db = await _database.database;
      await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);

      // オフライン操作を記録
      await _recordOfflineOperation('delete', id);
    } catch (e) {
      AppLogger.instance.e('ローカルでの目標削除に失敗しました: $id, $e');
      rethrow;
    }
  }

  // 未同期の目標を取得
  Future<List<GoalsModel>> getUnsyncedGoals() async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        _tableName,
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      return maps.map((map) => _convertToGoalsModel(map)).toList();
    } catch (e) {
      AppLogger.instance.e('未同期の目標データの取得に失敗しました: $e');
      return [];
    }
  }

  // 目標を追加または更新（同期時に使用）
  Future<void> upsertGoal(GoalsModel goal) async {
    final db = await AppDatabase.instance.database;

    await db.insert('goals', {
      'id': goal.id,
      'user_id': goal.userId,
      'title': goal.title,
      'description': goal.description,
      'deadline': goal.deadline.toIso8601String(),
      'is_completed': goal.isCompleted ? 1 : 0,
      'avoid_message': goal.avoidMessage,
      'target_minutes': goal.targetMinutes,
      'spent_minutes': goal.spentMinutes,
      'updated_at':
          goal.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'sync_updated_at': DateTime.now().toIso8601String(),
      'is_synced': goal.isSynced ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  // SQLiteとGoalsModel間のマッピング
  Map<String, dynamic> _convertToMap(GoalsModel goal) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': goal.id,
      'user_id': goal.userId,
      'title': goal.title,
      'description': goal.description,
      'deadline': goal.deadline.toIso8601String(),
      'is_completed': goal.isCompleted ? 1 : 0,
      'avoid_message': goal.avoidMessage,
      'target_minutes': goal.targetMinutes,
      'spent_minutes': goal.spentMinutes,
      'updated_at': goal.updatedAt?.toIso8601String() ?? now,
      'sync_updated_at': now, // 同期管理用の更新時刻
      'is_synced': goal.isSynced ? 1 : 0,
    };
  }

  GoalsModel _convertToGoalsModel(Map<String, dynamic> map) {
    return GoalsModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      deadline:
          map['deadline'] is String
              ? DateTime.parse(map['deadline'])
              : (map['deadline'] as DateTime),
      isCompleted: (map['is_completed'] as int) == 1,
      avoidMessage: map['avoid_message'] as String,
      targetMinutes: () {
        final targetMins = map['target_minutes'] as int?;
        if (targetMins != null) return targetMins;

        final targetHours = map['total_target_hours'] as int?;
        return targetHours != null ? targetHours * 60 : 0;
      }(),
      spentMinutes: map['spent_minutes'] as int,
      updatedAt:
          map['updated_at'] != null
              ? (map['updated_at'] is String
                  ? DateTime.parse(map['updated_at'])
                  : (map['updated_at'] as DateTime))
              : null,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }
}
