/// 時間関連のユーティリティクラス
class TimeUtils {
  /// 秒数を時間表示形式にフォーマット
  /// 60分以上の場合は HH:MM:SS 形式、それ以外は MM:SS 形式
  static String formatDurationFromSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 分数を時間表示形式にフォーマット
  /// 60分以上の場合は HH:MM:SS 形式（秒は00）、それ以外は「X分」形式
  static String formatDurationFromMinutes(int totalMinutes) {
    if (totalMinutes >= 60) {
      return formatDurationFromSeconds(totalMinutes * 60);
    } else {
      return '$totalMinutes分';
    }
  }

  /// 残り時間を計算（目標時間 - 消費時間）- 後方互換性のため残す
  static String calculateRemainingTime(int totalTargetHours, int spentMinutes) {
    // 目標時間を分に変換
    final targetMinutes = (totalTargetHours * 60);
    return calculateRemainingTimeFromMinutes(targetMinutes, spentMinutes);
  }

  /// 残り時間を計算（分単位で指定）
  static String calculateRemainingTimeFromMinutes(
    int targetMinutes,
    int spentMinutes,
  ) {
    // 残り分を計算
    final remainingMinutes = targetMinutes - spentMinutes;

    if (remainingMinutes <= 0) {
      return '0時間0分';
    }

    // 時間と分に変換
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;

    return '$hours時間$minutes分';
  }

  /// 残り時間（分）を計算 - 後方互換性のため残す
  static int calculateRemainingMinutes(int totalTargetHours, int spentMinutes) {
    final targetMinutes = (totalTargetHours * 60);
    return calculateRemainingMinutesFromTotal(targetMinutes, spentMinutes);
  }

  /// 残り時間（分）を計算（分単位で指定）
  static int calculateRemainingMinutesFromTotal(
    int targetMinutes,
    int spentMinutes,
  ) {
    return (targetMinutes - spentMinutes).clamp(0, double.infinity).toInt();
  }

  /// 目標進捗率を計算（0.0 〜 1.0）- 後方互換性のため残す
  static double calculateProgressRate(int totalTargetHours, int spentMinutes) {
    final targetMinutes = totalTargetHours * 60;
    return calculateProgressRateFromMinutes(targetMinutes, spentMinutes);
  }

  /// 目標進捗率を計算（0.0 〜 1.0）（分単位で指定）
  static double calculateProgressRateFromMinutes(
    int targetMinutes,
    int spentMinutes,
  ) {
    if (targetMinutes <= 0) return 1.0;
    return (spentMinutes / targetMinutes).clamp(0.0, 1.0);
  }
}
