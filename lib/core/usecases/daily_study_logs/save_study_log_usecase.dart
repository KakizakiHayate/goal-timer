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
  /// [log]: 保存する学習ログ
  /// 戻り値: 保存された学習ログ（IDが生成される場合あり）
  /// throws: ArgumentError 学習時間が0以下の場合
  Future<DailyStudyLogModel> execute(DailyStudyLogModel log) async {
    // バリデーション
    if (log.studyDuration <= 0) {
      throw ArgumentError('学習時間は0より大きい必要があります');
    }

    // Repositoryに委譲（Local/Remote切り替えはRepository内で処理）
    return await _repository.upsertDailyLog(log);
  }
}
