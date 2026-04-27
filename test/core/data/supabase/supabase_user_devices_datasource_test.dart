import 'package:flutter_test/flutter_test.dart';

import 'package:goal_timer/core/models/user_devices/user_devices_model.dart';

// Note: SupabaseUserDevicesDatasourceは SupabaseClient に直接依存するため、
// 完全なユニットテストは Integration Test もしくは実際の Supabase 接続が必要です。
// ここでは Model 周りの基本的な構造のみを検証します。

void main() {
  group('UserDevicesModel', () {
    test('JSONからモデルを生成できる', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111111',
        'user_id': '22222222-2222-2222-2222-222222222222',
        'fcm_token': 'sample-fcm-token',
        'platform': 'ios',
        'device_name': 'iPhone 15',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
        'last_active_at': '2026-01-03T00:00:00.000Z',
      };

      final model = UserDevicesModel.fromJson(json);

      expect(model.id, '11111111-1111-1111-1111-111111111111');
      expect(model.userId, '22222222-2222-2222-2222-222222222222');
      expect(model.fcmToken, 'sample-fcm-token');
      expect(model.platform, 'ios');
      expect(model.deviceName, 'iPhone 15');
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);
      expect(model.lastActiveAt, isNotNull);
    });

    test('モデルからJSONに変換すると snake_case のキーになる', () {
      final model = UserDevicesModel(
        id: 'id-1',
        userId: 'user-1',
        fcmToken: 'token-1',
        platform: 'android',
      );

      final json = model.toJson();

      expect(json['user_id'], 'user-1');
      expect(json['fcm_token'], 'token-1');
      expect(json.containsKey('userId'), isFalse);
      expect(json.containsKey('fcmToken'), isFalse);
    });

    test('オプショナルなフィールドは省略可能', () {
      final model = UserDevicesModel(
        id: 'id-1',
        userId: 'user-1',
        fcmToken: 'token-1',
        platform: 'ios',
      );

      expect(model.deviceName, isNull);
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
      expect(model.lastActiveAt, isNull);
    });

    test('copyWithで一部フィールドだけ更新できる', () {
      final now = DateTime.now();
      final model = UserDevicesModel(
        id: 'id-1',
        userId: 'user-1',
        fcmToken: 'token-1',
        platform: 'ios',
      );

      final updated = model.copyWith(
        updatedAt: now,
        lastActiveAt: now,
      );

      expect(updated.id, 'id-1');
      expect(updated.userId, 'user-1');
      expect(updated.updatedAt, now);
      expect(updated.lastActiveAt, now);
    });
  });

  // 統合テストでの検証項目（実Supabase接続が必要）:
  // - upsertDeviceが (user_id, fcm_token) のUNIQUE制約を活かして
  //   既存トークンの場合はlast_active_atだけ更新する
  // - deleteDeviceByTokenが指定のトークンレコードを削除する
  // - deleteAllDevicesByUserがユーザー配下を全削除する
  // - fetchDevicesByUserが該当ユーザーの全デバイスを返す
  // - RLSにより他ユーザーのレコードは取得できない
}
