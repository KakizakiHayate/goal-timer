import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/utils/streak_reminder_consts.dart';

void main() {
  group('StreakReminderConsts Tests', () {
    group('calculateNotificationId', () {
      test('正しい通知IDを計算できること', () {
        // 1月15日のリマインダー通知ID
        final date = DateTime(2024, 1, 15);
        final id = StreakReminderConsts.calculateNotificationId(
          StreakReminderConsts.reminderIdBase,
          date,
        );
        // 1000 + (1 * 100 + 15) = 1000 + 115 = 1115
        expect(id, equals(1115));
      });

      test('12月31日の警告通知IDを計算できること', () {
        final date = DateTime(2024, 12, 31);
        final id = StreakReminderConsts.calculateNotificationId(
          StreakReminderConsts.warningIdBase,
          date,
        );
        // 2000 + (12 * 100 + 31) = 2000 + 1231 = 3231
        expect(id, equals(3231));
      });

      test('最終警告通知IDを計算できること', () {
        final date = DateTime(2024, 6, 1);
        final id = StreakReminderConsts.calculateNotificationId(
          StreakReminderConsts.finalWarningIdBase,
          date,
        );
        // 3000 + (6 * 100 + 1) = 3000 + 601 = 3601
        expect(id, equals(3601));
      });

      test('同じ日付でも通知タイプごとに異なるIDになること', () {
        final date = DateTime(2024, 3, 20);
        final reminderId = StreakReminderConsts.calculateNotificationId(
          StreakReminderConsts.reminderIdBase,
          date,
        );
        final warningId = StreakReminderConsts.calculateNotificationId(
          StreakReminderConsts.warningIdBase,
          date,
        );
        final finalWarningId = StreakReminderConsts.calculateNotificationId(
          StreakReminderConsts.finalWarningIdBase,
          date,
        );

        expect(reminderId, equals(1320)); // 1000 + 320
        expect(warningId, equals(2320)); // 2000 + 320
        expect(finalWarningId, equals(3320)); // 3000 + 320

        // 全て異なるIDであること
        expect(reminderId, isNot(equals(warningId)));
        expect(warningId, isNot(equals(finalWarningId)));
        expect(reminderId, isNot(equals(finalWarningId)));
      });
    });

    group('getReminderMessage', () {
      test('ストリーク日数が0の場合は専用メッセージを返すこと', () {
        final message = StreakReminderConsts.getReminderMessage(0);
        expect(message, equals(StreakReminderConsts.reminderMessageNoStreak));
      });

      test('ストリーク日数がマイナスの場合も専用メッセージを返すこと', () {
        final message = StreakReminderConsts.getReminderMessage(-1);
        expect(message, equals(StreakReminderConsts.reminderMessageNoStreak));
      });

      test('ストリーク日数が正の場合は日数を含むメッセージを返すこと', () {
        final message = StreakReminderConsts.getReminderMessage(5);
        expect(message, contains('5'));
        expect(message, contains('連続'));
      });

      test('ストリーク日数が大きい場合も正しく変換されること', () {
        final message = StreakReminderConsts.getReminderMessage(100);
        expect(message, contains('100'));
      });
    });

    group('getWarningMessage', () {
      test('ストリーク日数が0の場合は専用メッセージを返すこと', () {
        final message = StreakReminderConsts.getWarningMessage(0);
        expect(message, equals(StreakReminderConsts.warningMessageNoStreak));
      });

      test('ストリーク日数が正の場合は日数を含むメッセージを返すこと', () {
        final message = StreakReminderConsts.getWarningMessage(10);
        expect(message, contains('10'));
        expect(message, contains('連続学習'));
      });
    });

    group('getFinalWarningMessage', () {
      test('ストリーク日数が0の場合は専用メッセージを返すこと', () {
        final message = StreakReminderConsts.getFinalWarningMessage(0);
        expect(
          message,
          equals(StreakReminderConsts.finalWarningMessageNoStreak),
        );
      });

      test('ストリーク日数が正の場合は日数を含むメッセージを返すこと', () {
        final message = StreakReminderConsts.getFinalWarningMessage(30);
        expect(message, contains('30'));
      });
    });

    group('定数値の検証', () {
      test('通知時刻が正しく設定されていること', () {
        expect(StreakReminderConsts.reminderHour, equals(20));
        expect(StreakReminderConsts.warningHour, equals(21));
        expect(StreakReminderConsts.finalWarningHour, equals(23));
        expect(StreakReminderConsts.notificationMinute, equals(0));
      });

      test('通知IDベースが重複しないこと', () {
        expect(StreakReminderConsts.reminderIdBase, equals(1000));
        expect(StreakReminderConsts.warningIdBase, equals(2000));
        expect(StreakReminderConsts.finalWarningIdBase, equals(3000));
      });

      test('デフォルトでリマインダーが有効であること', () {
        expect(StreakReminderConsts.defaultReminderEnabled, isTrue);
      });
    });
  });
}
