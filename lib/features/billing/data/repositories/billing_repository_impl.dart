import '../../domain/entities/entities.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/revenue_cat_datasource_production.dart';

/// BillingRepositoryの実装クラス
class BillingRepositoryImpl implements BillingRepository {
  final RevenueCatDataSourceProduction _dataSource;

  BillingRepositoryImpl({RevenueCatDataSourceProduction? dataSource})
    : _dataSource = dataSource ?? RevenueCatDataSourceProduction.instance;

  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    return await _dataSource.getSubscriptionStatus();
  }

  @override
  Future<List<ProductInfo>> getAvailableProducts() async {
    return await _dataSource.getAvailableProducts();
  }

  @override
  Future<PurchaseResult> purchaseProduct(String productId) async {
    return await _dataSource.purchaseProduct(productId);
  }

  @override
  Future<RestoreResult> restorePurchases() async {
    return await _dataSource.restorePurchases();
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    return await _dataSource.getCustomerInfo();
  }

  @override
  Stream<SubscriptionStatus> subscriptionStatusStream() {
    return _dataSource.subscriptionStatusStream();
  }

  @override
  Future<bool> hasEntitlement(String entitlementId) async {
    return await _dataSource.hasEntitlement(entitlementId);
  }

  @override
  Future<bool> isPremiumAvailable() async {
    return await _dataSource.isPremiumAvailable();
  }
}
