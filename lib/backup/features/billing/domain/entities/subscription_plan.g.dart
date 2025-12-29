// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionPlanImpl _$$SubscriptionPlanImplFromJson(
  Map<String, dynamic> json,
) => _$SubscriptionPlanImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  price: json['price'] as String,
  period: json['period'] as String,
  duration: Duration(microseconds: json['duration'] as int),
  hasFreeTrial: json['hasFreeTrial'] as bool,
  trialDuration:
      json['trialDuration'] == null
          ? null
          : Duration(microseconds: json['trialDuration'] as int),
  introPrice: json['introPrice'] as String?,
  discount: json['discount'] as String?,
  features:
      (json['features'] as List<dynamic>).map((e) => e as String).toList(),
  isPopular: json['isPopular'] as bool? ?? false,
);

Map<String, dynamic> _$$SubscriptionPlanImplToJson(
  _$SubscriptionPlanImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'price': instance.price,
  'period': instance.period,
  'duration': instance.duration.inMicroseconds,
  'hasFreeTrial': instance.hasFreeTrial,
  'trialDuration': instance.trialDuration?.inMicroseconds,
  'introPrice': instance.introPrice,
  'discount': instance.discount,
  'features': instance.features,
  'isPopular': instance.isPopular,
};
