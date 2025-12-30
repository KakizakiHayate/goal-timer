import 'package:goal_timer/backup/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/backup/core/models/goals/goals_model.dart';
import 'package:goal_timer/backup/core/utils/app_logger.dart';

/// 目標更新のユースケース
/// クリーンアーキテクチャに従い、ViewModelとRepositoryの間の橋渡しを行う
class UpdateGoalUseCase {
  final GoalsRepository _repository;

  // 目標時間の制約
  static const int minTargetMinutes = 1;
  static const int maxTargetMinutes = 1439; // 23時間59分

  // バリデーションの制約
  static const int minTitleLength = 2;
  static const int minAvoidMessageLength = 5;

  UpdateGoalUseCase(this._repository);

  /// 目標を更新する
  Future<GoalsModel> call({
    required GoalsModel originalGoal,
    String? title,
    String? description,
    String? avoidMessage,
    int? targetMinutes,
    bool? isCompleted,
    DateTime? deadline,
  }) async {
    try {
      AppLogger.instance.i(
        '🔧 [UpdateGoalUseCase] 目標の更新を開始します: ${originalGoal.title}',
      );
      AppLogger.instance.i(
        '🔧 [UpdateGoalUseCase] 更新前の目標ID: ${originalGoal.id}',
      );
      AppLogger.instance.i('🔧 [UpdateGoalUseCase] 入力パラメータ:');
      AppLogger.instance.i('   📝 title: $title');
      AppLogger.instance.i('   📝 description: $description');
      AppLogger.instance.i('   📝 avoidMessage: $avoidMessage');
      AppLogger.instance.i('   📝 targetMinutes: $targetMinutes');
      AppLogger.instance.i('   📝 isCompleted: $isCompleted');
      AppLogger.instance.i('   📝 deadline: $deadline');

      // 更新する値があれば適用、なければ既存値を使用
      final updatedTitle = title?.trim() ?? originalGoal.title;
      final updatedDescription =
          description?.trim() ?? originalGoal.description;
      final updatedAvoidMessage =
          avoidMessage?.trim() ?? originalGoal.avoidMessage;
      final updatedTargetMinutes = targetMinutes ?? originalGoal.targetMinutes;
      final updatedIsCompleted = isCompleted ?? originalGoal.isCompleted;
      final updatedDeadline = deadline ?? originalGoal.deadline;

      AppLogger.instance.i('🔧 [UpdateGoalUseCase] 適用後の値:');
      AppLogger.instance.i('   ✏️ updatedTitle: $updatedTitle');
      AppLogger.instance.i('   ✏️ updatedDescription: $updatedDescription');
      AppLogger.instance.i('   ✏️ updatedAvoidMessage: $updatedAvoidMessage');
      AppLogger.instance.i('   ✏️ updatedTargetMinutes: $updatedTargetMinutes');
      AppLogger.instance.i('   ✏️ updatedIsCompleted: $updatedIsCompleted');

      AppLogger.instance.i('🔧 [UpdateGoalUseCase] バリデーションを開始します...');

      // バリデーション
      if (updatedTitle.isEmpty) {
        AppLogger.instance.e('❌ [UpdateGoalUseCase] バリデーションエラー: タイトルは必須です');
        throw ArgumentError('タイトルは必須です');
      }
      if (updatedTitle.length < minTitleLength) {
        AppLogger.instance.e(
          '❌ [UpdateGoalUseCase] バリデーションエラー: タイトルは$minTitleLength文字以上である必要があります',
        );
        throw ArgumentError('タイトルは$minTitleLength文字以上である必要があります');
      }
      if (updatedAvoidMessage.isEmpty) {
        AppLogger.instance.e(
          '❌ [UpdateGoalUseCase] バリデーションエラー: ネガティブ回避メッセージは必須です',
        );
        throw ArgumentError('ネガティブ回避メッセージは必須です');
      }
      if (updatedAvoidMessage.length < minAvoidMessageLength) {
        AppLogger.instance.e(
          '❌ [UpdateGoalUseCase] バリデーションエラー: ネガティブ回避メッセージは$minAvoidMessageLength文字以上である必要があります',
        );
        throw ArgumentError(
          'ネガティブ回避メッセージは$minAvoidMessageLength文字以上である必要があります',
        );
      }
      if (updatedTargetMinutes < minTargetMinutes ||
          updatedTargetMinutes > maxTargetMinutes) {
        AppLogger.instance.e(
          '❌ [UpdateGoalUseCase] バリデーションエラー: 目標時間は$minTargetMinutes分から$maxTargetMinutes分（23時間59分）の範囲で設定してください',
        );
        throw ArgumentError(
          '目標時間は$minTargetMinutes分から$maxTargetMinutes分（23時間59分）の範囲で設定してください',
        );
      }

      AppLogger.instance.i('✅ [UpdateGoalUseCase] バリデーション完了');

      // 更新された目標モデルを作成
      AppLogger.instance.i('🔧 [UpdateGoalUseCase] 更新された目標モデルを作成します...');
      final updatedGoal = originalGoal.copyWith(
        title: updatedTitle,
        description: updatedDescription,
        avoidMessage: updatedAvoidMessage,
        targetMinutes: updatedTargetMinutes,
        isCompleted: updatedIsCompleted,
        deadline: updatedDeadline,
        updatedAt: DateTime.now(),
      );

      AppLogger.instance.i('✅ [UpdateGoalUseCase] 更新された目標モデルを作成しました');
      AppLogger.instance.i('🔧 [UpdateGoalUseCase] モデルID: ${updatedGoal.id}');
      AppLogger.instance.i(
        '🔧 [UpdateGoalUseCase] モデルタイトル: ${updatedGoal.title}',
      );
      AppLogger.instance.i(
        '🔧 [UpdateGoalUseCase] 目標時間: ${updatedGoal.targetMinutes}分',
      );

      // リポジトリ経由でデータベースを更新
      AppLogger.instance.i(
        '🚀 [UpdateGoalUseCase] リポジトリのupdateGoal()を呼び出します...',
      );
      final resultGoal = await _repository.updateGoal(updatedGoal);

      AppLogger.instance.i('✅ [UpdateGoalUseCase] リポジトリのupdateGoal()が完了しました');
      AppLogger.instance.i(
        '📊 [UpdateGoalUseCase] 結果: ${resultGoal.title} (ID: ${resultGoal.id})',
      );
      AppLogger.instance.i(
        '📊 [UpdateGoalUseCase] 目標時間: ${resultGoal.targetMinutes}分',
      );
      AppLogger.instance.i('🏁 [UpdateGoalUseCase] 目標の更新が完了しました');

      return resultGoal;
    } catch (e) {
      AppLogger.instance.e('❌ [UpdateGoalUseCase] 目標の更新に失敗しました', e);
      AppLogger.instance.e('❌ [UpdateGoalUseCase] エラー詳細: ${e.toString()}');
      AppLogger.instance.e('❌ [UpdateGoalUseCase] エラータイプ: ${e.runtimeType}');
      rethrow;
    }
  }
}
