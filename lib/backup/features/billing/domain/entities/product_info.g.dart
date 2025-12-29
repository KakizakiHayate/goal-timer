// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductInfoImpl _$$ProductInfoImplFromJson(Map<String, dynamic> json) =>
    _$ProductInfoImpl(
      identifier: json['identifier'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      currencyCode: json['currencyCode'] as String,
      priceAmount: (json['priceAmount'] as num).toDouble(),
      introductoryPrice: json['introductoryPrice'] as String?,
      introductoryPeriod: json['introductoryPeriod'] as String?,
      subscriptionPeriod: json['subscriptionPeriod'] as String,
      isAvailable: json['isAvailable'] as bool,
    );

Map<String, dynamic> _$$ProductInfoImplToJson(_$ProductInfoImpl instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'currencyCode': instance.currencyCode,
      'priceAmount': instance.priceAmount,
      'introductoryPrice': instance.introductoryPrice,
      'introductoryPeriod': instance.introductoryPeriod,
      'subscriptionPeriod': instance.subscriptionPeriod,
      'isAvailable': instance.isAvailable,
    };

_$EntitlementInfoImpl _$$EntitlementInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$EntitlementInfoImpl(
      identifier: json['identifier'] as String,
      isActive: json['isActive'] as bool,
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
      latestPurchaseDate: json['latestPurchaseDate'] == null
          ? null
          : DateTime.parse(json['latestPurchaseDate'] as String),
      originalPurchaseDate: json['originalPurchaseDate'] == null
          ? null
          : DateTime.parse(json['originalPurchaseDate'] as String),
      productIdentifier: json['productIdentifier'] as String?,
      willRenew: json['willRenew'] as bool,
    );

Map<String, dynamic> _$$EntitlementInfoImplToJson(
        _$EntitlementInfoImpl instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'isActive': instance.isActive,
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'latestPurchaseDate': instance.latestPurchaseDate?.toIso8601String(),
      'originalPurchaseDate': instance.originalPurchaseDate?.toIso8601String(),
      'productIdentifier': instance.productIdentifier,
      'willRenew': instance.willRenew,
    };

_$CustomerInfoImpl _$$CustomerInfoImplFromJson(Map<String, dynamic> json) =>
    _$CustomerInfoImpl(
      originalAppUserId: json['originalAppUserId'] as String,
      entitlements: (json['entitlements'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, EntitlementInfo.fromJson(e as Map<String, dynamic>)),
      ),
      originalPurchaseDate: json['originalPurchaseDate'] == null
          ? null
          : DateTime.parse(json['originalPurchaseDate'] as String),
      latestExpirationDate: json['latestExpirationDate'] == null
          ? null
          : DateTime.parse(json['latestExpirationDate'] as String),
      allPurchaseDates:
          (json['allPurchaseDates'] as Map<String, dynamic>?)?.map(
                (k, e) =>
                    MapEntry(k, e == null ? null : DateTime.parse(e as String)),
              ) ??
              const {},
      allExpirationDates:
          (json['allExpirationDates'] as Map<String, dynamic>?)?.map(
                (k, e) =>
                    MapEntry(k, e == null ? null : DateTime.parse(e as String)),
              ) ??
              const {},
    );

Map<String, dynamic> _$$CustomerInfoImplToJson(_$CustomerInfoImpl instance) =>
    <String, dynamic>{
      'originalAppUserId': instance.originalAppUserId,
      'entitlements': instance.entitlements,
      'originalPurchaseDate': instance.originalPurchaseDate?.toIso8601String(),
      'latestExpirationDate': instance.latestExpirationDate?.toIso8601String(),
      'allPurchaseDates': instance.allPurchaseDates
          .map((k, e) => MapEntry(k, e?.toIso8601String())),
      'allExpirationDates': instance.allExpirationDates
          .map((k, e) => MapEntry(k, e?.toIso8601String())),
    };
