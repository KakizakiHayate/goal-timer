import 'package:goal_timer/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

/// 目標作成のユースケース
/// クリーンアーキテクチャに従い、ViewModelとRepositoryの間の橋渡しを行う
class CreateGoalUseCase {
  final GoalsRepository _repository;

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
      if (title.trim().length < 2) {
        throw ArgumentError('タイトルは2文字以上である必要があります');
      }
      if (avoidMessage.trim().isEmpty) {
        throw ArgumentError('ネガティブ回避メッセージは必須です');
      }
      if (avoidMessage.trim().length < 5) {
        throw ArgumentError('ネガティブ回避メッセージは5文字以上である必要があります');
      }
      if (targetMinutes < 15 || targetMinutes > 180) {
        throw ArgumentError('目標時間は15分から180分の範囲で設定してください');
      }

      // 目標モデルを作成
      final goal = GoalsModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: title.trim(),
        description: description.trim(),
        deadline: deadline ?? DateTime.now().add(const Duration(days: 30)),
        isCompleted: false,
        avoidMessage: avoidMessage.trim(),
        totalTargetHours: (targetMinutes / 60).round(),
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