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
  static const String channelName = 'ストリークリマインダー';
  static const String channelDescription = '連続学習日数を維持するためのリマインダー通知';

  // 通知タイトル
  static const String reminderTitle = '今日も学習しましょう！';
  static const String warningTitle = 'ストリークが途切れそう！';
  static const String finalWarningTitle = '最後のチャンス！';

  // 通知メッセージテンプレート（%dはストリーク日数に置換される）
  static const String reminderMessage = '現在%d日連続で学習中です。今日も続けましょう！';
  static const String warningMessage = '%d日間の連続学習が途切れてしまいます！あと少しで1日終了です。';
  static const String finalWarningMessage = '%d日連続の記録を守りましょう！今日中に1分以上学習してください。';

  // ストリーク0日の場合のメッセージ
  static const String reminderMessageNoStreak = '今日から学習を始めましょう！';
  static const String warningMessageNoStreak = '今日も学習しませんか？まだ間に合います！';
  static const String finalWarningMessageNoStreak = '今日中に学習して、連続学習を始めましょう！';

  // デフォルト設定
  static const bool defaultReminderEnabled = true;

  /// 通知IDを計算する
  /// [baseId] - 1000/2000/3000のいずれか
  /// [date] - 通知を表示する日付
  static int calculateNotificationId(int baseId, DateTime date) {
    return baseId + (date.month * 100 + date.day);
  }

  /// ストリーク日数に応じたメッセージを取得する
  static String getReminderMessage(int streakDays) {
    if (streakDays <= 0) {
      return reminderMessageNoStreak;
    }
    return reminderMessage.replaceAll('%d', streakDays.toString());
  }

  static String getWarningMessage(int streakDays) {
    if (streakDays <= 0) {
      return warningMessageNoStreak;
    }
    return warningMessage.replaceAll('%d', streakDays.toString());
  }

  static String getFinalWarningMessage(int streakDays) {
    if (streakDays <= 0) {
      return finalWarningMessageNoStreak;
    }
    return finalWarningMessage.replaceAll('%d', streakDays.toString());
  }
}
