import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_devices/user_devices_model.dart';
import '../../utils/app_logger.dart';

/// Supabase user_devicesテーブルを操作するDataSource
///
/// 1ユーザーに紐づく複数の端末トークン（FCMトークン）を管理する。
/// マルチデバイス対応のため、(user_id, fcm_token)のUNIQUE制約で
/// 同一端末の二重登録を防ぐ。
class SupabaseUserDevicesDatasource {
  final SupabaseClient _supabase;

  static const String _tableName = 'user_devices';

  SupabaseUserDevicesDatasource({required SupabaseClient supabase})
      : _supabase = supabase;

  /// デバイスを作成または更新
  ///
  /// (user_id, fcm_token)のUNIQUE制約により、同一トークンが既に存在する場合は
  /// レコードが更新される。
  ///
  /// 時刻系カラム（created_at / updated_at / last_active_at）はクライアント時刻が
  /// 信頼できないため一切送信せず、サーバー側のDEFAULT NOW()およびトリガー
  /// （update_user_devices_timestamps_trigger）で自動設定する。
  Future<UserDevicesModel> upsertDevice(UserDevicesModel device) async {
    try {
      // 時刻系・nullフィールドはサーバー側に任せるため除外する
      final payload = device.toJson()
        ..removeWhere((key, value) => value == null);

      final response = await _supabase
          .from(_tableName)
          .upsert(
            payload,
            onConflict: 'user_id,fcm_token',
          )
          .select()
          .single();

      AppLogger.instance.i(
        'デバイスをupsertしました: userId=${device.userId}, platform=${device.platform}',
      );
      return UserDevicesModel.fromJson(response);
    } catch (error, stackTrace) {
      AppLogger.instance.e('デバイスupsertに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 指定したFCMトークンのデバイスを削除
  ///
  /// ログアウト時など、特定の端末のトークンだけを削除したい場合に使用する。
  Future<void> deleteDeviceByToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', fcmToken);

      AppLogger.instance.i('デバイスを削除しました: userId=$userId');
    } catch (error, stackTrace) {
      AppLogger.instance.e('デバイス削除に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 指定したユーザーの全デバイスを削除
  ///
  /// アカウント削除時など、ユーザーに紐づくすべての端末トークンを
  /// 一括削除したい場合に使用する。
  Future<void> deleteAllDevicesByUser(String userId) async {
    try {
      await _supabase.from(_tableName).delete().eq('user_id', userId);

      AppLogger.instance.i('ユーザーの全デバイスを削除しました: userId=$userId');
    } catch (error, stackTrace) {
      AppLogger.instance.e('全デバイス削除に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 指定したユーザーのデバイス一覧を取得
  Future<List<UserDevicesModel>> fetchDevicesByUser(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map((map) => UserDevicesModel.fromJson(map as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.instance.e('デバイス一覧取得に失敗しました', error, stackTrace);
      rethrow;
    }
  }
}
