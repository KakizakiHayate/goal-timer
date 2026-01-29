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

  /// displayNameを取得
  ///
  /// usersテーブルからdisplay_nameを取得します。
  /// ユーザーが存在しない場合やdisplay_nameが未設定の場合はnullを返します。
  Future<String?> getDisplayName(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        AppLogger.instance.i('ユーザーが存在しません: $userId');
        return null;
      }

      final displayName = response['display_name'] as String?;
      AppLogger.instance.i('displayNameを取得しました: $displayName');
      return displayName;
    } catch (error, stackTrace) {
      AppLogger.instance.e('displayName取得に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// displayNameを更新
  ///
  /// usersテーブルのdisplay_nameを更新します。
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      final now = DateTime.now();
      await _supabase.from(_tableName).update({
        'display_name': displayName,
        'updated_at': now.toIso8601String(),
        'sync_updated_at': now.toIso8601String(),
      }).eq('id', userId);

      AppLogger.instance.i('displayNameを更新しました: $userId -> $displayName');
    } catch (error, stackTrace) {
      AppLogger.instance.e('displayName更新に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// longestStreakを取得
  ///
  /// usersテーブルからlongest_streakを取得します。
  /// ユーザーが存在しない場合やlongest_streakが未設定の場合は0を返します。
  Future<int> getLongestStreak(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('longest_streak')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        AppLogger.instance.i('ユーザーが存在しません: $userId');
        return 0;
      }

      final longestStreak = response['longest_streak'] as int? ?? 0;
      AppLogger.instance.i('longestStreakを取得しました: $longestStreak');
      return longestStreak;
    } catch (error, stackTrace) {
      AppLogger.instance.e('longestStreak取得に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// longestStreakを更新
  ///
  /// usersテーブルのlongest_streakを更新します。
  Future<void> updateLongestStreak(String userId, int longestStreak) async {
    try {
      final now = DateTime.now();
      await _supabase.from(_tableName).update({
        'longest_streak': longestStreak,
        'updated_at': now.toIso8601String(),
        'sync_updated_at': now.toIso8601String(),
      }).eq('id', userId);

      AppLogger.instance.i('longestStreakを更新しました: $userId -> $longestStreak');
    } catch (error, stackTrace) {
      AppLogger.instance.e('longestStreak更新に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// streakReminderEnabledを取得
  ///
  /// usersテーブルからstreak_reminder_enabledを取得します。
  /// ユーザーが存在しない場合やstreak_reminder_enabledが未設定の場合はtrueを返します。
  Future<bool> getStreakReminderEnabled(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('streak_reminder_enabled')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        AppLogger.instance.i('ユーザーが存在しません: $userId');
        return true; // デフォルト値
      }

      final enabled = response['streak_reminder_enabled'] as bool? ?? true;
      AppLogger.instance.i('streakReminderEnabledを取得しました: $enabled');
      return enabled;
    } catch (error, stackTrace) {
      AppLogger.instance.e('streakReminderEnabled取得に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// streakReminderEnabledを更新
  ///
  /// usersテーブルのstreak_reminder_enabledを更新します。
  Future<void> updateStreakReminderEnabled(String userId, bool enabled) async {
    try {
      final now = DateTime.now();
      await _supabase.from(_tableName).update({
        'streak_reminder_enabled': enabled,
        'updated_at': now.toIso8601String(),
        'sync_updated_at': now.toIso8601String(),
      }).eq('id', userId);

      AppLogger.instance.i(
          'streakReminderEnabledを更新しました: $userId -> ${enabled ? "有効" : "無効"}');
    } catch (error, stackTrace) {
      AppLogger.instance.e('streakReminderEnabled更新に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// アカウントが存在するか確認
  ///
  /// usersテーブルでemail + providerの組み合わせが存在するか確認します。
  /// Google/Appleは別アカウント扱いのため、両方の条件でチェックします。
  /// RLSをバイパスするため、SECURITY DEFINER関数を使用しています。
  Future<bool> checkAccountExists({
    required String email,
    required String provider,
  }) async {
    try {
      // RLSをバイパスするため、SECURITY DEFINER関数を呼び出す
      final response = await _supabase.rpc(
        'check_account_exists',
        params: {
          'p_email': email,
          'p_provider': provider,
        },
      );

      final exists = response as bool;
      AppLogger.instance.i(
        'アカウント存在チェック: email=$email, provider=$provider, exists=$exists',
      );
      return exists;
    } catch (error, stackTrace) {
      AppLogger.instance.e('アカウント存在チェックに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// emailとproviderをupsert
  ///
  /// 連携成功時にemailとproviderを保存します。
  /// レコードが存在すれば更新、存在しなければ作成します。
  Future<void> upsertEmailAndProvider({
    required String userId,
    required String email,
    required String provider,
  }) async {
    try {
      final now = DateTime.now();
      await _supabase.from(_tableName).upsert({
        'id': userId,
        'email': email,
        'provider': provider,
        'updated_at': now.toIso8601String(),
        'sync_updated_at': now.toIso8601String(),
      });

      AppLogger.instance.i(
        'emailとproviderをupsertしました: userId=$userId, email=$email, provider=$provider',
      );
    } catch (error, stackTrace) {
      AppLogger.instance.e('emailとproviderのupsertに失敗しました', error, stackTrace);
      rethrow;
    }
  }
}
