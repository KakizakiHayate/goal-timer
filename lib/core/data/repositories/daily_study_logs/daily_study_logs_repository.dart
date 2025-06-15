import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';

/// 学習記録データのリポジトリインターフェース
abstract class DailyStudyLogsRepository {
  /// 全学習記録を取得
  Future<List<DailyStudyLogModel>> getAllLogs();

  /// 特定の日付の学習記録を取得
  Future<List<DailyStudyLogModel>> getDailyLogs(DateTime date);

  /// 特定の期間の学習記録を取得
  Future<List<DailyStudyLogModel>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// 特定の目標IDの学習記録を取得
  Future<List<DailyStudyLogModel>> getLogsByGoalId(String goalId);

  /// 特定のIDの学習記録を取得
  Future<DailyStudyLogModel?> getLogById(String id);

  /// 学習記録を追加または更新
  Future<DailyStudyLogModel> upsertDailyLog(DailyStudyLogModel log);

  /// 学習記録を削除
  Future<bool> deleteDailyLog(String id);

  /// リモートと同期を実行
  Future<void> syncWithRemote();
}
