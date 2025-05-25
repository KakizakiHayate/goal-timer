/// 時間関連のユーティリティクラス
class TimeUtils {
  /// 残り時間を計算（目標時間 - 消費時間）
  static String calculateRemainingTime(int totalTargetHours, int spentMinutes) {
    // 目標時間を分に変換
    final targetMinutes = (totalTargetHours * 60);
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

  /// 残り時間（分）を計算
  static int calculateRemainingMinutes(int totalTargetHours, int spentMinutes) {
    final targetMinutes = (totalTargetHours * 60);
    return (targetMinutes - spentMinutes).clamp(0, double.infinity).toInt();
  }

  /// 目標進捗率を計算（0.0 〜 1.0）
  static double calculateProgressRate(int totalTargetHours, int spentMinutes) {
    final targetMinutes = totalTargetHours * 60;
    if (targetMinutes <= 0) return 1.0;

    return (spentMinutes / targetMinutes).clamp(0.0, 1.0);
  }
}
