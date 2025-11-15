import '../entities/entities.dart';
import '../repositories/billing_repository.dart';

/// 購入復元UseCase
class RestorePurchasesUseCase {
  final BillingRepository _repository;

  RestorePurchasesUseCase(this._repository);

  /// 購入を復元
  Future<RestoreResult> call() async {
    try {
      return await _repository.restorePurchases();
    } catch (e) {
      return RestoreResult.failure(e.toString());
    }
  }
}
