import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/users/users_model.dart';
import '../../utils/app_logger.dart';

/// Supabase usersテーブルを操作するDataSource
class SupabaseUsersDatasource {
  final SupabaseClient _supabase;

  static const String _tableName = 'users';

  SupabaseUsersDatasource({required SupabaseClient supabase})
      : _supabase = supabase;

  /// ユーザーを取得
  Future<UsersModel?> fetchUser(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UsersModel.fromJson(response);
    } catch (error, stackTrace) {
      AppLogger.instance.e('ユーザー取得に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// ユーザーを作成または更新
  Future<UsersModel> upsertUser(UsersModel user) async {
    try {
      final now = DateTime.now();
      final userToUpsert = user.copyWith(
        updatedAt: now,
        syncUpdatedAt: now,
      );

      final response = await _supabase
          .from(_tableName)
          .upsert(userToUpsert.toJson())
          .select()
          .single();

      AppLogger.instance.i('ユーザーをupsertしました: ${user.id}');
      return UsersModel.fromJson(response);
    } catch (error, stackTrace) {
      AppLogger.instance.e('ユーザーupsertに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// ユーザーを削除
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', userId);

      AppLogger.instance.i('ユーザーを削除しました: $userId');
    } catch (error, stackTrace) {
      AppLogger.instance.e('ユーザー削除に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 最終ログイン日時を更新
  Future<void> updateLastLogin(String userId) async {
    try {
      final now = DateTime.now();
      await _supabase.from(_tableName).update({
        'last_login': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'sync_updated_at': now.toIso8601String(),
      }).eq('id', userId);

      AppLogger.instance.i('最終ログイン日時を更新しました: $userId');
    } catch (error, stackTrace) {
      AppLogger.instance.e('最終ログイン更新に失敗しました', error, stackTrace);
      rethrow;
    }
  }
}
