// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'users_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods',
);

UsersModel _$UsersModelFromJson(Map<String, dynamic> json) {
  return _UsersModel.fromJson(json);
}

/// @nodoc
mixin _$UsersModel {
  String get id => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String? get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_login')
  DateTime? get lastLogin => throw _privateConstructorUsedError;
  @JsonKey(name: 'sync_updated_at')
  DateTime? get syncUpdatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UsersModelCopyWith<UsersModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UsersModelCopyWith<$Res> {
  factory $UsersModelCopyWith(
    UsersModel value,
    $Res Function(UsersModel) then,
  ) = _$UsersModelCopyWithImpl<$Res, UsersModel>;
  @useResult
  $Res call({
    String id,
    String? email,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'last_login') DateTime? lastLogin,
    @JsonKey(name: 'sync_updated_at') DateTime? syncUpdatedAt,
  });
}

/// @nodoc
class _$UsersModelCopyWithImpl<$Res, $Val extends UsersModel>
    implements $UsersModelCopyWith<$Res> {
  _$UsersModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = freezed,
    Object? displayName = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? lastLogin = freezed,
    Object? syncUpdatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            email:
                freezed == email
                    ? _value.email
                    : email // ignore: cast_nullable_to_non_nullable
                        as String?,
            displayName:
                freezed == displayName
                    ? _value.displayName
                    : displayName // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            lastLogin:
                freezed == lastLogin
                    ? _value.lastLogin
                    : lastLogin // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            syncUpdatedAt:
                freezed == syncUpdatedAt
                    ? _value.syncUpdatedAt
                    : syncUpdatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UsersModelImplCopyWith<$Res>
    implements $UsersModelCopyWith<$Res> {
  factory _$$UsersModelImplCopyWith(
    _$UsersModelImpl value,
    $Res Function(_$UsersModelImpl) then,
  ) = __$$UsersModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String? email,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'last_login') DateTime? lastLogin,
    @JsonKey(name: 'sync_updated_at') DateTime? syncUpdatedAt,
  });
}

/// @nodoc
class __$$UsersModelImplCopyWithImpl<$Res>
    extends _$UsersModelCopyWithImpl<$Res, _$UsersModelImpl>
    implements _$$UsersModelImplCopyWith<$Res> {
  __$$UsersModelImplCopyWithImpl(
    _$UsersModelImpl _value,
    $Res Function(_$UsersModelImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = freezed,
    Object? displayName = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? lastLogin = freezed,
    Object? syncUpdatedAt = freezed,
  }) {
    return _then(
      _$UsersModelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        email:
            freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                    as String?,
        displayName:
            freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        lastLogin:
            freezed == lastLogin
                ? _value.lastLogin
                : lastLogin // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        syncUpdatedAt:
            freezed == syncUpdatedAt
                ? _value.syncUpdatedAt
                : syncUpdatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UsersModelImpl extends _UsersModel {
  const _$UsersModelImpl({
    required this.id,
    this.email,
    @JsonKey(name: 'display_name') this.displayName,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'last_login') this.lastLogin,
    @JsonKey(name: 'sync_updated_at') this.syncUpdatedAt,
  }) : super._();

  factory _$UsersModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UsersModelImplFromJson(json);

  @override
  final String id;
  @override
  final String? email;
  @override
  @JsonKey(name: 'display_name')
  final String? displayName;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'last_login')
  final DateTime? lastLogin;
  @override
  @JsonKey(name: 'sync_updated_at')
  final DateTime? syncUpdatedAt;

  @override
  String toString() {
    return 'UsersModel(id: $id, email: $email, displayName: $displayName, createdAt: $createdAt, updatedAt: $updatedAt, lastLogin: $lastLogin, syncUpdatedAt: $syncUpdatedAt)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UsersModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.lastLogin, lastLogin) ||
                other.lastLogin == lastLogin) &&
            (identical(other.syncUpdatedAt, syncUpdatedAt) ||
                other.syncUpdatedAt == syncUpdatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    email,
    displayName,
    createdAt,
    updatedAt,
    lastLogin,
    syncUpdatedAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UsersModelImplCopyWith<_$UsersModelImpl> get copyWith =>
      __$$UsersModelImplCopyWithImpl<_$UsersModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UsersModelImplToJson(this);
  }
}

abstract class _UsersModel extends UsersModel {
  const factory _UsersModel({
    required final String id,
    final String? email,
    @JsonKey(name: 'display_name') final String? displayName,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'last_login') final DateTime? lastLogin,
    @JsonKey(name: 'sync_updated_at') final DateTime? syncUpdatedAt,
  }) = _$UsersModelImpl;
  const _UsersModel._() : super._();

  factory _UsersModel.fromJson(Map<String, dynamic> json) =
      _$UsersModelImpl.fromJson;

  @override
  String get id;
  @override
  String? get email;
  @override
  @JsonKey(name: 'display_name')
  String? get displayName;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'last_login')
  DateTime? get lastLogin;
  @override
  @JsonKey(name: 'sync_updated_at')
  DateTime? get syncUpdatedAt;
  @override
  @JsonKey(ignore: true)
  _$$UsersModelImplCopyWith<_$UsersModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
