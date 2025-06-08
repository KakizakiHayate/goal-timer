import 'package:goal_timer/core/models/users/users_model.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUsersDatasource {
  static const String _tableName = 'users';
  final SupabaseClient _client;

  SupabaseUsersDatasource(this._client);

  // 全ユーザーを取得
  Future<List<UsersModel>> getUsers() async {
    try {
      final response = await _client.from(_tableName).select();

      return response.map((user) => UsersModel.fromMap(user)).toList();
    } catch (e, stackTrace) {
      AppLogger.instance.e('getUsers error', e, stackTrace);
      return [];
    }
  }

  // 特定のIDのユーザーを取得
  Future<UsersModel?> getUserById(String id) async {
    try {
      final response =
          await _client.from(_tableName).select().eq('id', id).single();

      return UsersModel.fromMap(response);
    } catch (e, stackTrace) {
      AppLogger.instance.e('getUserById error', e, stackTrace);
      return null;
    }
  }

  // 新規ユーザーを作成
  Future<UsersModel> createUser(UsersModel user) async {
    try {
      final map = user.toMap();
      await _client.from(_tableName).insert(map);
      return user;
    } catch (e, stackTrace) {
      AppLogger.instance.e('createUser error', e, stackTrace);
      rethrow;
    }
  }

  // 既存ユーザーを更新
  Future<UsersModel> updateUser(UsersModel user) async {
    try {
      final map = user.toMap();
      await _client.from(_tableName).update(map).eq('id', user.id);
      return user;
    } catch (e, stackTrace) {
      AppLogger.instance.e('updateUser error', e, stackTrace);
      rethrow;
    }
  }

  // ユーザーを追加または更新
  Future<UsersModel> upsertUser(UsersModel user) async {
    try {
      final map = user.toMap();
      await _client.from(_tableName).upsert(map, onConflict: 'id');
      return user;
    } catch (e, stackTrace) {
      AppLogger.instance.e('upsertUser error', e, stackTrace);
      rethrow;
    }
  }

  // ユーザーを削除
  Future<bool> deleteUser(String id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.e('deleteUser error', e, stackTrace);
      return false;
    }
  }

  // 現在のユーザー情報を取得
  Future<UsersModel?> getCurrentUser() async {
    try {
      final auth = _client.auth;
      final currentUserId = auth.currentUser?.id;

      if (currentUserId == null) {
        return null;
      }

      return await getUserById(currentUserId);
    } catch (e, stackTrace) {
      AppLogger.instance.e('getCurrentUser error', e, stackTrace);
      return null;
    }
  }
}
