import 'dart:async';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:goal_timer/backup/core/utils/app_logger.dart';
import '../../domain/entities/entities.dart';

/// RevenueCat SDKとの通信を担当するデータソース（本番版）
class RevenueCatDataSourceProduction {
  static RevenueCatDataSourceProduction? _instance;

  RevenueCatDataSourceProduction._();

  static RevenueCatDataSourceProduction get instance {
    _instance ??= RevenueCatDataSourceProduction._();
    return _instance!;
  }

  /// 顧客情報を取得
  Future<CustomerInfo> getCustomerInfo() async {
    try {
      final customerInfo = await rc.Purchases.getCustomerInfo();
      return _mapCustomerInfo(customerInfo);
    } catch (e) {
      AppLogger.instance.e('Failed to get customer info: $e');
      throw Exception('顧客情報の取得に失敗しました');
    }
  }

  /// 利用可能な商品一覧を取得
  Future<List<ProductInfo>> getAvailableProducts() async {
    try {
      final offerings = await rc.Purchases.getOfferings();
      final products = <ProductInfo>[];

      if (offerings.current != null) {
        for (final package in offerings.current!.availablePackages) {
          products.add(_mapProductInfo(package));
        }
      }

      return products;
    } catch (e) {
      AppLogger.instance.e('Failed to get available products: $e');
      return [];
    }
  }

  /// 商品を購入
  Future<PurchaseResult> purchaseProduct(String productId) async {
    try {
      final offerings = await rc.Purchases.getOfferings();
      rc.Package? packageToPurchase;

      // パッケージを探す
      if (offerings.current != null) {
        for (final package in offerings.current!.availablePackages) {
          if (package.identifier == productId ||
              package.storeProduct.identifier == productId) {
            packageToPurchase = package;
            break;
          }
        }
      }

      if (packageToPurchase == null) {
        return PurchaseResult.error(
          errorType: PurchaseErrorType.productNotFound,
          errorMessage: '商品が見つかりません',
          productId: productId,
        );
      }

      final purchaserInfo = await rc.Purchases.purchasePackage(
        packageToPurchase,
      );

      return PurchaseResult.success(
        transactionId: purchaserInfo.originalAppUserId,
        productId: productId,
        purchaseDate: DateTime.now(),
      );
    } on PlatformException catch (e) {
      AppLogger.instance.e('Purchase failed: ${e.code} - ${e.message}');

      // エラーコードに応じた処理
      switch (e.code) {
        case '1': // PurchaseCancelledError
        case 'UserCancelled':
          return PurchaseResult.cancelled();
        case '2': // StoreProblemError
        case '3': // PurchaseNotAllowedError
          return PurchaseResult.error(
            errorType: PurchaseErrorType.paymentDeclined,
            errorMessage: e.message ?? '購入が拒否されました',
            productId: productId,
          );
        case '4': // PurchaseInvalidError
        case '5': // ProductNotAvailableForPurchaseError
          return PurchaseResult.error(
            errorType: PurchaseErrorType.productNotFound,
            errorMessage: e.message ?? '商品が利用できません',
            productId: productId,
          );
        case '6': // ProductAlreadyPurchasedError
          return PurchaseResult.error(
            errorType: PurchaseErrorType.alreadyOwned,
            errorMessage: 'すでに購入済みです',
            productId: productId,
          );
        case '7': // ReceiptAlreadyInUseError
        case '8': // InvalidReceiptError
        case '9': // MissingReceiptFileError
          return PurchaseResult.error(
            errorType: PurchaseErrorType.server,
            errorMessage: e.message ?? 'レシート検証エラー',
            productId: productId,
          );
        case '10': // NetworkError
          return PurchaseResult.error(
            errorType: PurchaseErrorType.network,
            errorMessage: 'ネットワークエラー',
            productId: productId,
          );
        default:
          return PurchaseResult.error(
            errorType: PurchaseErrorType.unknown,
            errorMessage: e.message ?? '不明なエラー',
            productId: productId,
          );
      }
    } catch (e) {
      AppLogger.instance.e('Unexpected purchase error: $e');
      return PurchaseResult.error(
        errorType: PurchaseErrorType.system,
        errorMessage: e.toString(),
        productId: productId,
      );
    }
  }

  /// 購入を復元
  Future<RestoreResult> restorePurchases() async {
    try {
      final customerInfo = await rc.Purchases.restorePurchases();
      final activeEntitlements = customerInfo.entitlements.active.keys.toList();

      if (activeEntitlements.isEmpty) {
        return RestoreResult.success(restoredCount: 0, restoredProductIds: []);
      }

      return RestoreResult.success(
        restoredCount: activeEntitlements.length,
        restoredProductIds: activeEntitlements,
      );
    } catch (e) {
      AppLogger.instance.e('Restore purchases failed: $e');
      return RestoreResult.failure('購入の復元に失敗しました: $e');
    }
  }

  /// サブスクリプション状態を取得
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final customerInfo = await rc.Purchases.getCustomerInfo();
      return _mapSubscriptionStatus(customerInfo);
    } catch (e) {
      AppLogger.instance.e('Failed to get subscription status: $e');
      return SubscriptionStatus.free;
    }
  }

  /// サブスクリプション状態の変更を監視
  Stream<SubscriptionStatus> subscriptionStatusStream() {
    // RevenueCat SDK v8ではlistenerを使用
    final controller = StreamController<SubscriptionStatus>.broadcast();

    // 定期的に状態を確認する簡易実装
    Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final status = await getSubscriptionStatus();
        controller.add(status);
      } catch (e) {
        AppLogger.instance.e('Failed to update subscription status: $e');
        controller.add(SubscriptionStatus.free);
      }
    });

    // 初回の状態を取得
    getSubscriptionStatus()
        .then((status) {
          controller.add(status);
        })
        .catchError((error) {
          AppLogger.instance.e('Initial subscription status error: $error');
          controller.add(SubscriptionStatus.free);
        });

    return controller.stream;
  }

  /// 特定のエンタイトルメントが有効かどうかを確認
  Future<bool> hasEntitlement(String entitlementId) async {
    try {
      final customerInfo = await rc.Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      AppLogger.instance.e('Failed to check entitlement: $e');
      return false;
    }
  }

  /// プレミアム機能が利用可能かどうかを確認
  Future<bool> isPremiumAvailable() async {
    try {
      final customerInfo = await rc.Purchases.getCustomerInfo();
      // "premium"というエンタイトルメントを確認
      return customerInfo.entitlements.active.containsKey('premium') ||
          customerInfo.entitlements.active.isNotEmpty;
    } catch (e) {
      AppLogger.instance.e('Failed to check premium status: $e');
      return false;
    }
  }

  // マッピング関数

  CustomerInfo _mapCustomerInfo(rc.CustomerInfo wrapper) {
    final entitlements = <String, EntitlementInfo>{};

    for (final entry in wrapper.entitlements.active.entries) {
      entitlements[entry.key] = EntitlementInfo(
        identifier: entry.key,
        isActive: true,
        expirationDate:
            entry.value.expirationDate != null
                ? DateTime.tryParse(entry.value.expirationDate!)
                : null,
        latestPurchaseDate:
            entry.value.latestPurchaseDate != null
                ? DateTime.tryParse(entry.value.latestPurchaseDate!)
                : null,
        originalPurchaseDate:
            entry.value.originalPurchaseDate != null
                ? DateTime.tryParse(entry.value.originalPurchaseDate!)
                : null,
        productIdentifier: entry.value.productIdentifier,
        willRenew: entry.value.willRenew,
      );
    }

    return CustomerInfo(
      originalAppUserId: wrapper.originalAppUserId,
      entitlements: entitlements,
      originalPurchaseDate:
          wrapper.originalPurchaseDate != null
              ? DateTime.tryParse(wrapper.originalPurchaseDate!)
              : null,
      latestExpirationDate:
          wrapper.latestExpirationDate != null
              ? DateTime.tryParse(wrapper.latestExpirationDate!)
              : null,
    );
  }

  ProductInfo _mapProductInfo(rc.Package package) {
    final product = package.storeProduct;
    return ProductInfo(
      identifier: product.identifier,
      title: product.title,
      description: product.description,
      price: product.priceString,
      currencyCode: product.currencyCode ?? 'JPY',
      priceAmount: product.price,
      introductoryPrice: product.introductoryPrice?.priceString,
      introductoryPeriod: product.introductoryPrice?.period.toString(),
      subscriptionPeriod: product.subscriptionPeriod ?? '',
      isAvailable: true,
    );
  }

  SubscriptionStatus _mapSubscriptionStatus(rc.CustomerInfo customerInfo) {
    final hasActiveEntitlement = customerInfo.entitlements.active.isNotEmpty;
    final activeEntitlementKeys =
        customerInfo.entitlements.active.keys.toList();

    if (!hasActiveEntitlement) {
      return SubscriptionStatus.free;
    }

    // アクティブなエンタイトルメントから情報を取得
    final firstEntitlement = customerInfo.entitlements.active.values.first;
    final expirationDate =
        firstEntitlement.expirationDate != null
            ? DateTime.tryParse(firstEntitlement.expirationDate!)
            : null;

    // トライアル期間かどうかを判定
    final isInTrialPeriod = firstEntitlement.periodType == rc.PeriodType.trial;

    // サブスクリプション状態を判定
    SubscriptionState state;
    if (isInTrialPeriod) {
      state = SubscriptionState.trial;
    } else if (hasActiveEntitlement) {
      state = SubscriptionState.active;
    } else {
      state = SubscriptionState.none;
    }

    return SubscriptionStatus(
      state: state,
      isPremium: hasActiveEntitlement,
      planId: firstEntitlement.productIdentifier,
      expirationDate: expirationDate,
      renewalDate: expirationDate,
      isAutoRenew: firstEntitlement.willRenew,
      isInTrialPeriod: isInTrialPeriod,
      trialEndDate: isInTrialPeriod ? expirationDate : null,
      entitlements: activeEntitlementKeys,
    );
  }
}
