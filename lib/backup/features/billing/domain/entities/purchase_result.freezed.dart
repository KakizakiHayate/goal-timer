// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods',
);

PurchaseResult _$PurchaseResultFromJson(Map<String, dynamic> json) {
  return _PurchaseResult.fromJson(json);
}

/// @nodoc
mixin _$PurchaseResult {
  PurchaseResultType get type => throw _privateConstructorUsedError;
  String? get transactionId => throw _privateConstructorUsedError;
  String? get productId => throw _privateConstructorUsedError;
  DateTime? get purchaseDate => throw _privateConstructorUsedError;
  PurchaseErrorType? get errorType => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  bool get needsFinalization => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PurchaseResultCopyWith<PurchaseResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PurchaseResultCopyWith<$Res> {
  factory $PurchaseResultCopyWith(
    PurchaseResult value,
    $Res Function(PurchaseResult) then,
  ) = _$PurchaseResultCopyWithImpl<$Res, PurchaseResult>;
  @useResult
  $Res call({
    PurchaseResultType type,
    String? transactionId,
    String? productId,
    DateTime? purchaseDate,
    PurchaseErrorType? errorType,
    String? errorMessage,
    bool needsFinalization,
  });
}

/// @nodoc
class _$PurchaseResultCopyWithImpl<$Res, $Val extends PurchaseResult>
    implements $PurchaseResultCopyWith<$Res> {
  _$PurchaseResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? transactionId = freezed,
    Object? productId = freezed,
    Object? purchaseDate = freezed,
    Object? errorType = freezed,
    Object? errorMessage = freezed,
    Object? needsFinalization = null,
  }) {
    return _then(
      _value.copyWith(
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as PurchaseResultType,
            transactionId:
                freezed == transactionId
                    ? _value.transactionId
                    : transactionId // ignore: cast_nullable_to_non_nullable
                        as String?,
            productId:
                freezed == productId
                    ? _value.productId
                    : productId // ignore: cast_nullable_to_non_nullable
                        as String?,
            purchaseDate:
                freezed == purchaseDate
                    ? _value.purchaseDate
                    : purchaseDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            errorType:
                freezed == errorType
                    ? _value.errorType
                    : errorType // ignore: cast_nullable_to_non_nullable
                        as PurchaseErrorType?,
            errorMessage:
                freezed == errorMessage
                    ? _value.errorMessage
                    : errorMessage // ignore: cast_nullable_to_non_nullable
                        as String?,
            needsFinalization:
                null == needsFinalization
                    ? _value.needsFinalization
                    : needsFinalization // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PurchaseResultImplCopyWith<$Res>
    implements $PurchaseResultCopyWith<$Res> {
  factory _$$PurchaseResultImplCopyWith(
    _$PurchaseResultImpl value,
    $Res Function(_$PurchaseResultImpl) then,
  ) = __$$PurchaseResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PurchaseResultType type,
    String? transactionId,
    String? productId,
    DateTime? purchaseDate,
    PurchaseErrorType? errorType,
    String? errorMessage,
    bool needsFinalization,
  });
}

/// @nodoc
class __$$PurchaseResultImplCopyWithImpl<$Res>
    extends _$PurchaseResultCopyWithImpl<$Res, _$PurchaseResultImpl>
    implements _$$PurchaseResultImplCopyWith<$Res> {
  __$$PurchaseResultImplCopyWithImpl(
    _$PurchaseResultImpl _value,
    $Res Function(_$PurchaseResultImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? transactionId = freezed,
    Object? productId = freezed,
    Object? purchaseDate = freezed,
    Object? errorType = freezed,
    Object? errorMessage = freezed,
    Object? needsFinalization = null,
  }) {
    return _then(
      _$PurchaseResultImpl(
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as PurchaseResultType,
        transactionId:
            freezed == transactionId
                ? _value.transactionId
                : transactionId // ignore: cast_nullable_to_non_nullable
                    as String?,
        productId:
            freezed == productId
                ? _value.productId
                : productId // ignore: cast_nullable_to_non_nullable
                    as String?,
        purchaseDate:
            freezed == purchaseDate
                ? _value.purchaseDate
                : purchaseDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        errorType:
            freezed == errorType
                ? _value.errorType
                : errorType // ignore: cast_nullable_to_non_nullable
                    as PurchaseErrorType?,
        errorMessage:
            freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                    as String?,
        needsFinalization:
            null == needsFinalization
                ? _value.needsFinalization
                : needsFinalization // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PurchaseResultImpl implements _PurchaseResult {
  const _$PurchaseResultImpl({
    required this.type,
    required this.transactionId,
    required this.productId,
    required this.purchaseDate,
    required this.errorType,
    required this.errorMessage,
    this.needsFinalization = false,
  });

  factory _$PurchaseResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$PurchaseResultImplFromJson(json);

  @override
  final PurchaseResultType type;
  @override
  final String? transactionId;
  @override
  final String? productId;
  @override
  final DateTime? purchaseDate;
  @override
  final PurchaseErrorType? errorType;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final bool needsFinalization;

  @override
  String toString() {
    return 'PurchaseResult(type: $type, transactionId: $transactionId, productId: $productId, purchaseDate: $purchaseDate, errorType: $errorType, errorMessage: $errorMessage, needsFinalization: $needsFinalization)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseResultImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.errorType, errorType) ||
                other.errorType == errorType) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.needsFinalization, needsFinalization) ||
                other.needsFinalization == needsFinalization));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    transactionId,
    productId,
    purchaseDate,
    errorType,
    errorMessage,
    needsFinalization,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseResultImplCopyWith<_$PurchaseResultImpl> get copyWith =>
      __$$PurchaseResultImplCopyWithImpl<_$PurchaseResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PurchaseResultImplToJson(this);
  }
}

abstract class _PurchaseResult implements PurchaseResult {
  const factory _PurchaseResult({
    required final PurchaseResultType type,
    required final String? transactionId,
    required final String? productId,
    required final DateTime? purchaseDate,
    required final PurchaseErrorType? errorType,
    required final String? errorMessage,
    final bool needsFinalization,
  }) = _$PurchaseResultImpl;

  factory _PurchaseResult.fromJson(Map<String, dynamic> json) =
      _$PurchaseResultImpl.fromJson;

  @override
  PurchaseResultType get type;
  @override
  String? get transactionId;
  @override
  String? get productId;
  @override
  DateTime? get purchaseDate;
  @override
  PurchaseErrorType? get errorType;
  @override
  String? get errorMessage;
  @override
  bool get needsFinalization;
  @override
  @JsonKey(ignore: true)
  _$$PurchaseResultImplCopyWith<_$PurchaseResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RestoreResult _$RestoreResultFromJson(Map<String, dynamic> json) {
  return _RestoreResult.fromJson(json);
}

/// @nodoc
mixin _$RestoreResult {
  bool get success => throw _privateConstructorUsedError;
  int get restoredCount => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  List<String> get restoredProductIds => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RestoreResultCopyWith<RestoreResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestoreResultCopyWith<$Res> {
  factory $RestoreResultCopyWith(
    RestoreResult value,
    $Res Function(RestoreResult) then,
  ) = _$RestoreResultCopyWithImpl<$Res, RestoreResult>;
  @useResult
  $Res call({
    bool success,
    int restoredCount,
    String? errorMessage,
    List<String> restoredProductIds,
  });
}

/// @nodoc
class _$RestoreResultCopyWithImpl<$Res, $Val extends RestoreResult>
    implements $RestoreResultCopyWith<$Res> {
  _$RestoreResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? restoredCount = null,
    Object? errorMessage = freezed,
    Object? restoredProductIds = null,
  }) {
    return _then(
      _value.copyWith(
            success:
                null == success
                    ? _value.success
                    : success // ignore: cast_nullable_to_non_nullable
                        as bool,
            restoredCount:
                null == restoredCount
                    ? _value.restoredCount
                    : restoredCount // ignore: cast_nullable_to_non_nullable
                        as int,
            errorMessage:
                freezed == errorMessage
                    ? _value.errorMessage
                    : errorMessage // ignore: cast_nullable_to_non_nullable
                        as String?,
            restoredProductIds:
                null == restoredProductIds
                    ? _value.restoredProductIds
                    : restoredProductIds // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RestoreResultImplCopyWith<$Res>
    implements $RestoreResultCopyWith<$Res> {
  factory _$$RestoreResultImplCopyWith(
    _$RestoreResultImpl value,
    $Res Function(_$RestoreResultImpl) then,
  ) = __$$RestoreResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool success,
    int restoredCount,
    String? errorMessage,
    List<String> restoredProductIds,
  });
}

/// @nodoc
class __$$RestoreResultImplCopyWithImpl<$Res>
    extends _$RestoreResultCopyWithImpl<$Res, _$RestoreResultImpl>
    implements _$$RestoreResultImplCopyWith<$Res> {
  __$$RestoreResultImplCopyWithImpl(
    _$RestoreResultImpl _value,
    $Res Function(_$RestoreResultImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? restoredCount = null,
    Object? errorMessage = freezed,
    Object? restoredProductIds = null,
  }) {
    return _then(
      _$RestoreResultImpl(
        success:
            null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                    as bool,
        restoredCount:
            null == restoredCount
                ? _value.restoredCount
                : restoredCount // ignore: cast_nullable_to_non_nullable
                    as int,
        errorMessage:
            freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                    as String?,
        restoredProductIds:
            null == restoredProductIds
                ? _value._restoredProductIds
                : restoredProductIds // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RestoreResultImpl implements _RestoreResult {
  const _$RestoreResultImpl({
    required this.success,
    required this.restoredCount,
    required this.errorMessage,
    required final List<String> restoredProductIds,
  }) : _restoredProductIds = restoredProductIds;

  factory _$RestoreResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$RestoreResultImplFromJson(json);

  @override
  final bool success;
  @override
  final int restoredCount;
  @override
  final String? errorMessage;
  final List<String> _restoredProductIds;
  @override
  List<String> get restoredProductIds {
    if (_restoredProductIds is EqualUnmodifiableListView)
      return _restoredProductIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_restoredProductIds);
  }

  @override
  String toString() {
    return 'RestoreResult(success: $success, restoredCount: $restoredCount, errorMessage: $errorMessage, restoredProductIds: $restoredProductIds)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestoreResultImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.restoredCount, restoredCount) ||
                other.restoredCount == restoredCount) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality().equals(
              other._restoredProductIds,
              _restoredProductIds,
            ));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    success,
    restoredCount,
    errorMessage,
    const DeepCollectionEquality().hash(_restoredProductIds),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RestoreResultImplCopyWith<_$RestoreResultImpl> get copyWith =>
      __$$RestoreResultImplCopyWithImpl<_$RestoreResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RestoreResultImplToJson(this);
  }
}

abstract class _RestoreResult implements RestoreResult {
  const factory _RestoreResult({
    required final bool success,
    required final int restoredCount,
    required final String? errorMessage,
    required final List<String> restoredProductIds,
  }) = _$RestoreResultImpl;

  factory _RestoreResult.fromJson(Map<String, dynamic> json) =
      _$RestoreResultImpl.fromJson;

  @override
  bool get success;
  @override
  int get restoredCount;
  @override
  String? get errorMessage;
  @override
  List<String> get restoredProductIds;
  @override
  @JsonKey(ignore: true)
  _$$RestoreResultImplCopyWith<_$RestoreResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
