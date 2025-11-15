import 'package:goal_timer/backup/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/backup/core/models/goals/goals_model.dart';
import 'package:goal_timer/backup/core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

/// 目標作成のユースケース
/// クリーンアーキテクチャに従い、ViewModelとRepositoryの間の橋渡しを行う
class CreateGoalUseCase {
  final GoalsRepository _repository;

  // 目標時間の制約
  static const int minTargetMinutes = 1;
  static const int maxTargetMinutes = 1439; // 23時間59分

  // バリデーションの制約
  static const int minTitleLength = 2;
  static const int minAvoidMessageLength = 5;
  static const int defaultDeadlineDays = 30;

  CreateGoalUseCase(this._repository);

  /// 目標を作成する
  Future<GoalsModel> call({
    required String userId,
    required String title,
    required String description,
    required String avoidMessage,
    required int targetMinutes,
    DateTime? deadline,
  }) async {
    try {
      AppLogger.instance.i('目標の作成を開始します: $title');

      // バリデーション
      if (title.trim().isEmpty) {
        throw ArgumentError('タイトルは必須です');
      }
      if (title.trim().length < minTitleLength) {
        throw ArgumentError('タイトルは$minTitleLength文字以上である必要があります');
      }
      if (avoidMessage.trim().isEmpty) {
        throw ArgumentError('ネガティブ回避メッセージは必須です');
      }
      if (avoidMessage.trim().length < minAvoidMessageLength) {
        throw ArgumentError(
          'ネガティブ回避メッセージは$minAvoidMessageLength文字以上である必要があります',
        );
      }
      if (targetMinutes < minTargetMinutes ||
          targetMinutes > maxTargetMinutes) {
        throw ArgumentError(
          '目標時間は$minTargetMinutes分から$maxTargetMinutes分（23時間59分）の範囲で設定してください',
        );
      }

      // 目標モデルを作成
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: userId,
        title: title.trim(),
        description: description.trim(),
        deadline:
            deadline ??
            DateTime.now().add(const Duration(days: defaultDeadlineDays)),
        isCompleted: false,
        avoidMessage: avoidMessage.trim(),
        targetMinutes: targetMinutes,
        spentMinutes: 0,
        updatedAt: DateTime.now(),
      );

      // リポジトリ経由でデータベースに保存
      final createdGoal = await _repository.createGoal(goal);

      AppLogger.instance.i('目標の作成が完了しました: ${createdGoal.title}');
      return createdGoal;
    } catch (e) {
      AppLogger.instance.e('目標の作成に失敗しました', e);
      rethrow;
    }
  }
}
