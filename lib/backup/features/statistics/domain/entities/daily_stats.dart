/// 日別の統計情報を表すエンティティ
class DailyStats {
  /// 日付
  final DateTime date;

  /// その日の総学習時間（分）
  final int totalMinutes;

  /// 目標ごとの学習時間
  final Map<String, int> goalMinutes;

  /// 目標ごとの目標名
  final Map<String, String> goalTitles;

  DailyStats({
    required this.date,
    required this.totalMinutes,
    required this.goalMinutes,
    required this.goalTitles,
  });

  /// 学習した目標の数を取得
  int get goalCount => goalMinutes.keys.length;

  /// 特定の目標の学習時間を取得
  int getGoalMinutes(String goalId) {
    return goalMinutes[goalId] ?? 0;
  }

  /// 総学習時間を時間と分に変換（例：2時間30分）
  String get formattedTotalTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '$hours時間${minutes > 0 ? '$minutes分' : ''}';
    } else {
      return '$minutes分';
    }
  }
}
