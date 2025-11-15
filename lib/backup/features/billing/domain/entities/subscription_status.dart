import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_status.freezed.dart';
part 'subscription_status.g.dart';

/// サブスクリプション状態
enum SubscriptionState {
  /// 未契約
  none,

  /// アクティブ
  active,

  /// トライアル中
  trial,

  /// 期限切れ
  expired,

  /// キャンセル済み（期間中）
  cancelled,

  /// 支払い問題
  billingIssue,

  /// 不明
  unknown,
}

/// ユーザーのサブスクリプション状態
@freezed
class SubscriptionStatus with _$SubscriptionStatus {
  const factory SubscriptionStatus({
    required SubscriptionState state,
    required bool isPremium,
    required String? planId,
    required DateTime? expirationDate,
    required DateTime? renewalDate,
    required bool isAutoRenew,
    required bool isInTrialPeriod,
    required DateTime? trialEndDate,
    @Default([]) List<String> entitlements,
  }) = _SubscriptionStatus;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusFromJson(json);

  /// 無料ユーザーのデフォルト状態
  static const free = SubscriptionStatus(
    state: SubscriptionState.none,
    isPremium: false,
    planId: null,
    expirationDate: null,
    renewalDate: null,
    isAutoRenew: false,
    isInTrialPeriod: false,
    trialEndDate: null,
    entitlements: [],
  );
}

/// 拡張メソッド
extension SubscriptionStatusX on SubscriptionStatus {
  /// アクティブな状態かどうか
  bool get isActive =>
      state == SubscriptionState.active ||
      state == SubscriptionState.trial ||
      state == SubscriptionState.cancelled; // キャンセル済みでも期間中はアクティブ

  /// 期限切れかどうか
  bool get isExpired => state == SubscriptionState.expired;

  /// 支払い問題があるかどうか
  bool get hasBillingIssue => state == SubscriptionState.billingIssue;

  /// プレミアム機能が使用可能かどうか
  bool get canUsePremiumFeatures => isPremium && isActive;

  /// 残り日数を取得
  int? get daysRemaining {
    if (expirationDate == null) return null;
    final now = DateTime.now();
    final difference = expirationDate!.difference(now);
    return difference.inDays;
  }

  /// トライアル残り日数を取得
  int? get trialDaysRemaining {
    if (trialEndDate == null || !isInTrialPeriod) return null;
    final now = DateTime.now();
    final difference = trialEndDate!.difference(now);
    return difference.inDays;
  }
}
