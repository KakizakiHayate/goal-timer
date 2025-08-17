import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_plan.freezed.dart';
part 'subscription_plan.g.dart';

/// サブスクリプションプラン情報
@freezed
class SubscriptionPlan with _$SubscriptionPlan {
  const factory SubscriptionPlan({
    required String id,
    required String title,
    required String price,
    required String period,
    required Duration duration,
    required bool hasFreeTrial,
    required Duration? trialDuration,
    required String? introPrice,
    required String? discount,
    required List<String> features,
    @Default(false) bool isPopular,
  }) = _SubscriptionPlan;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);
}

/// 定義済みのサブスクリプションプラン
class PredefinedPlans {
  static const monthly = SubscriptionPlan(
    id: 'monthly',
    title: '月額プラン',
    price: '¥500',
    period: '/月',
    duration: Duration(days: 30),
    hasFreeTrial: true,
    trialDuration: Duration(days: 7),
    introPrice: '¥240',
    discount: '50%オフ',
    features: [
      '無制限の目標作成',
      'ポモドーロタイマー',
      'CSVデータエクスポート',
    ],
  );

  static const yearly = SubscriptionPlan(
    id: 'yearly',
    title: '年額プラン',
    price: '¥6,000',
    period: '/年',
    duration: Duration(days: 365),
    hasFreeTrial: true,
    trialDuration: Duration(days: 7),
    introPrice: null,
    discount: '17%お得',
    features: [
      '無制限の目標作成',
      'ポモドーロタイマー',
      'CSVデータエクスポート',
      '月額換算 ¥400（¥80お得）',
    ],
    isPopular: true,
  );

  static const List<SubscriptionPlan> allPlans = [monthly, yearly];
}