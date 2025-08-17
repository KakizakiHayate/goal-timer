// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PurchaseResultImpl _$$PurchaseResultImplFromJson(Map<String, dynamic> json) =>
    _$PurchaseResultImpl(
      type: $enumDecode(_$PurchaseResultTypeEnumMap, json['type']),
      transactionId: json['transactionId'] as String?,
      productId: json['productId'] as String?,
      purchaseDate: json['purchaseDate'] == null
          ? null
          : DateTime.parse(json['purchaseDate'] as String),
      errorType:
          $enumDecodeNullable(_$PurchaseErrorTypeEnumMap, json['errorType']),
      errorMessage: json['errorMessage'] as String?,
      needsFinalization: json['needsFinalization'] as bool? ?? false,
    );

Map<String, dynamic> _$$PurchaseResultImplToJson(
        _$PurchaseResultImpl instance) =>
    <String, dynamic>{
      'type': _$PurchaseResultTypeEnumMap[instance.type]!,
      'transactionId': instance.transactionId,
      'productId': instance.productId,
      'purchaseDate': instance.purchaseDate?.toIso8601String(),
      'errorType': _$PurchaseErrorTypeEnumMap[instance.errorType],
      'errorMessage': instance.errorMessage,
      'needsFinalization': instance.needsFinalization,
    };

const _$PurchaseResultTypeEnumMap = {
  PurchaseResultType.success: 'success',
  PurchaseResultType.cancelled: 'cancelled',
  PurchaseResultType.pending: 'pending',
  PurchaseResultType.error: 'error',
  PurchaseResultType.unknown: 'unknown',
};

const _$PurchaseErrorTypeEnumMap = {
  PurchaseErrorType.network: 'network',
  PurchaseErrorType.paymentDeclined: 'paymentDeclined',
  PurchaseErrorType.productNotFound: 'productNotFound',
  PurchaseErrorType.alreadyOwned: 'alreadyOwned',
  PurchaseErrorType.server: 'server',
  PurchaseErrorType.system: 'system',
  PurchaseErrorType.unknown: 'unknown',
};

_$RestoreResultImpl _$$RestoreResultImplFromJson(Map<String, dynamic> json) =>
    _$RestoreResultImpl(
      success: json['success'] as bool,
      restoredCount: json['restoredCount'] as int,
      errorMessage: json['errorMessage'] as String?,
      restoredProductIds: (json['restoredProductIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$RestoreResultImplToJson(_$RestoreResultImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'restoredCount': instance.restoredCount,
      'errorMessage': instance.errorMessage,
      'restoredProductIds': instance.restoredProductIds,
    };
