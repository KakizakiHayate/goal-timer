// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$BillingState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isPurchasing => throw _privateConstructorUsedError;
  SubscriptionStatus? get subscriptionStatus =>
      throw _privateConstructorUsedError;
  List<ProductInfo> get availableProducts => throw _privateConstructorUsedError;
  String? get selectedProductId => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  PurchaseResult? get lastPurchaseResult => throw _privateConstructorUsedError;
  RestoreResult? get lastRestoreResult => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BillingStateCopyWith<BillingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BillingStateCopyWith<$Res> {
  factory $BillingStateCopyWith(
          BillingState value, $Res Function(BillingState) then) =
      _$BillingStateCopyWithImpl<$Res, BillingState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isPurchasing,
      SubscriptionStatus? subscriptionStatus,
      List<ProductInfo> availableProducts,
      String? selectedProductId,
      String? errorMessage,
      PurchaseResult? lastPurchaseResult,
      RestoreResult? lastRestoreResult});

  $SubscriptionStatusCopyWith<$Res>? get subscriptionStatus;
  $PurchaseResultCopyWith<$Res>? get lastPurchaseResult;
  $RestoreResultCopyWith<$Res>? get lastRestoreResult;
}

/// @nodoc
class _$BillingStateCopyWithImpl<$Res, $Val extends BillingState>
    implements $BillingStateCopyWith<$Res> {
  _$BillingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isPurchasing = null,
    Object? subscriptionStatus = freezed,
    Object? availableProducts = null,
    Object? selectedProductId = freezed,
    Object? errorMessage = freezed,
    Object? lastPurchaseResult = freezed,
    Object? lastRestoreResult = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isPurchasing: null == isPurchasing
          ? _value.isPurchasing
          : isPurchasing // ignore: cast_nullable_to_non_nullable
              as bool,
      subscriptionStatus: freezed == subscriptionStatus
          ? _value.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as SubscriptionStatus?,
      availableProducts: null == availableProducts
          ? _value.availableProducts
          : availableProducts // ignore: cast_nullable_to_non_nullable
              as List<ProductInfo>,
      selectedProductId: freezed == selectedProductId
          ? _value.selectedProductId
          : selectedProductId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastPurchaseResult: freezed == lastPurchaseResult
          ? _value.lastPurchaseResult
          : lastPurchaseResult // ignore: cast_nullable_to_non_nullable
              as PurchaseResult?,
      lastRestoreResult: freezed == lastRestoreResult
          ? _value.lastRestoreResult
          : lastRestoreResult // ignore: cast_nullable_to_non_nullable
              as RestoreResult?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SubscriptionStatusCopyWith<$Res>? get subscriptionStatus {
    if (_value.subscriptionStatus == null) {
      return null;
    }

    return $SubscriptionStatusCopyWith<$Res>(_value.subscriptionStatus!,
        (value) {
      return _then(_value.copyWith(subscriptionStatus: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PurchaseResultCopyWith<$Res>? get lastPurchaseResult {
    if (_value.lastPurchaseResult == null) {
      return null;
    }

    return $PurchaseResultCopyWith<$Res>(_value.lastPurchaseResult!, (value) {
      return _then(_value.copyWith(lastPurchaseResult: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $RestoreResultCopyWith<$Res>? get lastRestoreResult {
    if (_value.lastRestoreResult == null) {
      return null;
    }

    return $RestoreResultCopyWith<$Res>(_value.lastRestoreResult!, (value) {
      return _then(_value.copyWith(lastRestoreResult: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BillingStateImplCopyWith<$Res>
    implements $BillingStateCopyWith<$Res> {
  factory _$$BillingStateImplCopyWith(
          _$BillingStateImpl value, $Res Function(_$BillingStateImpl) then) =
      __$$BillingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isPurchasing,
      SubscriptionStatus? subscriptionStatus,
      List<ProductInfo> availableProducts,
      String? selectedProductId,
      String? errorMessage,
      PurchaseResult? lastPurchaseResult,
      RestoreResult? lastRestoreResult});

  @override
  $SubscriptionStatusCopyWith<$Res>? get subscriptionStatus;
  @override
  $PurchaseResultCopyWith<$Res>? get lastPurchaseResult;
  @override
  $RestoreResultCopyWith<$Res>? get lastRestoreResult;
}

/// @nodoc
class __$$BillingStateImplCopyWithImpl<$Res>
    extends _$BillingStateCopyWithImpl<$Res, _$BillingStateImpl>
    implements _$$BillingStateImplCopyWith<$Res> {
  __$$BillingStateImplCopyWithImpl(
      _$BillingStateImpl _value, $Res Function(_$BillingStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isPurchasing = null,
    Object? subscriptionStatus = freezed,
    Object? availableProducts = null,
    Object? selectedProductId = freezed,
    Object? errorMessage = freezed,
    Object? lastPurchaseResult = freezed,
    Object? lastRestoreResult = freezed,
  }) {
    return _then(_$BillingStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isPurchasing: null == isPurchasing
          ? _value.isPurchasing
          : isPurchasing // ignore: cast_nullable_to_non_nullable
              as bool,
      subscriptionStatus: freezed == subscriptionStatus
          ? _value.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as SubscriptionStatus?,
      availableProducts: null == availableProducts
          ? _value._availableProducts
          : availableProducts // ignore: cast_nullable_to_non_nullable
              as List<ProductInfo>,
      selectedProductId: freezed == selectedProductId
          ? _value.selectedProductId
          : selectedProductId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastPurchaseResult: freezed == lastPurchaseResult
          ? _value.lastPurchaseResult
          : lastPurchaseResult // ignore: cast_nullable_to_non_nullable
              as PurchaseResult?,
      lastRestoreResult: freezed == lastRestoreResult
          ? _value.lastRestoreResult
          : lastRestoreResult // ignore: cast_nullable_to_non_nullable
              as RestoreResult?,
    ));
  }
}

/// @nodoc

class _$BillingStateImpl implements _BillingState {
  const _$BillingStateImpl(
      {this.isLoading = false,
      this.isPurchasing = false,
      this.subscriptionStatus = null,
      final List<ProductInfo> availableProducts = const [],
      this.selectedProductId = null,
      this.errorMessage = null,
      this.lastPurchaseResult = null,
      this.lastRestoreResult = null})
      : _availableProducts = availableProducts;

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isPurchasing;
  @override
  @JsonKey()
  final SubscriptionStatus? subscriptionStatus;
  final List<ProductInfo> _availableProducts;
  @override
  @JsonKey()
  List<ProductInfo> get availableProducts {
    if (_availableProducts is EqualUnmodifiableListView)
      return _availableProducts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableProducts);
  }

  @override
  @JsonKey()
  final String? selectedProductId;
  @override
  @JsonKey()
  final String? errorMessage;
  @override
  @JsonKey()
  final PurchaseResult? lastPurchaseResult;
  @override
  @JsonKey()
  final RestoreResult? lastRestoreResult;

  @override
  String toString() {
    return 'BillingState(isLoading: $isLoading, isPurchasing: $isPurchasing, subscriptionStatus: $subscriptionStatus, availableProducts: $availableProducts, selectedProductId: $selectedProductId, errorMessage: $errorMessage, lastPurchaseResult: $lastPurchaseResult, lastRestoreResult: $lastRestoreResult)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BillingStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isPurchasing, isPurchasing) ||
                other.isPurchasing == isPurchasing) &&
            (identical(other.subscriptionStatus, subscriptionStatus) ||
                other.subscriptionStatus == subscriptionStatus) &&
            const DeepCollectionEquality()
                .equals(other._availableProducts, _availableProducts) &&
            (identical(other.selectedProductId, selectedProductId) ||
                other.selectedProductId == selectedProductId) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.lastPurchaseResult, lastPurchaseResult) ||
                other.lastPurchaseResult == lastPurchaseResult) &&
            (identical(other.lastRestoreResult, lastRestoreResult) ||
                other.lastRestoreResult == lastRestoreResult));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      isPurchasing,
      subscriptionStatus,
      const DeepCollectionEquality().hash(_availableProducts),
      selectedProductId,
      errorMessage,
      lastPurchaseResult,
      lastRestoreResult);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BillingStateImplCopyWith<_$BillingStateImpl> get copyWith =>
      __$$BillingStateImplCopyWithImpl<_$BillingStateImpl>(this, _$identity);
}

abstract class _BillingState implements BillingState {
  const factory _BillingState(
      {final bool isLoading,
      final bool isPurchasing,
      final SubscriptionStatus? subscriptionStatus,
      final List<ProductInfo> availableProducts,
      final String? selectedProductId,
      final String? errorMessage,
      final PurchaseResult? lastPurchaseResult,
      final RestoreResult? lastRestoreResult}) = _$BillingStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isPurchasing;
  @override
  SubscriptionStatus? get subscriptionStatus;
  @override
  List<ProductInfo> get availableProducts;
  @override
  String? get selectedProductId;
  @override
  String? get errorMessage;
  @override
  PurchaseResult? get lastPurchaseResult;
  @override
  RestoreResult? get lastRestoreResult;
  @override
  @JsonKey(ignore: true)
  _$$BillingStateImplCopyWith<_$BillingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
