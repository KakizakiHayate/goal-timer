import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/utils/time_utils.dart';

void main() {
  group('TimeUtils 残り日数計算', () {
    test('calculateRemainingDays returns 1 when deadline is today', () {
      final today = DateTime.now();
      final deadline = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final result = TimeUtils.calculateRemainingDays(deadline);

      expect(result, 1);
    });

    test('calculateRemainingDays returns 3 when deadline is 2 days from now',
        () {
      final today = DateTime.now();
      final deadline = DateTime(today.year, today.month, today.day)
          .add(const Duration(days: 2));

      final result = TimeUtils.calculateRemainingDays(deadline);

      expect(result, 3); // 今日を含む
    });

    test('calculateRemainingDays returns 1 when deadline is past', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final deadline = DateTime(yesterday.year, yesterday.month, yesterday.day);

      final result = TimeUtils.calculateRemainingDays(deadline);

      expect(result, 1); // 最低1日
    });

    test('calculateRemainingDays returns 7 when deadline is 6 days from now',
        () {
      final today = DateTime.now();
      final deadline = DateTime(today.year, today.month, today.day)
          .add(const Duration(days: 6));

      final result = TimeUtils.calculateRemainingDays(deadline);

      expect(result, 7); // 今日を含む
    });
  });

  group('TimeUtils 総目標時間計算', () {
    test('calculateTotalTargetMinutes returns correct value', () {
      // 30分 × 10日 = 300分
      final result = TimeUtils.calculateTotalTargetMinutes(
        targetMinutes: 30,
        remainingDays: 10,
      );

      expect(result, 300);
    });

    test('calculateTotalTargetMinutes with minimum 1 day', () {
      // 60分 × 1日 = 60分
      final result = TimeUtils.calculateTotalTargetMinutes(
        targetMinutes: 60,
        remainingDays: 1,
      );

      expect(result, 60);
    });

    test('calculateTotalTargetMinutes with 0 days returns targetMinutes', () {
      // 残り0日でも最低1日分
      final result = TimeUtils.calculateTotalTargetMinutes(
        targetMinutes: 45,
        remainingDays: 0,
      );

      expect(result, 45); // 最低1日分
    });

    test('calculateTotalTargetMinutes with negative days returns targetMinutes',
        () {
      // 負の日数でも最低1日分
      final result = TimeUtils.calculateTotalTargetMinutes(
        targetMinutes: 30,
        remainingDays: -5,
      );

      expect(result, 30); // 最低1日分
    });
  });

  group('期限バリデーション', () {
    test('isValidDeadline accepts today', () {
      final today = DateTime.now();
      final deadline = DateTime(today.year, today.month, today.day);

      final result = TimeUtils.isValidDeadline(deadline);

      expect(result, true);
    });

    test('isValidDeadline accepts future date', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final deadline =
          DateTime(futureDate.year, futureDate.month, futureDate.day);

      final result = TimeUtils.isValidDeadline(deadline);

      expect(result, true);
    });

    test('isValidDeadline rejects yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final deadline =
          DateTime(yesterday.year, yesterday.month, yesterday.day);

      final result = TimeUtils.isValidDeadline(deadline);

      expect(result, false);
    });
  });

  group('進捗計算', () {
    test('progress calculation uses totalTargetMinutes', () {
      // 150分学習、総目標300分 = 50%
      final progress = TimeUtils.calculateProgressRateFromMinutes(300, 150);

      expect(progress, 0.5);
    });

    test('progress calculation caps at 100%', () {
      // 400分学習、総目標300分 = 100%（最大値）
      final progress = TimeUtils.calculateProgressRateFromMinutes(300, 400);

      expect(progress, 1.0);
    });

    test('progress calculation with 0 target returns 100%', () {
      final progress = TimeUtils.calculateProgressRateFromMinutes(0, 100);

      expect(progress, 1.0);
    });
  });
}
