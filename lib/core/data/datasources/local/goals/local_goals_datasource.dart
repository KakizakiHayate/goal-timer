import 'package:goal_timer/core/data/local/database/app_database.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

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
      print('ローカルからの目標データ取得に失敗しました: $e');
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
      print('ローカルからの目標データ取得に失敗しました: $id, $e');
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
                version: 1,
                isSynced: false,
              )
              : goal.copyWith(updatedAt: now, isSynced: false);

      final map = _convertToMap(newGoal);

      await db.insert(_tableName, map);

      // オフライン操作を記録
      await _recordOfflineOperation('create', newGoal.id);

      return newGoal;
    } catch (e) {
      print('ローカルでの目標作成に失敗しました: $e');
      rethrow;
    }
  }

  // 既存の目標を更新
  Future<GoalsModel> updateGoal(GoalsModel goal) async {
    try {
      final db = await _database.database;

      // 現在のバージョンを取得
      final result = await db.query(
        _tableName,
        columns: ['version'],
        where: 'id = ?',
        whereArgs: [goal.id],
      );

      final currentVersion =
          result.isNotEmpty ? (result.first['version'] as int) : 0;
      final newVersion = currentVersion + 1;

      final now = DateTime.now().toUtc();
      final updatedGoal = goal.copyWith(
        updatedAt: now,
        version: newVersion,
        isSynced: false,
      );

      final map = _convertToMap(updatedGoal);

      await db.update(_tableName, map, where: 'id = ?', whereArgs: [goal.id]);

      // オフライン操作を記録
      await _recordOfflineOperation('update', goal.id);

      return updatedGoal;
    } catch (e) {
      print('ローカルでの目標更新に失敗しました: ${goal.id}, $e');
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
      print('ローカルでの目標削除に失敗しました: $id, $e');
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
      print('未同期の目標データの取得に失敗しました: $e');
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
      print('同期フラグの更新に失敗しました: $id, $e');
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
      print('オフライン操作の記録に失敗しました: $e');
    }
  }

  // SQLiteとGoalsModel間のマッピング
  Map<String, dynamic> _convertToMap(GoalsModel goal) {
    return {
      'id': goal.id,
      'user_id': goal.userId,
      'title': goal.title,
      'description': goal.description,
      'deadline': goal.deadline.toIso8601String(),
      'is_completed': goal.isCompleted ? 1 : 0,
      'avoid_message': goal.avoidMessage,
      'total_target_hours': goal.totalTargetHours,
      'spent_minutes': goal.spentMinutes,
      'updated_at':
          goal.updatedAt?.toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      'version': goal.version,
      'is_synced': goal.isSynced ? 1 : 0,
    };
  }

  // SQLiteの型をGoalsModelに合わせて変換
  GoalsModel _convertToGoalsModel(Map<String, dynamic> map) {
    return GoalsModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      deadline: DateTime.parse(map['deadline'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      avoidMessage: map['avoid_message'] as String,
      totalTargetHours: map['total_target_hours'] as int,
      spentMinutes: map['spent_minutes'] as int,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      version: map['version'] as int,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }
}
