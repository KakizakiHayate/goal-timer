import 'dart:async';
import '../../domain/entities/entities.dart';

/// デバッグ用のRevenueCatデータソース（StoreKit設定待ち）
class RevenueCatDataSourceDebug {
  static RevenueCatDataSourceDebug? _instance;

  RevenueCatDataSourceDebug._();

  static RevenueCatDataSourceDebug get instance {
    _instance ??= RevenueCatDataSourceDebug._();
    return _instance!;
  }

  /// デバッグ用の顧客情報を返す
  Future<CustomerInfo> getCustomerInfo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return CustomerInfo(
      userId: 'debug_user_001',
      entitlements: [],
      activeSubscriptions: [],
      allPurchasedProductIds: [],
      latestExpirationDate: null,
      firstSeen: DateTime.now().subtract(const Duration(days: 7)),
      originalAppUserId: 'debug_user_001',
      managementUrl: null,
    );
  }

  /// デバッグ用の商品リストを返す
  Future<List<ProductInfo>> getAvailableProducts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      ProductInfo(
        productId: 'goal_timer_monthly_500',
        title: '月額プラン',
        description: '全機能がアンロックされます',
        price: '¥500',
        priceAmount: 500.0,
        currencyCode: 'JPY',
        subscriptionPeriod: const Duration(days: 30),
        introductoryPrice: null,
      ),
      ProductInfo(
        productId: 'goal_timer_yearly_6000',
        title: '年額プラン',
        description: '17%お得！全機能がアンロックされます',
        price: '¥6,000',
        priceAmount: 6000.0,
        currencyCode: 'JPY',
        subscriptionPeriod: const Duration(days: 365),
        introductoryPrice: null,
      ),
    ];
  }

  /// デバッグ用の購入処理
  Future<PurchaseResult> purchaseProduct(String productId) async {
    await Future.delayed(const Duration(seconds: 1));

    // デバッグモードでは常に成功を返す
    return PurchaseResult(
      success: true,
      customerInfo: await getCustomerInfo(),
      error: null,
    );
  }

  /// 購入の復元（デバッグ用）
  Future<CustomerInfo> restorePurchases() async {
    return await getCustomerInfo();
  }

  /// サブスクリプション状態を取得（デバッグ用）
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SubscriptionStatus(
      isActive: false,
      expirationDate: null,
      willRenew: false,
      isTrial: false,
      planId: null,
      state: SubscriptionState.none,
    );
  }

  /// サブスクリプション状態をストリームで監視（デバッグ用）
  Stream<SubscriptionStatus> subscriptionStatusStream() {
    final controller = StreamController<SubscriptionStatus>.broadcast();

    // 初期状態を送信
    controller.add(
      SubscriptionStatus(
        isActive: false,
        expirationDate: null,
        willRenew: false,
        isTrial: false,
        planId: null,
        state: SubscriptionState.none,
      ),
    );

    return controller.stream;
  }

  /// プレミアム機能が利用可能かチェック（デバッグ用）
  Future<bool> isPremiumAvailable() async {
    final status = await getSubscriptionStatus();
    return status.isActive || status.isTrial;
  }

  /// 無料トライアルが利用可能かチェック（デバッグ用）
  Future<bool> isTrialAvailable() async {
    // デバッグモードでは常にトライアル可能
    return true;
  }

  /// サブスクリプションをキャンセル（デバッグ用）
  Future<void> cancelSubscription() async {
    await Future.delayed(const Duration(seconds: 1));
    // デバッグモードでは何もしない
  }

  /// サブスクリプション管理画面を開く（デバッグ用）
  Future<void> openSubscriptionManagement() async {
    // デバッグモードでは何もしない
    print('Debug: Opening subscription management (no-op in debug mode)');
  }
}
