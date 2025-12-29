// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods',
);

SubscriptionStatus _$SubscriptionStatusFromJson(Map<String, dynamic> json) {
  return _SubscriptionStatus.fromJson(json);
}

/// @nodoc
mixin _$SubscriptionStatus {
  SubscriptionState get state => throw _privateConstructorUsedError;
  bool get isPremium => throw _privateConstructorUsedError;
  String? get planId => throw _privateConstructorUsedError;
  DateTime? get expirationDate => throw _privateConstructorUsedError;
  DateTime? get renewalDate => throw _privateConstructorUsedError;
  bool get isAutoRenew => throw _privateConstructorUsedError;
  bool get isInTrialPeriod => throw _privateConstructorUsedError;
  DateTime? get trialEndDate => throw _privateConstructorUsedError;
  List<String> get entitlements => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SubscriptionStatusCopyWith<SubscriptionStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubscriptionStatusCopyWith<$Res> {
  factory $SubscriptionStatusCopyWith(
    SubscriptionStatus value,
    $Res Function(SubscriptionStatus) then,
  ) = _$SubscriptionStatusCopyWithImpl<$Res, SubscriptionStatus>;
  @useResult
  $Res call({
    SubscriptionState state,
    bool isPremium,
    String? planId,
    DateTime? expirationDate,
    DateTime? renewalDate,
    bool isAutoRenew,
    bool isInTrialPeriod,
    DateTime? trialEndDate,
    List<String> entitlements,
  });
}

/// @nodoc
class _$SubscriptionStatusCopyWithImpl<$Res, $Val extends SubscriptionStatus>
    implements $SubscriptionStatusCopyWith<$Res> {
  _$SubscriptionStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? isPremium = null,
    Object? planId = freezed,
    Object? expirationDate = freezed,
    Object? renewalDate = freezed,
    Object? isAutoRenew = null,
    Object? isInTrialPeriod = null,
    Object? trialEndDate = freezed,
    Object? entitlements = null,
  }) {
    return _then(
      _value.copyWith(
            state:
                null == state
                    ? _value.state
                    : state // ignore: cast_nullable_to_non_nullable
                        as SubscriptionState,
            isPremium:
                null == isPremium
                    ? _value.isPremium
                    : isPremium // ignore: cast_nullable_to_non_nullable
                        as bool,
            planId:
                freezed == planId
                    ? _value.planId
                    : planId // ignore: cast_nullable_to_non_nullable
                        as String?,
            expirationDate:
                freezed == expirationDate
                    ? _value.expirationDate
                    : expirationDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            renewalDate:
                freezed == renewalDate
                    ? _value.renewalDate
                    : renewalDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            isAutoRenew:
                null == isAutoRenew
                    ? _value.isAutoRenew
                    : isAutoRenew // ignore: cast_nullable_to_non_nullable
                        as bool,
            isInTrialPeriod:
                null == isInTrialPeriod
                    ? _value.isInTrialPeriod
                    : isInTrialPeriod // ignore: cast_nullable_to_non_nullable
                        as bool,
            trialEndDate:
                freezed == trialEndDate
                    ? _value.trialEndDate
                    : trialEndDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            entitlements:
                null == entitlements
                    ? _value.entitlements
                    : entitlements // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SubscriptionStatusImplCopyWith<$Res>
    implements $SubscriptionStatusCopyWith<$Res> {
  factory _$$SubscriptionStatusImplCopyWith(
    _$SubscriptionStatusImpl value,
    $Res Function(_$SubscriptionStatusImpl) then,
  ) = __$$SubscriptionStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    SubscriptionState state,
    bool isPremium,
    String? planId,
    DateTime? expirationDate,
    DateTime? renewalDate,
    bool isAutoRenew,
    bool isInTrialPeriod,
    DateTime? trialEndDate,
    List<String> entitlements,
  });
}

/// @nodoc
class __$$SubscriptionStatusImplCopyWithImpl<$Res>
    extends _$SubscriptionStatusCopyWithImpl<$Res, _$SubscriptionStatusImpl>
    implements _$$SubscriptionStatusImplCopyWith<$Res> {
  __$$SubscriptionStatusImplCopyWithImpl(
    _$SubscriptionStatusImpl _value,
    $Res Function(_$SubscriptionStatusImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? isPremium = null,
    Object? planId = freezed,
    Object? expirationDate = freezed,
    Object? renewalDate = freezed,
    Object? isAutoRenew = null,
    Object? isInTrialPeriod = null,
    Object? trialEndDate = freezed,
    Object? entitlements = null,
  }) {
    return _then(
      _$SubscriptionStatusImpl(
        state:
            null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                    as SubscriptionState,
        isPremium:
            null == isPremium
                ? _value.isPremium
                : isPremium // ignore: cast_nullable_to_non_nullable
                    as bool,
        planId:
            freezed == planId
                ? _value.planId
                : planId // ignore: cast_nullable_to_non_nullable
                    as String?,
        expirationDate:
            freezed == expirationDate
                ? _value.expirationDate
                : expirationDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        renewalDate:
            freezed == renewalDate
                ? _value.renewalDate
                : renewalDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        isAutoRenew:
            null == isAutoRenew
                ? _value.isAutoRenew
                : isAutoRenew // ignore: cast_nullable_to_non_nullable
                    as bool,
        isInTrialPeriod:
            null == isInTrialPeriod
                ? _value.isInTrialPeriod
                : isInTrialPeriod // ignore: cast_nullable_to_non_nullable
                    as bool,
        trialEndDate:
            freezed == trialEndDate
                ? _value.trialEndDate
                : trialEndDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        entitlements:
            null == entitlements
                ? _value._entitlements
                : entitlements // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubscriptionStatusImpl implements _SubscriptionStatus {
  const _$SubscriptionStatusImpl({
    required this.state,
    required this.isPremium,
    required this.planId,
    required this.expirationDate,
    required this.renewalDate,
    required this.isAutoRenew,
    required this.isInTrialPeriod,
    required this.trialEndDate,
    final List<String> entitlements = const [],
  }) : _entitlements = entitlements;

  factory _$SubscriptionStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubscriptionStatusImplFromJson(json);

  @override
  final SubscriptionState state;
  @override
  final bool isPremium;
  @override
  final String? planId;
  @override
  final DateTime? expirationDate;
  @override
  final DateTime? renewalDate;
  @override
  final bool isAutoRenew;
  @override
  final bool isInTrialPeriod;
  @override
  final DateTime? trialEndDate;
  final List<String> _entitlements;
  @override
  @JsonKey()
  List<String> get entitlements {
    if (_entitlements is EqualUnmodifiableListView) return _entitlements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entitlements);
  }

  @override
  String toString() {
    return 'SubscriptionStatus(state: $state, isPremium: $isPremium, planId: $planId, expirationDate: $expirationDate, renewalDate: $renewalDate, isAutoRenew: $isAutoRenew, isInTrialPeriod: $isInTrialPeriod, trialEndDate: $trialEndDate, entitlements: $entitlements)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubscriptionStatusImpl &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.isPremium, isPremium) ||
                other.isPremium == isPremium) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.expirationDate, expirationDate) ||
                other.expirationDate == expirationDate) &&
            (identical(other.renewalDate, renewalDate) ||
                other.renewalDate == renewalDate) &&
            (identical(other.isAutoRenew, isAutoRenew) ||
                other.isAutoRenew == isAutoRenew) &&
            (identical(other.isInTrialPeriod, isInTrialPeriod) ||
                other.isInTrialPeriod == isInTrialPeriod) &&
            (identical(other.trialEndDate, trialEndDate) ||
                other.trialEndDate == trialEndDate) &&
            const DeepCollectionEquality().equals(
              other._entitlements,
              _entitlements,
            ));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    state,
    isPremium,
    planId,
    expirationDate,
    renewalDate,
    isAutoRenew,
    isInTrialPeriod,
    trialEndDate,
    const DeepCollectionEquality().hash(_entitlements),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SubscriptionStatusImplCopyWith<_$SubscriptionStatusImpl> get copyWith =>
      __$$SubscriptionStatusImplCopyWithImpl<_$SubscriptionStatusImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubscriptionStatusImplToJson(this);
  }
}

abstract class _SubscriptionStatus implements SubscriptionStatus {
  const factory _SubscriptionStatus({
    required final SubscriptionState state,
    required final bool isPremium,
    required final String? planId,
    required final DateTime? expirationDate,
    required final DateTime? renewalDate,
    required final bool isAutoRenew,
    required final bool isInTrialPeriod,
    required final DateTime? trialEndDate,
    final List<String> entitlements,
  }) = _$SubscriptionStatusImpl;

  factory _SubscriptionStatus.fromJson(Map<String, dynamic> json) =
      _$SubscriptionStatusImpl.fromJson;

  @override
  SubscriptionState get state;
  @override
  bool get isPremium;
  @override
  String? get planId;
  @override
  DateTime? get expirationDate;
  @override
  DateTime? get renewalDate;
  @override
  bool get isAutoRenew;
  @override
  bool get isInTrialPeriod;
  @override
  DateTime? get trialEndDate;
  @override
  List<String> get entitlements;
  @override
  @JsonKey(ignore: true)
  _$$SubscriptionStatusImplCopyWith<_$SubscriptionStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
