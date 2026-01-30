import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/local_settings_datasource.dart';
import 'package:goal_timer/core/utils/app_consts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalSettingsDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dataSource = LocalSettingsDataSource();
  });

  group('LocalSettingsDataSource フィードバック機能テスト', () {
    group('fetchCountdownCompletionCount', () {
      test('初期値は0であること', () async {
        final count = await dataSource.fetchCountdownCompletionCount();
        expect(count, 0);
      });
    });

    group('incrementCountdownCompletionCount', () {
      test('カウントが1増加すること', () async {
        final newCount = await dataSource.incrementCountdownCompletionCount();
        expect(newCount, 1);

        final count = await dataSource.fetchCountdownCompletionCount();
        expect(count, 1);
      });

      test('複数回インクリメントできること', () async {
        await dataSource.incrementCountdownCompletionCount();
        await dataSource.incrementCountdownCompletionCount();
        final newCount = await dataSource.incrementCountdownCompletionCount();
        expect(newCount, 3);
      });
    });

    group('resetCountdownCompletionCount', () {
      test('カウントが0にリセットされること', () async {
        await dataSource.incrementCountdownCompletionCount();
        await dataSource.incrementCountdownCompletionCount();
        await dataSource.resetCountdownCompletionCount();

        final count = await dataSource.fetchCountdownCompletionCount();
        expect(count, 0);
      });
    });

    group('fetchLastFeedbackDismissedAt', () {
      test('初期値はnullであること', () async {
        final lastDismissed = await dataSource.fetchLastFeedbackDismissedAt();
        expect(lastDismissed, isNull);
      });
    });

    group('saveLastFeedbackDismissedAt', () {
      test('日時が正しく保存・取得できること', () async {
        final now = DateTime.now();
        await dataSource.saveLastFeedbackDismissedAt(now);

        final saved = await dataSource.fetchLastFeedbackDismissedAt();
        expect(saved, isNotNull);
        // ミリ秒の精度差を許容
        expect(
          saved!.difference(now).inSeconds.abs(),
          lessThanOrEqualTo(1),
        );
      });
    });

    group('shouldShowFeedbackPopup', () {
      test('カウントが0の場合はfalseを返すこと', () async {
        final shouldShow = await dataSource.shouldShowFeedbackPopup();
        expect(shouldShow, false);
      });

      test('カウントが1の場合はfalseを返すこと', () async {
        await dataSource.incrementCountdownCompletionCount();
        final shouldShow = await dataSource.shouldShowFeedbackPopup();
        expect(shouldShow, false);
      });

      test('カウントが2の場合はfalseを返すこと', () async {
        await dataSource.incrementCountdownCompletionCount();
        await dataSource.incrementCountdownCompletionCount();
        final shouldShow = await dataSource.shouldShowFeedbackPopup();
        expect(shouldShow, false);
      });

      test('カウントが3（feedbackPopupInterval）の場合はtrueを返すこと', () async {
        for (var i = 0; i < AppConsts.feedbackPopupInterval; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }
        final shouldShow = await dataSource.shouldShowFeedbackPopup();
        expect(shouldShow, true);
      });

      test('カウントが6（feedbackPopupInterval * 2）の場合はtrueを返すこと', () async {
        for (var i = 0; i < AppConsts.feedbackPopupInterval * 2; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }
        final shouldShow = await dataSource.shouldShowFeedbackPopup();
        expect(shouldShow, true);
      });

      test('クールダウン期間中はfalseを返すこと', () async {
        // 3回カウントして条件を満たす
        for (var i = 0; i < AppConsts.feedbackPopupInterval; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }

        // 今日を非表示日時として記録
        await dataSource.saveLastFeedbackDismissedAt(DateTime.now());

        final shouldShow = await dataSource.shouldShowFeedbackPopup();
        expect(shouldShow, false);
      });

      test('クールダウン期間経過後はtrueを返すこと', () async {
        // 3回カウントして条件を満たす
        for (var i = 0; i < AppConsts.feedbackPopupInterval; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }

        // 8日前を非表示日時として記録（7日間のクールダウンを超過）
        final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
        await dataSource.saveLastFeedbackDismissedAt(eightDaysAgo);

        final shouldShow = await dataSource.shouldShowFeedbackPopup();
        expect(shouldShow, true);
      });

      test('ちょうど7日経過後はtrueを返すこと（7日間=0〜6日目が非表示）', () async {
        // 3回カウントして条件を満たす
        for (var i = 0; i < AppConsts.feedbackPopupInterval; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }

        // ちょうど7日前を非表示日時として記録
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        await dataSource.saveLastFeedbackDismissedAt(sevenDaysAgo);

        final shouldShow = await dataSource.shouldShowFeedbackPopup();
        // 7日間（0〜6日目）が経過したので表示可能
        expect(shouldShow, true);
      });

      test('6日経過はまだクールダウン中（falseを返す）', () async {
        // 3回カウントして条件を満たす
        for (var i = 0; i < AppConsts.feedbackPopupInterval; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }

        // 6日前を非表示日時として記録
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));
        await dataSource.saveLastFeedbackDismissedAt(sixDaysAgo);

        final shouldShow = await dataSource.shouldShowFeedbackPopup();
        // 6日目はまだクールダウン中
        expect(shouldShow, false);
      });
    });

    group('統合シナリオ', () {
      test('スキップ後7日以内に完了3回目はポップアップ非表示', () async {
        // 最初の3回完了でポップアップ表示
        for (var i = 0; i < AppConsts.feedbackPopupInterval; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }
        expect(await dataSource.shouldShowFeedbackPopup(), true);

        // スキップ（非表示日時を記録してカウントリセット）
        await dataSource.saveLastFeedbackDismissedAt(DateTime.now());
        await dataSource.resetCountdownCompletionCount();

        // さらに3回完了
        for (var i = 0; i < AppConsts.feedbackPopupInterval; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }

        // 7日以内なのでfalse
        expect(await dataSource.shouldShowFeedbackPopup(), false);
      });

      test('スキップ後7日経過後に完了3回目はポップアップ表示', () async {
        // 最初の3回完了でポップアップ表示
        for (var i = 0; i < AppConsts.feedbackPopupInterval; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }
        expect(await dataSource.shouldShowFeedbackPopup(), true);

        // 8日前にスキップ
        final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
        await dataSource.saveLastFeedbackDismissedAt(eightDaysAgo);
        await dataSource.resetCountdownCompletionCount();

        // さらに3回完了
        for (var i = 0; i < AppConsts.feedbackPopupInterval; i++) {
          await dataSource.incrementCountdownCompletionCount();
        }

        // 7日経過後なのでtrue
        expect(await dataSource.shouldShowFeedbackPopup(), true);
      });
    });
  });
}
