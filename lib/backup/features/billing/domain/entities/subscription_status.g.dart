// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionStatusImpl _$$SubscriptionStatusImplFromJson(
        Map<String, dynamic> json) =>
    _$SubscriptionStatusImpl(
      state: $enumDecode(_$SubscriptionStateEnumMap, json['state']),
      isPremium: json['isPremium'] as bool,
      planId: json['planId'] as String?,
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
      renewalDate: json['renewalDate'] == null
          ? null
          : DateTime.parse(json['renewalDate'] as String),
      isAutoRenew: json['isAutoRenew'] as bool,
      isInTrialPeriod: json['isInTrialPeriod'] as bool,
      trialEndDate: json['trialEndDate'] == null
          ? null
          : DateTime.parse(json['trialEndDate'] as String),
      entitlements: (json['entitlements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SubscriptionStatusImplToJson(
        _$SubscriptionStatusImpl instance) =>
    <String, dynamic>{
      'state': _$SubscriptionStateEnumMap[instance.state]!,
      'isPremium': instance.isPremium,
      'planId': instance.planId,
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'renewalDate': instance.renewalDate?.toIso8601String(),
      'isAutoRenew': instance.isAutoRenew,
      'isInTrialPeriod': instance.isInTrialPeriod,
      'trialEndDate': instance.trialEndDate?.toIso8601String(),
      'entitlements': instance.entitlements,
    };

const _$SubscriptionStateEnumMap = {
  SubscriptionState.none: 'none',
  SubscriptionState.active: 'active',
  SubscriptionState.trial: 'trial',
  SubscriptionState.expired: 'expired',
  SubscriptionState.cancelled: 'cancelled',
  SubscriptionState.billingIssue: 'billingIssue',
  SubscriptionState.unknown: 'unknown',
};
