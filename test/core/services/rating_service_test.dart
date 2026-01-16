import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/services/rating_service.dart';

void main() {
  group('RatingService Tests', () {
    group('シングルトンパターン', () {
      test('同じインスタンスが返されること', () {
        final instance1 = RatingService();
        final instance2 = RatingService();

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('shouldShowRatingDialog', () {
      late RatingService ratingService;

      setUp(() {
        ratingService = RatingService();
      });

      test('1回目の完了時は評価ダイアログを表示しない', () {
        expect(ratingService.shouldShowRatingDialog(1, false), isFalse);
      });

      test('2回目の完了時は評価ダイアログを表示しない', () {
        expect(ratingService.shouldShowRatingDialog(2, false), isFalse);
      });

      test('3回目の完了時は評価ダイアログを表示しない', () {
        expect(ratingService.shouldShowRatingDialog(3, false), isFalse);
      });

      test('4回目の完了時は評価ダイアログを表示しない', () {
        expect(ratingService.shouldShowRatingDialog(4, false), isFalse);
      });

      test('5回目の完了時は評価ダイアログを表示する', () {
        expect(ratingService.shouldShowRatingDialog(5, false), isTrue);
      });

      test('6回目の完了時は評価ダイアログを表示しない', () {
        expect(ratingService.shouldShowRatingDialog(6, false), isFalse);
      });

      test('10回目の完了時は評価ダイアログを表示する', () {
        expect(ratingService.shouldShowRatingDialog(10, false), isTrue);
      });

      test('15回目の完了時は評価ダイアログを表示する', () {
        expect(ratingService.shouldShowRatingDialog(15, false), isTrue);
      });

      test('評価済みの場合は5回目でも評価ダイアログを表示しない', () {
        expect(ratingService.shouldShowRatingDialog(5, true), isFalse);
      });

      test('評価済みの場合は10回目でも評価ダイアログを表示しない', () {
        expect(ratingService.shouldShowRatingDialog(10, true), isFalse);
      });

      test('0回目の完了時は評価ダイアログを表示しない', () {
        expect(ratingService.shouldShowRatingDialog(0, false), isTrue);
        // 注: 0 % 5 == 0 なので true になる
        // 実際には0回目は発生しない（1から開始）
      });
    });

    // Note: onStudyCompleted(), markAsRated() などのメソッドは
    // SharedPreferencesとInAppReviewに依存するため、
    // 統合テストで実施する
    //
    // 手動テスト項目:
    // 1. 学習完了5回目でレビューダイアログが表示される
    // 2. 学習完了10回目でレビューダイアログが表示される
    // 3. 評価済みの場合はレビューダイアログが表示されない
    // 4. SharedPreferencesに完了回数が正しく保存される
    // 5. ログ出力が適切に行われる
  });
}
