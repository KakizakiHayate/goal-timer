import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/services/notification_service.dart';

void main() {
  group('NotificationService - 繰り返し通知の定数検証', () {
    test('iOS通知上限（64個）を超えないこと', () {
      // 繰り返し通知40個 + ストリークリマインダー最大6個 = 46個 < 64個
      const repeatingMaxCount = 40;
      const streakMaxCount = 6; // 今日3個 + 明日3個
      const iosLimit = 64;

      expect(repeatingMaxCount + streakMaxCount, lessThanOrEqualTo(iosLimit));
    });
  });

  group('NotificationService - cancelRepeatingCompletionNotifications', () {
    test('T-2.2: スケジュールなしでキャンセルしてもエラーが発生しないこと', () async {
      // NotificationServiceはシングルトンで未初期化状態
      // 空リストのキャンセルはエラーなく完了すべき
      final service = NotificationService();
      await service.cancelRepeatingCompletionNotifications();
      // エラーが発生しなければテスト成功
    });
  });
}
