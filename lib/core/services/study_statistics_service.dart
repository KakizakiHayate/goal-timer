import '../models/study_statistics.dart';
import '../data/repositories/users/users_repository.dart';
import '../data/repositories/daily_study_logs/daily_study_logs_repository.dart';
import '../data/repositories/goals/goals_repository.dart';
import '../utils/app_logger.dart';

/// 学習統計情報を計算するサービスクラス
class StudyStatisticsService {
  final UsersRepository _usersRepository;
  final DailyStudyLogsRepository _dailyStudyLogsRepository;
  final GoalsRepository _goalsRepository;

  StudyStatisticsService({
    required UsersRepository usersRepository,
    required DailyStudyLogsRepository dailyStudyLogsRepository,
    required GoalsRepository goalsRepository,
  }) : _usersRepository = usersRepository,
       _dailyStudyLogsRepository = dailyStudyLogsRepository,
       _goalsRepository = goalsRepository;

  /// 現在のユーザーの学習統計を取得
  Future<StudyStatistics> getCurrentUserStatistics() async {
    try {
      // 現在のユーザーを取得
      final currentUser = await _usersRepository.getCurrentUser();
      if (currentUser == null) {
        AppLogger.instance.w('現在のユーザーが見つかりません');
        return StudyStatistics.empty();
      }

      return await getUserStatistics(currentUser.id);
    } catch (e) {
      AppLogger.instance.e('統計データの取得に失敗しました', e);
      return StudyStatistics.empty();
    }
  }

  /// 指定されたユーザーの学習統計を取得
  Future<StudyStatistics> getUserStatistics(String userId) async {
    try {
      final today = DateTime.now();

      // 一度だけgoalsを取得
      final allGoals = await _goalsRepository.getGoals();
      final userGoals =
          allGoals.where((goal) => goal.userId == userId).toList();

      // 取得したgoalsを各メソッドに渡す
      final results = await Future.wait([
        _getTodayStudyMinutes(userId, today, userGoals),
        _getTodayTargetMinutes(userId, userGoals),
        _getCurrentStreak(userId, today, userGoals),
        _getGoalCounts(userId, userGoals),
      ]);

      final todayStudyMinutes = results[0] as int;
      final todayTargetMinutes = results[1] as int;
      final currentStreak = results[2] as int;
      final goalCounts = results[3] as Map<String, int>;

      // 進捗率を計算
      final todayProgress =
          todayTargetMinutes > 0
              ? (todayStudyMinutes / todayTargetMinutes).clamp(0.0, 1.0)
              : 0.0;

      return StudyStatistics(
        todayProgress: todayProgress,
        totalMinutes: todayStudyMinutes,
        targetMinutes: todayTargetMinutes,
        currentStreak: currentStreak,
        totalGoals: goalCounts['total'] ?? 0,
        completedGoals: goalCounts['completed'] ?? 0,
        remainingMinutes: (todayTargetMinutes - todayStudyMinutes).clamp(
          0,
          todayTargetMinutes,
        ),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      AppLogger.instance.e('ユーザー統計の計算に失敗しました: $userId', e);
      return StudyStatistics.empty();
    }
  }

  /// 今日の学習時間を取得（分）
  Future<int> _getTodayStudyMinutes(
    String userId,
    DateTime today,
    List<dynamic> userGoals,
  ) async {
    try {
      final dailyLogs = await _dailyStudyLogsRepository.getLogsByDateRange(
        _startOfDay(today),
        _endOfDay(today),
      );

      // 渡されたgoalsデータを使用
      final userGoalIds = userGoals.map((goal) => goal.id).toSet();

      final todayMinutes = dailyLogs
          .where((log) => userGoalIds.contains(log.goalId))
          .fold<int>(0, (sum, log) => sum + log.minutes);

      AppLogger.instance.d('今日の学習時間: $todayMinutes分');
      return todayMinutes;
    } catch (e) {
      AppLogger.instance.e('今日の学習時間取得エラー', e);
      return 0;
    }
  }

  /// 今日の目標時間を取得（分）
  Future<int> _getTodayTargetMinutes(
    String userId,
    List<dynamic> userGoals,
  ) async {
    try {
      final activeGoals = userGoals.where((goal) => !goal.isCompleted).toList();

      // 1日あたりの目標時間を計算（目標時間 ÷ 残り日数）
      final todayTargetMinutes = activeGoals.fold<int>(0, (sum, goal) {
        final remainingDays = goal.deadline.difference(DateTime.now()).inDays;
        if (remainingDays <= 0) return sum;

        final dailyTargetMinutes =
            goal.targetMinutes.toDouble() / remainingDays;
        final dailyMinutes = dailyTargetMinutes.toInt();
        return (sum + dailyMinutes) as int;
      });

      AppLogger.instance.d('今日の目標時間: $todayTargetMinutes分');
      return todayTargetMinutes;
    } catch (e) {
      AppLogger.instance.e('今日の目標時間取得エラー', e);
      return 0;
    }
  }

  /// 現在のストリーク（連続学習日数）を取得
  Future<int> _getCurrentStreak(
    String userId,
    DateTime today,
    List<dynamic> userGoals,
  ) async {
    try {
      // 過去30日分のデータを取得
      final startDate = today.subtract(const Duration(days: 30));
      final dailyLogs = await _dailyStudyLogsRepository.getLogsByDateRange(
        startDate,
        today,
      );

      // 渡されたgoalsデータを使用
      final userGoalIds = userGoals.map((goal) => goal.id).toSet();

      final userLogs =
          dailyLogs.where((log) => userGoalIds.contains(log.goalId)).toList();

      // 日付ごとに学習時間をグループ化
      final dailyMinutes = <String, int>{};
      for (final log in userLogs) {
        final dateKey = _formatDate(log.date);
        dailyMinutes[dateKey] = (dailyMinutes[dateKey] ?? 0) + log.minutes;
      }

      // 連続学習日数を計算
      int streak = 0;
      DateTime checkDate = today;

      while (checkDate.isAfter(startDate)) {
        final dateKey = _formatDate(checkDate);
        final minutesForDay = dailyMinutes[dateKey] ?? 0;

        if (minutesForDay > 0) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      AppLogger.instance.d('現在のストリーク: $streak日');
      return streak;
    } catch (e) {
      AppLogger.instance.e('ストリーク計算エラー', e);
      return 0;
    }
  }

  /// 目標数（総数・完了数）を取得
  Future<Map<String, int>> _getGoalCounts(
    String userId,
    List<dynamic> userGoals,
  ) async {
    try {
      final totalGoals = userGoals.length;
      final completedGoals = userGoals.where((goal) => goal.isCompleted).length;

      AppLogger.instance.d('目標数 - 総数: $totalGoals, 完了: $completedGoals');
      return {'total': totalGoals, 'completed': completedGoals};
    } catch (e) {
      AppLogger.instance.e('目標数取得エラー', e);
      return {'total': 0, 'completed': 0};
    }
  }

  /// 指定した目標のストリーク日数を取得
  Future<int> getGoalStreak(String goalId) async {
    try {
      final today = DateTime.now();
      final startDate = today.subtract(const Duration(days: 30));

      final dailyLogs = await _dailyStudyLogsRepository.getLogsByDateRange(
        startDate,
        today,
      );

      final goalLogs = dailyLogs.where((log) => log.goalId == goalId).toList();

      // 日付ごとに学習時間をグループ化
      final dailyMinutes = <String, int>{};
      for (final log in goalLogs) {
        final dateKey = _formatDate(log.date);
        dailyMinutes[dateKey] = (dailyMinutes[dateKey] ?? 0) + log.minutes;
      }

      // 連続学習日数を計算
      int streak = 0;
      DateTime checkDate = today;

      while (checkDate.isAfter(startDate)) {
        final dateKey = _formatDate(checkDate);
        final minutesForDay = dailyMinutes[dateKey] ?? 0;

        if (minutesForDay > 0) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      AppLogger.instance.e('目標ストリーク計算エラー: $goalId', e);
      return 0;
    }
  }

  // ユーティリティメソッド
  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
