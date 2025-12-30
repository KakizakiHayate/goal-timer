import '../entities/entities.dart';
import '../repositories/billing_repository.dart';

/// サブスクリプション状態取得UseCase
class GetSubscriptionStatusUseCase {
  final BillingRepository _repository;

  GetSubscriptionStatusUseCase(this._repository);

  /// サブスクリプション状態を取得
  Future<SubscriptionStatus> call() async {
    try {
      return await _repository.getSubscriptionStatus();
    } catch (e) {
      // エラーの場合は無料状態を返す
      return SubscriptionStatus.free;
    }
  }

  /// サブスクリプション状態の監視ストリーム
  Stream<SubscriptionStatus> stream() {
    return _repository.subscriptionStatusStream();
  }
}
