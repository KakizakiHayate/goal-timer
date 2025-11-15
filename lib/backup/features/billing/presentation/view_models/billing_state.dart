import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/entities.dart';

part 'billing_state.freezed.dart';

/// 課金画面の状態
@freezed
class BillingState with _$BillingState {
  const factory BillingState({
    @Default(false) bool isLoading,
    @Default(false) bool isPurchasing,
    @Default(null) SubscriptionStatus? subscriptionStatus,
    @Default([]) List<ProductInfo> availableProducts,
    @Default(null) String? selectedProductId,
    @Default(null) String? errorMessage,
    @Default(null) PurchaseResult? lastPurchaseResult,
    @Default(null) RestoreResult? lastRestoreResult,
  }) = _BillingState;
}
