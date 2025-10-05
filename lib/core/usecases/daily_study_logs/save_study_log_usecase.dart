import 'package:goal_timer/core/data/repositories/daily_study_logs/daily_study_logs_repository.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';

/// 学習ログを保存するUseCase
///
/// ビジネスルール:
/// - 学習時間は0より大きい必要がある
/// - Repositoryに保存を委譲（Local/Remote切り替えはRepository内で処理）
class SaveStudyLogUseCase {
  final DailyStudyLogsRepository _repository;

  SaveStudyLogUseCase({required DailyStudyLogsRepository repository})
      : _repository = repository;

  /// 学習ログを保存する
  ///
  /// [goalId]: 目標ID
  /// [studyDurationInSeconds]: 学習時間（秒）
  /// throws: ArgumentError 学習時間が0以下の場合
  Future<DailyStudyLogModel> execute({
    required String goalId,
    required int studyDurationInSeconds,
  }) async {
    // バリデーション
    if (studyDurationInSeconds <= 0) {
      throw ArgumentError('学習時間は0より大きい必要があります');
    }

    final dailyStudyLogModel = DailyStudyLogModel.create(
      goalId: goalId,
      totalSeconds: studyDurationInSeconds,
    );

    // Repositoryに委譲（Local/Remote切り替えはRepository内で処理）
    return await _repository.upsertDailyLog(dailyStudyLogModel);
  }
}
