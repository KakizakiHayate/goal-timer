import 'package:uuid/uuid.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';
import 'package:goal_timer/core/data/repositories/daily_study_logs/daily_study_logs_repository.dart';
import 'package:goal_timer/core/data/repositories/goals/goals_repository.dart';
import '../entities/quick_record.dart';

/// Issue #44: 手動学習記録保存ユースケース
class SaveQuickRecordUseCase {
  final DailyStudyLogsRepository _dailyStudyLogsRepository;
  final GoalsRepository _goalsRepository;

  SaveQuickRecordUseCase({
    required DailyStudyLogsRepository dailyStudyLogsRepository,
    required GoalsRepository goalsRepository,
  })  : _dailyStudyLogsRepository = dailyStudyLogsRepository,
        _goalsRepository = goalsRepository;

  /// 手動記録を既存データと合算して保存
  Future<void> call(QuickRecord record) async {
    // バリデーションチェック
    if (!record.isValid) {
      throw ArgumentError(record.validationError ?? 'Invalid quick record');
    }

    // 1. 同日の既存記録を取得
    final existingLogs = await _dailyStudyLogsRepository.getDailyLogs(record.date);
    final existingLog = existingLogs.where((log) => log.goalId == record.goalId).firstOrNull;

    // 2. 新規入力と既存データを合算（分単位）
    int totalMinutes = record.totalMinutes;
    if (existingLog != null) {
      totalMinutes += existingLog.minutes;
    }

    // 3. オーバーフロー（24時間超過）チェック
    if (totalMinutes > 1439) { // 23時間59分 = 1439分
      throw ArgumentError('24時間を超過します');
    }

    // 4. 分単位でそのまま保存
    final updatedLog = DailyStudyLogModel(
      id: existingLog?.id ?? const Uuid().v4(),
      goalId: record.goalId,
      date: record.date,
      minutes: totalMinutes,
      updatedAt: DateTime.now(),
    );

    await _dailyStudyLogsRepository.upsertDailyLog(updatedLog);

    // 5. 目標の累計時間を更新
    await _updateGoalSpentMinutes(record.goalId);
  }

  /// 目標の累計時間を更新
  Future<void> _updateGoalSpentMinutes(String goalId) async {
    // 該当目標の全ての学習記録を取得して合計分数を計算
    final allLogs = await _dailyStudyLogsRepository.getLogsByGoalId(goalId);
    final totalSpentMinutes = allLogs.fold<int>(
      0,
      (sum, log) => sum + log.minutes,
    );

    // 目標の累計時間を更新
    final goal = await _goalsRepository.getGoalById(goalId);
    if (goal != null) {
      final updatedGoal = goal.copyWith(spentMinutes: totalSpentMinutes);
      await _goalsRepository.updateGoal(updatedGoal);
    }
  }
}