import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_statistics.freezed.dart';

/// ホーム画面の統計情報を格納するモデル
@freezed
class StudyStatistics with _$StudyStatistics {
  const factory StudyStatistics({
    /// 今日の進捗率（0.0 - 1.0）
    @Default(0.0) double todayProgress,

    /// 今日の学習時間（分）
    @Default(0) int totalMinutes,

    /// 今日の目標時間（分）
    @Default(0) int targetMinutes,

    /// 連続学習日数（ストリーク）
    @Default(0) int currentStreak,

    /// 総目標数
    @Default(0) int totalGoals,

    /// 完了済み目標数
    @Default(0) int completedGoals,

    /// 今日の残り時間（分）
    @Default(0) int remainingMinutes,

    /// データ更新日時
    DateTime? lastUpdated,
  }) = _StudyStatistics;

  /// 空の統計データを生成
  factory StudyStatistics.empty() => const StudyStatistics();
}

extension StudyStatisticsExtension on StudyStatistics {
  /// 進捗率を百分率で取得
  int get progressPercentage => (todayProgress * 100).toInt();

  /// 目標達成率を計算
  double get goalCompletionRate {
    if (totalGoals == 0) return 0.0;
    return completedGoals / totalGoals;
  }

  /// 平均集中時間を計算（分）
  int get averageStudyTime {
    if (totalGoals == 0) return 0;
    return (totalMinutes / totalGoals).toInt();
  }

  /// 今日の目標達成済みかどうか
  bool get isTargetAchieved => todayProgress >= 1.0;

  /// モチベーショナルメッセージを取得
  String get motivationalMessage {
    if (isTargetAchieved) {
      return '今日の目標達成！素晴らしいです！';
    } else if (todayProgress >= 0.8) {
      return 'もう少しで達成です！';
    } else if (todayProgress >= 0.5) {
      return '順調に進んでいます';
    } else if (todayProgress >= 0.3) {
      return '良いスタートです';
    } else {
      return '今日も頑張りましょう！';
    }
  }
}
