import '../../l10n/app_localizations.dart';
import 'locale_helper.dart';

/// ストリークリマインダー通知の定数
class StreakReminderConsts {
  static AppLocalizations get _l10n =>
      lookupAppLocalizations(LocaleHelper.systemLocale);
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
  static String get channelName => _l10n.streakReminderChannelName;

  /// 通知チャンネル説明（ロケール対応）
  static String get channelDescription => _l10n.streakReminderChannelDescription;

  /// リマインダータイトル（ロケール対応）
  static String get reminderTitle => _l10n.reminderTitle;

  /// 警告タイトル（ロケール対応）
  static String get warningTitle => _l10n.warningTitle;

  /// 最終警告タイトル（ロケール対応）
  static String get finalWarningTitle => _l10n.finalWarningTitle;

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
      return _l10n.reminderNoStreak;
    }
    return _l10n.reminderMessage(streakDays);
  }

  /// ストリーク日数に応じた警告メッセージを取得する
  static String getWarningMessage(int streakDays) {
    if (streakDays <= 0) {
      return _l10n.warningNoStreak;
    }
    return _l10n.warningMessage(streakDays);
  }

  /// ストリーク日数に応じた最終警告メッセージを取得する
  static String getFinalWarningMessage(int streakDays) {
    if (streakDays <= 0) {
      return _l10n.finalWarningNoStreak;
    }
    return _l10n.finalWarningMessage(streakDays);
  }
}
