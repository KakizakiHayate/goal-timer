import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';
import 'package:goal_timer/features/statistics/domain/entities/statistics.dart';
import 'package:goal_timer/features/statistics/domain/entities/daily_stats.dart';

/// 統計機能テスト用のモックデータ生成ヘルパー
class StatisticsTestData {
  static const String goal1Id = 'goal-1';
  static const String goal2Id = 'goal-2';
  static const String goal3Id = 'goal-3';

  /// テスト用の目標データ
  static List<GoalsModel> get mockGoals => [
    GoalsModel(
      id: goal1Id,
      userId: 'user-1',
      title: '英語学習',
      description: 'TOEIC対策',
      targetMinutes: 420,
      spentMinutes: 420,
      deadline: DateTime(2025, 12, 31),
      isCompleted: false,
      avoidMessage: 'TOEICスコアが上がらない',
    ),
    GoalsModel(
      id: goal2Id,
      userId: 'user-1',
      title: 'プログラミング',
      description: 'Flutter開発スキル向上',
      targetMinutes: 300,
      spentMinutes: 225,
      deadline: DateTime(2025, 12, 31),
      isCompleted: false,
      avoidMessage: 'スキルアップできない',
    ),
    GoalsModel(
      id: goal3Id,
      userId: 'user-1',
      title: '資格勉強',
      description: 'IT資格取得',
      targetMinutes: 200,
      spentMinutes: 90,
      deadline: DateTime(2025, 12, 31),
      isCompleted: true,
      avoidMessage: '資格取得できない',
    ),
  ];

  /// 今週の学習記録データ（連続7日）
  static List<DailyStudyLogModel> get thisWeekStudyLogs {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return [
      // 英語学習 - 毎日60分 (7日 × 60分 = 420分)
      ...List.generate(7, (index) => DailyStudyLogModel(
        id: 'log-current-week-goal1-$index',
        goalId: goal1Id,
        minutes: 60,
        date: startOfWeek.add(Duration(days: index)),
      )),
      
      // プログラミング - 平日のみ45分 (5日 × 45分 = 225分)
      ...List.generate(5, (index) => DailyStudyLogModel(
        id: 'log-current-week-goal2-$index',
        goalId: goal2Id,
        minutes: 45,
        date: startOfWeek.add(Duration(days: index)),
      )),
      
      // 資格勉強 - 3日間のみ30分 (3日 × 30分 = 90分)
      ...List.generate(3, (index) => DailyStudyLogModel(
        id: 'log-current-week-goal3-$index',
        goalId: goal3Id,
        minutes: 30,
        date: startOfWeek.add(Duration(days: index)),
      )),
    ];
  }

  /// 先週の学習記録データ（比較用）
  static List<DailyStudyLogModel> get lastWeekStudyLogs {
    final now = DateTime.now();
    final startOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
    
    return [
      // 英語学習 - 毎日30分 (7日 × 30分 = 210分)
      ...List.generate(7, (index) => DailyStudyLogModel(
        id: 'log-last-week-goal1-$index',
        goalId: goal1Id,
        minutes: 30,
        date: startOfLastWeek.add(Duration(days: index)),
      )),
      
      // プログラミング - 4日間60分 (4日 × 60分 = 240分)
      ...List.generate(4, (index) => DailyStudyLogModel(
        id: 'log-last-week-goal2-$index',
        goalId: goal2Id,
        minutes: 60,
        date: startOfLastWeek.add(Duration(days: index)),
      )),
      
      // 資格勉強 - 学習記録なし (0分)
    ];
  }

  /// 全ての学習記録データ
  static List<DailyStudyLogModel> get allStudyLogs => [
    ...thisWeekStudyLogs,
    ...lastWeekStudyLogs,
  ];

  /// 継続日数テスト用データ（連続7日間）
  static List<DailyStudyLogModel> get consecutiveStudyLogs {
    final now = DateTime.now();
    return List.generate(7, (index) => DailyStudyLogModel(
      id: 'consecutive-log-$index',
      goalId: goal1Id,
      minutes: 30,
      date: now.subtract(Duration(days: 6 - index)),
    ));
  }

  /// 継続が中断されたテスト用データ
  static List<DailyStudyLogModel> get brokenStreakStudyLogs {
    final now = DateTime.now();
    return [
      // 今日
      DailyStudyLogModel(
        id: 'broken-streak-today',
        goalId: goal1Id,
        minutes: 30,
        date: now,
      ),
      // 昨日は記録なし
      // 一昨日
      DailyStudyLogModel(
        id: 'broken-streak-2-days-ago',
        goalId: goal1Id,
        minutes: 45,
        date: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// 空のデータ（学習記録なし）
  static List<DailyStudyLogModel> get emptyStudyLogs => [];

  /// 期待される計算結果

  /// 今週の総学習時間（分）
  static int get expectedThisWeekTotalMinutes => 735; // 420 + 225 + 90

  /// 今週の総学習時間（時間単位）
  static double get expectedThisWeekHours => 12.25; // 735 / 60

  /// 先週の総学習時間（分）
  static int get expectedLastWeekTotalMinutes => 450; // 210 + 240

  /// 先週の総学習時間（時間単位）
  static double get expectedLastWeekHours => 7.5; // 450 / 60

  /// 今週の平均集中時間（分）
  static int get expectedThisWeekAverageMinutes => 49; // 735 / 15セッション

  /// 今週の目標達成率（%）
  static int get expectedThisWeekAchievementRate => 100; // 3/3目標達成

  /// 先週の目標達成率（%）
  static int get expectedLastWeekAchievementRate => 67; // 2/3目標達成

  /// 学習時間の変化量（今週 vs 先週）
  static double get expectedStudyTimeChange => 4.75; // 12.25 - 7.5

  /// 達成率の変化量（今週 vs 先週）
  static int get expectedAchievementRateChange => 33; // 100 - 67

  /// 継続日数（連続データの場合）
  static int get expectedConsecutiveDays => 7;

  /// 継続日数（中断データの場合）
  static int get expectedBrokenStreakDays => 1; // 今日のみ

  /// 今週の期待される統計データ
  static Statistics get expectedThisWeekStatistics => Statistics(
    id: 'this-week',
    date: DateTime.now(),
    totalMinutes: expectedThisWeekTotalMinutes,
    goalCount: 3,
  );

  /// 先週の期待される統計データ
  static Statistics get expectedLastWeekStatistics => Statistics(
    id: 'last-week',
    date: DateTime.now().subtract(const Duration(days: 7)),
    totalMinutes: expectedLastWeekTotalMinutes,
    goalCount: 2,
  );

  /// 今週の期待される詳細統計データ
  static DailyStats get expectedThisWeekDailyStats => DailyStats(
    date: DateTime.now(),
    totalMinutes: expectedThisWeekTotalMinutes,
    goalMinutes: {
      goal1Id: 420, // 60×7
      goal2Id: 225, // 45×5  
      goal3Id: 90,  // 30×3
    },
    goalTitles: {
      goal1Id: '英語学習',
      goal2Id: 'プログラミング',
      goal3Id: '資格勉強',
    },
  );

  /// テストヘルパーメソッド

  /// 日付範囲内の学習記録をフィルタリング
  static List<DailyStudyLogModel> filterLogsByDateRange(
    List<DailyStudyLogModel> logs,
    DateTime startDate,
    DateTime endDate,
  ) {
    return logs.where((log) {
      return log.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          log.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// 特定の目標の学習記録をフィルタリング
  static List<DailyStudyLogModel> filterLogsByGoal(
    List<DailyStudyLogModel> logs,
    String goalId,
  ) {
    return logs.where((log) => log.goalId == goalId).toList();
  }

  /// 指定日の学習記録を取得
  static List<DailyStudyLogModel> getLogsForDate(
    List<DailyStudyLogModel> logs,
    DateTime date,
  ) {
    return logs.where((log) => 
      log.date.year == date.year &&
      log.date.month == date.month &&
      log.date.day == date.day
    ).toList();
  }

  /// 連続学習日数を計算
  static int calculateConsecutiveDays(List<DailyStudyLogModel> logs) {
    if (logs.isEmpty) return 0;

    final sortedLogs = logs.toList()..sort((a, b) => b.date.compareTo(a.date));
    final today = DateTime.now();
    int consecutiveDays = 0;

    for (int i = 0; i < sortedLogs.length; i++) {
      final expectedDate = today.subtract(Duration(days: i));
      final logDate = sortedLogs[i].date;
      
      if (logDate.year == expectedDate.year &&
          logDate.month == expectedDate.month &&
          logDate.day == expectedDate.day) {
        consecutiveDays++;
      } else {
        break;
      }
    }

    return consecutiveDays;
  }
}