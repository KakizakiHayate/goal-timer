import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_info.freezed.dart';
part 'product_info.g.dart';

/// 商品情報（RevenueCatから取得）
@freezed
class ProductInfo with _$ProductInfo {
  const factory ProductInfo({
    required String identifier,
    required String title,
    required String description,
    required String price,
    required String currencyCode,
    required double priceAmount,
    required String? introductoryPrice,
    required String? introductoryPeriod,
    required String subscriptionPeriod,
    required bool isAvailable,
  }) = _ProductInfo;

  factory ProductInfo.fromJson(Map<String, dynamic> json) =>
      _$ProductInfoFromJson(json);
}

/// エンタイトルメント情報
@freezed
class EntitlementInfo with _$EntitlementInfo {
  const factory EntitlementInfo({
    required String identifier,
    required bool isActive,
    required DateTime? expirationDate,
    required DateTime? latestPurchaseDate,
    required DateTime? originalPurchaseDate,
    required String? productIdentifier,
    required bool willRenew,
  }) = _EntitlementInfo;

  factory EntitlementInfo.fromJson(Map<String, dynamic> json) =>
      _$EntitlementInfoFromJson(json);
}

/// 顧客情報
@freezed
class CustomerInfo with _$CustomerInfo {
  const CustomerInfo._();

  const factory CustomerInfo({
    required String originalAppUserId,
    required Map<String, EntitlementInfo> entitlements,
    required DateTime? originalPurchaseDate,
    required DateTime? latestExpirationDate,
    @Default({}) Map<String, DateTime?> allPurchaseDates,
    @Default({}) Map<String, DateTime?> allExpirationDates,
  }) = _CustomerInfo;

  factory CustomerInfo.fromJson(Map<String, dynamic> json) =>
      _$CustomerInfoFromJson(json);

  /// プレミアム状態かどうか
  bool get isPremium {
    return entitlements.values.any((entitlement) => entitlement.isActive);
  }

  /// アクティブなエンタイトルメントを取得
  List<EntitlementInfo> get activeEntitlements {
    return entitlements.values.where((e) => e.isActive).toList();
  }
}
