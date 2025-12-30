import '../entities/entities.dart';
import '../repositories/billing_repository.dart';

/// 利用可能商品取得UseCase
class GetAvailableProductsUseCase {
  final BillingRepository _repository;

  GetAvailableProductsUseCase(this._repository);

  /// 利用可能な商品一覧を取得
  Future<List<ProductInfo>> call() async {
    try {
      return await _repository.getAvailableProducts();
    } catch (e) {
      // エラーの場合は空のリストを返す
      return [];
    }
  }
}
