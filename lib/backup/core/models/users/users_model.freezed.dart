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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

UsersModel _$UsersModelFromJson(Map<String, dynamic> json) {
  return _UsersModel.fromJson(json);
}

/// @nodoc
mixin _$UsersModel {
  /// ユーザーのid管理
  String get id => throw _privateConstructorUsedError;

  /// ユーザーのメールアドレス
  String get email => throw _privateConstructorUsedError;

  /// ユーザーの表示名
  String get displayName => throw _privateConstructorUsedError;

  /// アカウント作成日時
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 最終更新日時
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// 最終ログイン日時
  DateTime? get lastLogin => throw _privateConstructorUsedError;

  /// 同期時の最終更新日時（同期処理で使用）
  DateTime? get syncUpdatedAt => throw _privateConstructorUsedError;

  /// 同期状態（ローカルDBのみで使用）
  bool get isSynced => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UsersModelCopyWith<UsersModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UsersModelCopyWith<$Res> {
  factory $UsersModelCopyWith(
          UsersModel value, $Res Function(UsersModel) then) =
      _$UsersModelCopyWithImpl<$Res, UsersModel>;
  @useResult
  $Res call(
      {String id,
      String email,
      String displayName,
      DateTime createdAt,
      DateTime updatedAt,
      DateTime? lastLogin,
      DateTime? syncUpdatedAt,
      bool isSynced});
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
    Object? email = null,
    Object? displayName = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? lastLogin = freezed,
    Object? syncUpdatedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastLogin: freezed == lastLogin
          ? _value.lastLogin
          : lastLogin // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncUpdatedAt: freezed == syncUpdatedAt
          ? _value.syncUpdatedAt
          : syncUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UsersModelImplCopyWith<$Res>
    implements $UsersModelCopyWith<$Res> {
  factory _$$UsersModelImplCopyWith(
          _$UsersModelImpl value, $Res Function(_$UsersModelImpl) then) =
      __$$UsersModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      String displayName,
      DateTime createdAt,
      DateTime updatedAt,
      DateTime? lastLogin,
      DateTime? syncUpdatedAt,
      bool isSynced});
}

/// @nodoc
class __$$UsersModelImplCopyWithImpl<$Res>
    extends _$UsersModelCopyWithImpl<$Res, _$UsersModelImpl>
    implements _$$UsersModelImplCopyWith<$Res> {
  __$$UsersModelImplCopyWithImpl(
      _$UsersModelImpl _value, $Res Function(_$UsersModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? lastLogin = freezed,
    Object? syncUpdatedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_$UsersModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastLogin: freezed == lastLogin
          ? _value.lastLogin
          : lastLogin // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncUpdatedAt: freezed == syncUpdatedAt
          ? _value.syncUpdatedAt
          : syncUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UsersModelImpl implements _UsersModel {
  const _$UsersModelImpl(
      {required this.id,
      required this.email,
      required this.displayName,
      required this.createdAt,
      required this.updatedAt,
      this.lastLogin,
      this.syncUpdatedAt = null,
      this.isSynced = false});

  factory _$UsersModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UsersModelImplFromJson(json);

  /// ユーザーのid管理
  @override
  final String id;

  /// ユーザーのメールアドレス
  @override
  final String email;

  /// ユーザーの表示名
  @override
  final String displayName;

  /// アカウント作成日時
  @override
  final DateTime createdAt;

  /// 最終更新日時
  @override
  final DateTime updatedAt;

  /// 最終ログイン日時
  @override
  final DateTime? lastLogin;

  /// 同期時の最終更新日時（同期処理で使用）
  @override
  @JsonKey()
  final DateTime? syncUpdatedAt;

  /// 同期状態（ローカルDBのみで使用）
  @override
  @JsonKey()
  final bool isSynced;

  @override
  String toString() {
    return 'UsersModel(id: $id, email: $email, displayName: $displayName, createdAt: $createdAt, updatedAt: $updatedAt, lastLogin: $lastLogin, syncUpdatedAt: $syncUpdatedAt, isSynced: $isSynced)';
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
                other.syncUpdatedAt == syncUpdatedAt) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, displayName,
      createdAt, updatedAt, lastLogin, syncUpdatedAt, isSynced);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UsersModelImplCopyWith<_$UsersModelImpl> get copyWith =>
      __$$UsersModelImplCopyWithImpl<_$UsersModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UsersModelImplToJson(
      this,
    );
  }
}

abstract class _UsersModel implements UsersModel {
  const factory _UsersModel(
      {required final String id,
      required final String email,
      required final String displayName,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final DateTime? lastLogin,
      final DateTime? syncUpdatedAt,
      final bool isSynced}) = _$UsersModelImpl;

  factory _UsersModel.fromJson(Map<String, dynamic> json) =
      _$UsersModelImpl.fromJson;

  @override

  /// ユーザーのid管理
  String get id;
  @override

  /// ユーザーのメールアドレス
  String get email;
  @override

  /// ユーザーの表示名
  String get displayName;
  @override

  /// アカウント作成日時
  DateTime get createdAt;
  @override

  /// 最終更新日時
  DateTime get updatedAt;
  @override

  /// 最終ログイン日時
  DateTime? get lastLogin;
  @override

  /// 同期時の最終更新日時（同期処理で使用）
  DateTime? get syncUpdatedAt;
  @override

  /// 同期状態（ローカルDBのみで使用）
  bool get isSynced;
  @override
  @JsonKey(ignore: true)
  _$$UsersModelImplCopyWith<_$UsersModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
