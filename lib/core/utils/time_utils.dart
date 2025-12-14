/// 時間関連のユーティリティクラス
class TimeUtils {
  // 時間変換の定数
  static const int secondsPerMinute = 60;
  static const int minutesPerHour = 60;
  static const int secondsPerHour = secondsPerMinute * minutesPerHour;

  // しきい値の定数
  static const int hoursThresholdForExtendedFormat = 1;
  static const int minutesThresholdForExtendedFormat = 60;

  // バリデーション用の定数
  static const int minValidMinutes = 0;
  static const int minValidSeconds = 0;

  /// 秒数を時間表示形式にフォーマット
  /// 60分以上の場合は HH:MM:SS 形式、それ以外は MM:SS 形式
  static String formatDurationFromSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ secondsPerHour;
    final minutes = (totalSeconds % secondsPerHour) ~/ secondsPerMinute;
    final seconds = totalSeconds % secondsPerMinute;

    if (hours >= hoursThresholdForExtendedFormat) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 分数を時間表示形式にフォーマット
  /// 60分以上の場合は HH:MM:SS 形式（秒は00）、それ以外は「X分」形式
  static String formatDurationFromMinutes(int totalMinutes) {
    if (totalMinutes >= minutesThresholdForExtendedFormat) {
      return formatDurationFromSeconds(totalMinutes * secondsPerMinute);
    } else {
      return '$totalMinutes分';
    }
  }

  /// 分数を「X時間Y分」形式にフォーマット
  /// 例: 90分 → "1時間30分", 30分 → "0時間30分"
  static String formatMinutesToHoursAndMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ minutesPerHour;
    final minutes = totalMinutes % minutesPerHour;
    return '$hours時間$minutes分';
  }

  /// 残り時間を計算（目標時間 - 消費時間）- 後方互換性のため残す
  static String calculateRemainingTime(int totalTargetHours, int spentMinutes) {
    // 目標時間を分に変換
    final targetMinutes = totalTargetHours * minutesPerHour;
    return calculateRemainingTimeFromMinutes(targetMinutes, spentMinutes);
  }

  /// 残り時間を計算（分単位で指定）
  static String calculateRemainingTimeFromMinutes(
    int targetMinutes,
    int spentMinutes,
  ) {
    // 残り分を計算
    final remainingMinutes = targetMinutes - spentMinutes;

    if (remainingMinutes <= minValidMinutes) {
      return '${minValidMinutes}時間${minValidMinutes}分';
    }

    // 時間と分に変換
    final hours = remainingMinutes ~/ minutesPerHour;
    final minutes = remainingMinutes % minutesPerHour;

    return '$hours時間$minutes分';
  }

  /// 残り時間（分）を計算 - 後方互換性のため残す
  static int calculateRemainingMinutes(int totalTargetHours, int spentMinutes) {
    final targetMinutes = totalTargetHours * minutesPerHour;
    return calculateRemainingMinutesFromTotal(targetMinutes, spentMinutes);
  }

  /// 残り時間（分）を計算（分単位で指定）
  static int calculateRemainingMinutesFromTotal(
    int targetMinutes,
    int spentMinutes,
  ) {
    return (targetMinutes - spentMinutes).clamp(minValidMinutes, double.infinity).toInt();
  }

  /// 目標進捗率を計算（0.0 〜 1.0）- 後方互換性のため残す
  static double calculateProgressRate(int totalTargetHours, int spentMinutes) {
    final targetMinutes = totalTargetHours * minutesPerHour;
    return calculateProgressRateFromMinutes(targetMinutes, spentMinutes);
  }

  /// 目標進捗率を計算（0.0 〜 1.0）（分単位で指定）
  static double calculateProgressRateFromMinutes(
    int targetMinutes,
    int spentMinutes,
  ) {
    if (targetMinutes <= minValidMinutes) return 1.0;
    return (spentMinutes / targetMinutes).clamp(0.0, 1.0);
  }
}
