import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/database_consts.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:sqflite/sqflite.dart';

class LocalGoalsDatasource {
  final AppDatabase _database;

  LocalGoalsDatasource({required AppDatabase database})
      : _database = database;

  /// 全ての目標を取得（削除済みを除く）
  Future<List<GoalsModel>> fetchAllGoals() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConsts.tableGoals,
      where: '${DatabaseConsts.columnDeletedAt} IS NULL',
    );

    return maps.map((map) => _mapToModel(map)).toList();
  }

  /// 削除済みを含む全ての目標を取得
  Future<List<GoalsModel>> fetchAllGoalsIncludingDeleted() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps =
        await db.query(DatabaseConsts.tableGoals);

    return maps.map((map) => _mapToModel(map)).toList();
  }

  /// 特定の目標を取得
  Future<GoalsModel?> fetchGoalById(String id) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConsts.tableGoals,
      where: '${DatabaseConsts.columnId} = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToModel(maps.first);
  }

  /// 目標を保存
  Future<void> saveGoal(GoalsModel goal) async {
    final db = await _database.database;
    await db.insert(
      DatabaseConsts.tableGoals,
      _modelToMap(goal),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 目標を更新
  Future<void> updateGoal(GoalsModel goal) async {
    final db = await _database.database;
    // 更新時は未同期状態にする
    final goalToUpdate = goal.copyWith(syncUpdatedAt: null);
    await db.update(
      DatabaseConsts.tableGoals,
      _modelToMap(goalToUpdate),
      where: '${DatabaseConsts.columnId} = ?',
      whereArgs: [goal.id],
    );
  }

  /// 目標を論理削除（deleted_atに現在日時を設定）
  Future<void> deleteGoal(String id) async {
    final db = await _database.database;
    await db.update(
      DatabaseConsts.tableGoals,
      {
        DatabaseConsts.columnDeletedAt: DateTime.now().toIso8601String(),
        DatabaseConsts.columnSyncUpdatedAt: null, // 未同期状態にする
      },
      where: '${DatabaseConsts.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 目標を物理削除（完全に削除）
  Future<void> hardDeleteGoal(String id) async {
    final db = await _database.database;
    await db.delete(
      DatabaseConsts.tableGoals,
      where: '${DatabaseConsts.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 未同期の目標を取得
  Future<List<GoalsModel>> fetchUnsyncedGoals() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConsts.tableGoals,
      where: '${DatabaseConsts.columnSyncUpdatedAt} IS NULL',
    );

    return maps.map((map) => _mapToModel(map)).toList();
  }

  /// 同期済みフラグを更新
  Future<void> markAsSynced(String id) async {
    final db = await _database.database;
    await db.update(
      DatabaseConsts.tableGoals,
      {DatabaseConsts.columnSyncUpdatedAt: DateTime.now().toIso8601String()},
      where: '${DatabaseConsts.columnId} = ?',
      whereArgs: [id],
    );
  }

  // ヘルパーメソッド: Map → Model
  GoalsModel _mapToModel(Map<String, dynamic> map) {
    return GoalsModel(
      id: map[DatabaseConsts.columnId] as String,
      userId: map[DatabaseConsts.columnUserId] as String?,
      title: map[DatabaseConsts.columnTitle] as String,
      description: map[DatabaseConsts.columnDescription] as String?,
      targetMinutes: map[DatabaseConsts.columnTargetMinutes] as int,
      avoidMessage: map[DatabaseConsts.columnAvoidMessage] as String,
      deadline: DateTime.parse(map[DatabaseConsts.columnDeadline] as String),
      completedAt: map[DatabaseConsts.columnCompletedAt] != null
          ? DateTime.parse(map[DatabaseConsts.columnCompletedAt] as String)
          : null,
      deletedAt: map[DatabaseConsts.columnDeletedAt] != null
          ? DateTime.parse(map[DatabaseConsts.columnDeletedAt] as String)
          : null,
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
  }

  // ヘルパーメソッド: Model → Map
  Map<String, dynamic> _modelToMap(GoalsModel model) {
    return {
      DatabaseConsts.columnId: model.id,
      DatabaseConsts.columnUserId: model.userId,
      DatabaseConsts.columnTitle: model.title,
      DatabaseConsts.columnDescription: model.description,
      DatabaseConsts.columnTargetMinutes: model.targetMinutes,
      DatabaseConsts.columnAvoidMessage: model.avoidMessage,
      DatabaseConsts.columnDeadline: model.deadline.toIso8601String(),
      DatabaseConsts.columnCompletedAt: model.completedAt?.toIso8601String(),
      DatabaseConsts.columnDeletedAt: model.deletedAt?.toIso8601String(),
      DatabaseConsts.columnCreatedAt: model.createdAt?.toIso8601String(),
      DatabaseConsts.columnUpdatedAt: model.updatedAt?.toIso8601String(),
      DatabaseConsts.columnSyncUpdatedAt: model.syncUpdatedAt?.toIso8601String(),
    };
  }
}
