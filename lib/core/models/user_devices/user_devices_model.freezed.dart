// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_devices_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserDevicesModel {

 String get id;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'fcm_token') String get fcmToken; String get platform;@JsonKey(name: 'device_name') String? get deviceName;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'last_active_at') DateTime? get lastActiveAt;
/// Create a copy of UserDevicesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDevicesModelCopyWith<UserDevicesModel> get copyWith => _$UserDevicesModelCopyWithImpl<UserDevicesModel>(this as UserDevicesModel, _$identity);

  /// Serializes this UserDevicesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDevicesModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,fcmToken,platform,deviceName,createdAt,updatedAt,lastActiveAt);

@override
String toString() {
  return 'UserDevicesModel(id: $id, userId: $userId, fcmToken: $fcmToken, platform: $platform, deviceName: $deviceName, createdAt: $createdAt, updatedAt: $updatedAt, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class $UserDevicesModelCopyWith<$Res>  {
  factory $UserDevicesModelCopyWith(UserDevicesModel value, $Res Function(UserDevicesModel) _then) = _$UserDevicesModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'fcm_token') String fcmToken, String platform,@JsonKey(name: 'device_name') String? deviceName,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'last_active_at') DateTime? lastActiveAt
});




}
/// @nodoc
class _$UserDevicesModelCopyWithImpl<$Res>
    implements $UserDevicesModelCopyWith<$Res> {
  _$UserDevicesModelCopyWithImpl(this._self, this._then);

  final UserDevicesModel _self;
  final $Res Function(UserDevicesModel) _then;

/// Create a copy of UserDevicesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? fcmToken = null,Object? platform = null,Object? deviceName = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? lastActiveAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fcmToken: null == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserDevicesModel].
extension UserDevicesModelPatterns on UserDevicesModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserDevicesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserDevicesModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserDevicesModel value)  $default,){
final _that = this;
switch (_that) {
case _UserDevicesModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserDevicesModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserDevicesModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'fcm_token')  String fcmToken,  String platform, @JsonKey(name: 'device_name')  String? deviceName, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'last_active_at')  DateTime? lastActiveAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserDevicesModel() when $default != null:
return $default(_that.id,_that.userId,_that.fcmToken,_that.platform,_that.deviceName,_that.createdAt,_that.updatedAt,_that.lastActiveAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'fcm_token')  String fcmToken,  String platform, @JsonKey(name: 'device_name')  String? deviceName, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'last_active_at')  DateTime? lastActiveAt)  $default,) {final _that = this;
switch (_that) {
case _UserDevicesModel():
return $default(_that.id,_that.userId,_that.fcmToken,_that.platform,_that.deviceName,_that.createdAt,_that.updatedAt,_that.lastActiveAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'fcm_token')  String fcmToken,  String platform, @JsonKey(name: 'device_name')  String? deviceName, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'last_active_at')  DateTime? lastActiveAt)?  $default,) {final _that = this;
switch (_that) {
case _UserDevicesModel() when $default != null:
return $default(_that.id,_that.userId,_that.fcmToken,_that.platform,_that.deviceName,_that.createdAt,_that.updatedAt,_that.lastActiveAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserDevicesModel extends UserDevicesModel {
  const _UserDevicesModel({required this.id, @JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'fcm_token') required this.fcmToken, required this.platform, @JsonKey(name: 'device_name') this.deviceName, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'last_active_at') this.lastActiveAt}): super._();
  factory _UserDevicesModel.fromJson(Map<String, dynamic> json) => _$UserDevicesModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'fcm_token') final  String fcmToken;
@override final  String platform;
@override@JsonKey(name: 'device_name') final  String? deviceName;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'last_active_at') final  DateTime? lastActiveAt;

/// Create a copy of UserDevicesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDevicesModelCopyWith<_UserDevicesModel> get copyWith => __$UserDevicesModelCopyWithImpl<_UserDevicesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDevicesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserDevicesModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fcmToken, fcmToken) || other.fcmToken == fcmToken)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,fcmToken,platform,deviceName,createdAt,updatedAt,lastActiveAt);

@override
String toString() {
  return 'UserDevicesModel(id: $id, userId: $userId, fcmToken: $fcmToken, platform: $platform, deviceName: $deviceName, createdAt: $createdAt, updatedAt: $updatedAt, lastActiveAt: $lastActiveAt)';
}


}

/// @nodoc
abstract mixin class _$UserDevicesModelCopyWith<$Res> implements $UserDevicesModelCopyWith<$Res> {
  factory _$UserDevicesModelCopyWith(_UserDevicesModel value, $Res Function(_UserDevicesModel) _then) = __$UserDevicesModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'fcm_token') String fcmToken, String platform,@JsonKey(name: 'device_name') String? deviceName,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'last_active_at') DateTime? lastActiveAt
});




}
/// @nodoc
class __$UserDevicesModelCopyWithImpl<$Res>
    implements _$UserDevicesModelCopyWith<$Res> {
  __$UserDevicesModelCopyWithImpl(this._self, this._then);

  final _UserDevicesModel _self;
  final $Res Function(_UserDevicesModel) _then;

/// Create a copy of UserDevicesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? fcmToken = null,Object? platform = null,Object? deviceName = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? lastActiveAt = freezed,}) {
  return _then(_UserDevicesModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fcmToken: null == fcmToken ? _self.fcmToken : fcmToken // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActiveAt: freezed == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
