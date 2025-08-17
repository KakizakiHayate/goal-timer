import '../entities/entities.dart';
import '../repositories/billing_repository.dart';

/// 商品購入UseCase
class PurchaseProductUseCase {
  final BillingRepository _repository;

  PurchaseProductUseCase(this._repository);

  /// 商品を購入
  Future<PurchaseResult> call(String productId) async {
    try {
      return await _repository.purchaseProduct(productId);
    } catch (e) {
      return PurchaseResult.error(
        errorType: PurchaseErrorType.system,
        errorMessage: e.toString(),
        productId: productId,
      );
    }
  }
}