import '../repositories/billing_repository.dart';
import '../entities/entities.dart';

/// プレミアム制限サービス
class PremiumRestrictionService {
  final BillingRepository _repository;
  
  // 無料版の制限値
  static const int freeGoalLimit = 3;
  
  PremiumRestrictionService(this._repository);

  /// プレミアムユーザーかどうか確認
  Future<bool> isPremiumUser() async {
    return await _repository.isPremiumAvailable();
  }

  /// 目標作成が可能かどうか確認
  Future<bool> canCreateGoal(int currentGoalCount) async {
    final isPremium = await isPremiumUser();
    if (isPremium) {
      return true; // プレミアムユーザーは無制限
    }
    return currentGoalCount < freeGoalLimit;
  }

  /// ポモドーロタイマーが使用可能かどうか確認
  Future<bool> canUsePomodoro() async {
    return await isPremiumUser();
  }

  /// CSVエクスポートが使用可能かどうか確認
  Future<bool> canExportCsv() async {
    return await isPremiumUser();
  }

  /// 残りの作成可能な目標数を取得
  Future<int> getRemainingGoals(int currentGoalCount) async {
    final isPremium = await isPremiumUser();
    if (isPremium) {
      return -1; // 無制限を示す
    }
    return (freeGoalLimit - currentGoalCount).clamp(0, freeGoalLimit);
  }

  /// 制限に達しているかチェック
  Future<bool> isGoalLimitReached(int currentGoalCount) async {
    final isPremium = await isPremiumUser();
    if (isPremium) {
      return false;
    }
    return currentGoalCount >= freeGoalLimit;
  }

  /// 制限メッセージを取得
  Future<String> getGoalLimitMessage(int currentGoalCount) async {
    final isPremium = await isPremiumUser();
    if (isPremium) {
      return '無制限に目標を作成できます';
    }
    
    final remaining = await getRemainingGoals(currentGoalCount);
    if (remaining > 0) {
      return 'あと$remaining個の目標を作成できます';
    } else {
      return '無料版では目標は$freeGoalLimit個までです。プレミアムプランで無制限に作成できます。';
    }
  }

  /// プレミアム機能使用時のメッセージ
  String getPremiumFeatureMessage(String featureName) {
    return '$featureName はプレミアム限定機能です。プレミアムプランにアップグレードしてご利用ください。';
  }
}