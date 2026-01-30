import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_consts.dart';
import '../../utils/app_logger.dart';
import '../../utils/time_utils.dart';

/// 設定データのローカルDataSource
/// SharedPreferencesを使用して設定を永続化
class LocalSettingsDataSource {
  static const String _keyDefaultTimerSeconds = 'default_timer_seconds';
  static const String _keyCountdownCompletionCount =
      'countdown_completion_count';
  static const String _keyLastFeedbackDismissedAt =
      'last_feedback_dismissed_at';

  // タイマー設定の定数
  static const int _defaultTimerMinutes = 25;
  static const int _minTimerMinutes = 1;
  static const int _maxTimerHours = 24;

  // 秒単位に変換した定数（外部公開用）
  static const int defaultTimerSeconds =
      _defaultTimerMinutes * TimeUtils.secondsPerMinute;
  static const int minTimerSeconds =
      _minTimerMinutes * TimeUtils.secondsPerMinute;
  static const int maxTimerSeconds = _maxTimerHours * TimeUtils.secondsPerHour;

  /// デフォルトタイマー時間を取得
  Future<int> fetchDefaultTimerSeconds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_keyDefaultTimerSeconds);
      if (stored != null &&
          stored >= minTimerSeconds &&
          stored <= maxTimerSeconds) {
        AppLogger.instance.i('デフォルトタイマー時間を読み込みました: $stored秒');
        return stored;
      }
      return defaultTimerSeconds;
    } catch (error, stackTrace) {
      AppLogger.instance.e('デフォルトタイマー時間の読み込みに失敗しました', error, stackTrace);
      return defaultTimerSeconds;
    }
  }

  /// デフォルトタイマー時間を保存
  Future<void> saveDefaultTimerSeconds(int seconds) async {
    try {
      final clampedSeconds = seconds.clamp(minTimerSeconds, maxTimerSeconds);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDefaultTimerSeconds, clampedSeconds);
      AppLogger.instance.i('デフォルトタイマー時間を保存しました: $clampedSeconds秒');
    } catch (error, stackTrace) {
      AppLogger.instance.e('デフォルトタイマー時間の保存に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  // === フィードバック関連 ===

  /// カウントダウン完了カウントを取得
  Future<int> fetchCountdownCompletionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyCountdownCompletionCount) ?? 0;
    } catch (error, stackTrace) {
      AppLogger.instance.e('カウントダウン完了カウントの読み込みに失敗しました', error, stackTrace);
      return 0;
    }
  }

  /// カウントダウン完了カウントをインクリメント
  Future<int> incrementCountdownCompletionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_keyCountdownCompletionCount) ?? 0;
      final newCount = currentCount + 1;
      await prefs.setInt(_keyCountdownCompletionCount, newCount);
      AppLogger.instance.i('カウントダウン完了カウントを更新しました: $newCount');
      return newCount;
    } catch (error, stackTrace) {
      AppLogger.instance.e('カウントダウン完了カウントの更新に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// カウントダウン完了カウントをリセット
  Future<void> resetCountdownCompletionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCountdownCompletionCount, 0);
      AppLogger.instance.i('カウントダウン完了カウントをリセットしました');
    } catch (error, stackTrace) {
      AppLogger.instance.e('カウントダウン完了カウントのリセットに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 最終フィードバック非表示日時を取得
  Future<DateTime?> fetchLastFeedbackDismissedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_keyLastFeedbackDismissedAt);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (error, stackTrace) {
      AppLogger.instance.e('最終フィードバック非表示日時の読み込みに失敗しました', error, stackTrace);
      return null;
    }
  }

  /// 最終フィードバック非表示日時を保存
  Future<void> saveLastFeedbackDismissedAt(DateTime dateTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyLastFeedbackDismissedAt,
        dateTime.toIso8601String(),
      );
      AppLogger.instance.i('最終フィードバック非表示日時を保存しました: $dateTime');
    } catch (error, stackTrace) {
      AppLogger.instance.e('最終フィードバック非表示日時の保存に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// フィードバックポップアップを表示すべきかどうかを判定
  ///
  /// 条件:
  /// 1. カウントダウン完了カウントが[AppConsts.feedbackPopupInterval]の倍数
  /// 2. 最終非表示日時から[AppConsts.feedbackPopupCooldownDays]日以上経過
  Future<bool> shouldShowFeedbackPopup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_keyCountdownCompletionCount) ?? 0;

      // 条件1: カウントが表示間隔の倍数でなければ表示しない
      if (count == 0 || count % AppConsts.feedbackPopupInterval != 0) {
        return false;
      }

      // 条件2: クールダウン期間をチェック
      final lastDismissedStr = prefs.getString(_keyLastFeedbackDismissedAt);
      if (lastDismissedStr != null) {
        final lastDismissed = DateTime.parse(lastDismissedStr);
        final daysSinceDismissed =
            DateTime.now().difference(lastDismissed).inDays;
        if (daysSinceDismissed < AppConsts.feedbackPopupCooldownDays) {
          AppLogger.instance.i(
            'フィードバックポップアップはクールダウン中です: '
            '残り${AppConsts.feedbackPopupCooldownDays - daysSinceDismissed}日',
          );
          return false;
        }
      }

      AppLogger.instance.i('フィードバックポップアップを表示します（完了回数: $count）');
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('フィードバック表示判定に失敗しました', error, stackTrace);
      return false;
    }
  }
}
