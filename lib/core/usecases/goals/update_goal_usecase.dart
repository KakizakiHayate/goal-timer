import 'package:goal_timer/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

/// 目標更新のユースケース
/// クリーンアーキテクチャに従い、ViewModelとRepositoryの間の橋渡しを行う
class UpdateGoalUseCase {
  final GoalsRepository _repository;

  UpdateGoalUseCase(this._repository);

  /// 目標を更新する
  Future<GoalsModel> call({
    required GoalsModel originalGoal,
    String? title,
    String? description,
    String? avoidMessage,
    int? totalTargetHours,
    bool? isCompleted,
    DateTime? deadline,
  }) async {
    try {
      AppLogger.instance.i('目標の更新を開始します: ${originalGoal.title}');

      // 更新する値があれば適用、なければ既存値を使用
      final updatedTitle = title?.trim() ?? originalGoal.title;
      final updatedDescription = description?.trim() ?? originalGoal.description;
      final updatedAvoidMessage = avoidMessage?.trim() ?? originalGoal.avoidMessage;
      final updatedTargetHours = totalTargetHours ?? originalGoal.totalTargetHours;
      final updatedIsCompleted = isCompleted ?? originalGoal.isCompleted;
      final updatedDeadline = deadline ?? originalGoal.deadline;

      // バリデーション
      if (updatedTitle.isEmpty) {
        throw ArgumentError('タイトルは必須です');
      }
      if (updatedTitle.length < 2) {
        throw ArgumentError('タイトルは2文字以上である必要があります');
      }
      if (updatedAvoidMessage.isEmpty) {
        throw ArgumentError('ネガティブ回避メッセージは必須です');
      }
      if (updatedAvoidMessage.length < 5) {
        throw ArgumentError('ネガティブ回避メッセージは5文字以上である必要があります');
      }
      if (updatedTargetHours < 1 || updatedTargetHours > 8) {
        throw ArgumentError('目標時間は1時間から8時間の範囲で設定してください');
      }

      // 更新された目標モデルを作成
      final updatedGoal = originalGoal.copyWith(
        title: updatedTitle,
        description: updatedDescription,
        avoidMessage: updatedAvoidMessage,
        totalTargetHours: updatedTargetHours,
        isCompleted: updatedIsCompleted,
        deadline: updatedDeadline,
        updatedAt: DateTime.now(),
      );

      // リポジトリ経由でデータベースを更新
      final resultGoal = await _repository.updateGoal(updatedGoal);
      
      AppLogger.instance.i('目標の更新が完了しました: ${resultGoal.title}');
      return resultGoal;
    } catch (e) {
      AppLogger.instance.e('目標の更新に失敗しました', e);
      rethrow;
    }
  }
}