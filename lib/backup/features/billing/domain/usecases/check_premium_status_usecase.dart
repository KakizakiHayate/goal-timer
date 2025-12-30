import '../entities/entities.dart';
import '../repositories/billing_repository.dart';

/// プレミアム状態確認UseCase
class CheckPremiumStatusUseCase {
  final BillingRepository _repository;

  CheckPremiumStatusUseCase(this._repository);

  /// プレミアム機能が利用可能かどうかを確認
  Future<bool> call() async {
    try {
      return await _repository.isPremiumAvailable();
    } catch (e) {
      // エラーの場合は無料とする
      return false;
    }
  }

  /// 特定のエンタイトルメントが有効かどうかを確認
  Future<bool> hasEntitlement(String entitlementId) async {
    try {
      return await _repository.hasEntitlement(entitlementId);
    } catch (e) {
      return false;
    }
  }
}
