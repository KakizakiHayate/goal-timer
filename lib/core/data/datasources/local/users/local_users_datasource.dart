import 'package:goal_timer/core/data/local/database/app_database.dart';
import 'package:goal_timer/core/models/users/users_model.dart';
import 'package:sqflite/sqflite.dart';

class LocalUsersDatasource {
  final AppDatabase _database = AppDatabase.instance;
  static const String _tableName = 'users';

  // 全ユーザーを取得
  Future<List<UsersModel>> getUsers() async {
    try {
      final db = await _database.database;
      final maps = await db.query(_tableName);

      return maps.map((map) => _convertToUsersModel(map)).toList();
    } catch (e) {
      print('ローカルからのユーザーデータ取得に失敗しました: $e');
      return [];
    }
  }

  // 特定のIDのユーザーを取得
  Future<UsersModel?> getUserById(String id) async {
    try {
      final db = await _database.database;
      final maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);

      if (maps.isEmpty) return null;
      return _convertToUsersModel(maps.first);
    } catch (e) {
      print('ローカルからのユーザーデータ取得に失敗しました: $id, $e');
      return null;
    }
  }

  // 新しいユーザーを作成または更新
  Future<UsersModel> upsertUser(UsersModel user) async {
    try {
      final db = await _database.database;
      final now = DateTime.now().toUtc();

      // 更新日時を現在時刻に設定
      final updatedUser = user.copyWith(updatedAt: now);

      final map = _convertToMap(updatedUser);

      // ユーザーが既に存在するか確認
      final existingUser = await getUserById(user.id);
      if (existingUser == null) {
        // 新規作成
        await db.insert(_tableName, map);
      } else {
        // 更新
        await db.update(_tableName, map, where: 'id = ?', whereArgs: [user.id]);
      }

      // オフライン操作を記録
      final operationType = existingUser == null ? 'create' : 'update';
      await _recordOfflineOperation(operationType, user.id);

      return updatedUser;
    } catch (e) {
      print('ローカルでのユーザー作成/更新に失敗しました: $e');
      rethrow;
    }
  }

  // 未同期のユーザーを取得
  Future<List<UsersModel>> getUnsyncedUsers() async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        _tableName,
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      return maps.map((map) => _convertToUsersModel(map)).toList();
    } catch (e) {
      print('未同期のユーザーデータの取得に失敗しました: $e');
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

  // SQLiteとUsersModel間のマッピング
  Map<String, dynamic> _convertToMap(UsersModel user) {
    return {
      'id': user.id,
      'email': user.email,
      'display_name': user.displayName,
      'created_at': user.createdAt.toIso8601String(),
      'updated_at': user.updatedAt.toIso8601String(),
      'last_login': user.lastLogin?.toIso8601String(),
      'is_synced': 0, // 未同期状態
    };
  }

  // SQLiteの型をUsersModelに合わせて変換
  UsersModel _convertToUsersModel(Map<String, dynamic> map) {
    return UsersModel(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastLogin:
          map['last_login'] != null
              ? DateTime.parse(map['last_login'] as String)
              : null,
    );
  }
}
