import 'locale_helper.dart';

/// ストリークリマインダー通知の定数
class StreakReminderConsts {
  // 通知時刻（時）
  static const int reminderHour = 20;
  static const int warningHour = 21;
  static const int finalWarningHour = 23;

  // 通知時刻（分）- 全て0分
  static const int notificationMinute = 0;

  // 通知ID計算用のベース値
  static const int reminderIdBase = 1000;
  static const int warningIdBase = 2000;
  static const int finalWarningIdBase = 3000;

  // 通知チャンネルID
  static const String channelId = 'streak_reminder';

  /// 通知チャンネル名（ロケール対応）
  static String get channelName =>
      LocaleHelper.isJapanese ? 'ストリークリマインダー' : 'Streak Reminder';

  /// 通知チャンネル説明（ロケール対応）
  static String get channelDescription => LocaleHelper.isJapanese
      ? '連続学習日数を維持するためのリマインダー通知'
      : 'Reminders to maintain your study streak';

  /// リマインダータイトル（ロケール対応）
  static String get reminderTitle =>
      LocaleHelper.isJapanese ? '今日も学習しましょう！' : "Let's study today!";

  /// 警告タイトル（ロケール対応）
  static String get warningTitle =>
      LocaleHelper.isJapanese ? 'ストリークが途切れそう！' : 'Your streak is at risk!';

  /// 最終警告タイトル（ロケール対応）
  static String get finalWarningTitle =>
      LocaleHelper.isJapanese ? '最後のチャンス！' : 'Last chance!';

  // デフォルト設定
  static const bool defaultReminderEnabled = true;

  /// 通知IDを計算する
  /// [baseId] - 1000/2000/3000のいずれか
  /// [date] - 通知を表示する日付
  static int calculateNotificationId(int baseId, DateTime date) {
    return baseId + (date.month * 100 + date.day);
  }

  /// ストリーク日数に応じたリマインダーメッセージを取得する
  static String getReminderMessage(int streakDays) {
    if (streakDays <= 0) {
      return LocaleHelper.isJapanese
          ? '今日から学習を始めましょう！'
          : 'Start studying today!';
    }
    return LocaleHelper.isJapanese
        ? '現在$streakDays日連続で学習中です。今日も続けましょう！'
        : "You've studied $streakDays ${streakDays == 1 ? 'day' : 'days'} in a row. Keep it up!";
  }

  /// ストリーク日数に応じた警告メッセージを取得する
  static String getWarningMessage(int streakDays) {
    if (streakDays <= 0) {
      return LocaleHelper.isJapanese
          ? '今日も学習しませんか？まだ間に合います！'
          : "How about studying today? There's still time!";
    }
    return LocaleHelper.isJapanese
        ? '$streakDays日間の連続学習が途切れてしまいます！あと少しで1日終了です。'
        : 'Your $streakDays-${streakDays == 1 ? 'day' : 'day'} streak will break! The day is almost over.';
  }

  /// ストリーク日数に応じた最終警告メッセージを取得する
  static String getFinalWarningMessage(int streakDays) {
    if (streakDays <= 0) {
      return LocaleHelper.isJapanese
          ? '今日中に学習して、連続学習を始めましょう！'
          : 'Study today to start your streak!';
    }
    return LocaleHelper.isJapanese
        ? '$streakDays日連続の記録を守りましょう！今日中に1分以上学習してください。'
        : 'Protect your $streakDays-${streakDays == 1 ? 'day' : 'day'} streak! Study for at least 1 minute today.';
  }
}
