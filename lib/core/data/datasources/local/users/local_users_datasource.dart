import 'package:goal_timer/core/data/local/database/app_database.dart';
import 'package:goal_timer/core/models/users/users_model.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

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
      AppLogger.instance.e('ローカルからのユーザーデータ取得に失敗しました: $e');
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
      AppLogger.instance.e('ローカルからのユーザーデータ取得に失敗しました: $id, $e');
      return null;
    }
  }

  // 現在のユーザーを取得
  Future<UsersModel?> getCurrentUser() async {
    try {
      final db = await _database.database;
      final maps = await db.query(_tableName, limit: 1);

      if (maps.isEmpty) return null;
      return _convertToUsersModel(maps.first);
    } catch (e) {
      AppLogger.instance.e('現在のユーザーの取得に失敗しました: $e');
      return null;
    }
  }

  // ユーザーを追加または更新
  Future<UsersModel> upsertUser(UsersModel user) async {
    try {
      final db = await _database.database;
      final map = _convertToMap(user);

      // ユーザーが既に存在するか確認
      final existingUser = await getUserById(user.id);

      if (existingUser == null) {
        // 新規作成
        await db.insert(_tableName, map);
      } else {
        // 更新
        await db.update(_tableName, map, where: 'id = ?', whereArgs: [user.id]);
      }

      return user;
    } catch (e) {
      AppLogger.instance.e('ローカルでのユーザー作成/更新に失敗しました: $e');
      rethrow;
    }
  }

  // ユーザーを更新
  Future<UsersModel> updateUser(UsersModel user) async {
    try {
      final db = await _database.database;
      final map = _convertToMap(user);

      await db.update(_tableName, map, where: 'id = ?', whereArgs: [user.id]);

      return user;
    } catch (e) {
      AppLogger.instance.e('ローカルでのユーザー更新に失敗しました: ${user.id}, $e');
      rethrow;
    }
  }

  // 未同期のユーザーを取得
  Future<List<UsersModel>> getUnsyncedUsers() async {
    try {
      final db = await _database.database;
      final maps = await db.query(_tableName);

      return maps.map((map) => _convertToUsersModel(map)).toList();
    } catch (e) {
      AppLogger.instance.e('未同期のユーザーデータの取得に失敗しました: $e');
      return [];
    }
  }

  // 同期フラグを更新
  Future<void> markAsSynced(String id) async {
    try {
      final db = await _database.database;
      await db.update(
        _tableName,
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      AppLogger.instance.e('同期フラグの更新に失敗しました: $id, $e');
      rethrow;
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
    };
  }

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
