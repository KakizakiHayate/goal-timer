import '../entities/entities.dart';

/// 課金機能のリポジトリインターフェース
abstract class BillingRepository {
  /// 現在のサブスクリプション状態を取得
  Future<SubscriptionStatus> getSubscriptionStatus();

  /// 利用可能な商品一覧を取得
  Future<List<ProductInfo>> getAvailableProducts();

  /// 商品を購入
  Future<PurchaseResult> purchaseProduct(String productId);

  /// 購入を復元
  Future<RestoreResult> restorePurchases();

  /// 顧客情報を取得
  Future<CustomerInfo> getCustomerInfo();

  /// サブスクリプション状態を監視するストリーム
  Stream<SubscriptionStatus> subscriptionStatusStream();

  /// 特定のエンタイトルメントが有効かどうかを確認
  Future<bool> hasEntitlement(String entitlementId);

  /// プレミアム機能が利用可能かどうかを確認
  Future<bool> isPremiumAvailable();
}