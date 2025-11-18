// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goals_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

GoalsModel _$GoalsModelFromJson(Map<String, dynamic> json) {
  return _GoalsModel.fromJson(json);
}

/// @nodoc
mixin _$GoalsModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError; // nullable
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError; // nullable
  DateTime get deadline => throw _privateConstructorUsedError;
  @JsonKey(name: 'avoid_message')
  String get avoidMessage => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'sync_updated_at')
  DateTime? get syncUpdatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_minutes')
  int get targetMinutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GoalsModelCopyWith<GoalsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalsModelCopyWith<$Res> {
  factory $GoalsModelCopyWith(
          GoalsModel value, $Res Function(GoalsModel) then) =
      _$GoalsModelCopyWithImpl<$Res, GoalsModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String? userId,
      String title,
      String? description,
      DateTime deadline,
      @JsonKey(name: 'avoid_message') String avoidMessage,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'sync_updated_at') DateTime? syncUpdatedAt,
      @JsonKey(name: 'target_minutes') int targetMinutes,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'completed_at') DateTime? completedAt});
}

/// @nodoc
class _$GoalsModelCopyWithImpl<$Res, $Val extends GoalsModel>
    implements $GoalsModelCopyWith<$Res> {
  _$GoalsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? deadline = null,
    Object? avoidMessage = null,
    Object? updatedAt = freezed,
    Object? syncUpdatedAt = freezed,
    Object? targetMinutes = null,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      deadline: null == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime,
      avoidMessage: null == avoidMessage
          ? _value.avoidMessage
          : avoidMessage // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncUpdatedAt: freezed == syncUpdatedAt
          ? _value.syncUpdatedAt
          : syncUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      targetMinutes: null == targetMinutes
          ? _value.targetMinutes
          : targetMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoalsModelImplCopyWith<$Res>
    implements $GoalsModelCopyWith<$Res> {
  factory _$$GoalsModelImplCopyWith(
          _$GoalsModelImpl value, $Res Function(_$GoalsModelImpl) then) =
      __$$GoalsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String? userId,
      String title,
      String? description,
      DateTime deadline,
      @JsonKey(name: 'avoid_message') String avoidMessage,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'sync_updated_at') DateTime? syncUpdatedAt,
      @JsonKey(name: 'target_minutes') int targetMinutes,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'completed_at') DateTime? completedAt});
}

/// @nodoc
class __$$GoalsModelImplCopyWithImpl<$Res>
    extends _$GoalsModelCopyWithImpl<$Res, _$GoalsModelImpl>
    implements _$$GoalsModelImplCopyWith<$Res> {
  __$$GoalsModelImplCopyWithImpl(
      _$GoalsModelImpl _value, $Res Function(_$GoalsModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? title = null,
    Object? description = freezed,
    Object? deadline = null,
    Object? avoidMessage = null,
    Object? updatedAt = freezed,
    Object? syncUpdatedAt = freezed,
    Object? targetMinutes = null,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(_$GoalsModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      deadline: null == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime,
      avoidMessage: null == avoidMessage
          ? _value.avoidMessage
          : avoidMessage // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      syncUpdatedAt: freezed == syncUpdatedAt
          ? _value.syncUpdatedAt
          : syncUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      targetMinutes: null == targetMinutes
          ? _value.targetMinutes
          : targetMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GoalsModelImpl extends _GoalsModel {
  const _$GoalsModelImpl(
      {required this.id,
      @JsonKey(name: 'user_id') this.userId,
      required this.title,
      this.description,
      required this.deadline,
      @JsonKey(name: 'avoid_message') required this.avoidMessage,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'sync_updated_at') this.syncUpdatedAt,
      @JsonKey(name: 'target_minutes') required this.targetMinutes,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'completed_at') this.completedAt})
      : super._();

  factory _$GoalsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalsModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
// nullable
  @override
  final String title;
  @override
  final String? description;
// nullable
  @override
  final DateTime deadline;
  @override
  @JsonKey(name: 'avoid_message')
  final String avoidMessage;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'sync_updated_at')
  final DateTime? syncUpdatedAt;
  @override
  @JsonKey(name: 'target_minutes')
  final int targetMinutes;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  @override
  String toString() {
    return 'GoalsModel(id: $id, userId: $userId, title: $title, description: $description, deadline: $deadline, avoidMessage: $avoidMessage, updatedAt: $updatedAt, syncUpdatedAt: $syncUpdatedAt, targetMinutes: $targetMinutes, createdAt: $createdAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalsModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.avoidMessage, avoidMessage) ||
                other.avoidMessage == avoidMessage) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.syncUpdatedAt, syncUpdatedAt) ||
                other.syncUpdatedAt == syncUpdatedAt) &&
            (identical(other.targetMinutes, targetMinutes) ||
                other.targetMinutes == targetMinutes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      title,
      description,
      deadline,
      avoidMessage,
      updatedAt,
      syncUpdatedAt,
      targetMinutes,
      createdAt,
      completedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalsModelImplCopyWith<_$GoalsModelImpl> get copyWith =>
      __$$GoalsModelImplCopyWithImpl<_$GoalsModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalsModelImplToJson(
      this,
    );
  }
}

abstract class _GoalsModel extends GoalsModel {
  const factory _GoalsModel(
          {required final String id,
          @JsonKey(name: 'user_id') final String? userId,
          required final String title,
          final String? description,
          required final DateTime deadline,
          @JsonKey(name: 'avoid_message') required final String avoidMessage,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt,
          @JsonKey(name: 'sync_updated_at') final DateTime? syncUpdatedAt,
          @JsonKey(name: 'target_minutes') required final int targetMinutes,
          @JsonKey(name: 'created_at') final DateTime? createdAt,
          @JsonKey(name: 'completed_at') final DateTime? completedAt}) =
      _$GoalsModelImpl;
  const _GoalsModel._() : super._();

  factory _GoalsModel.fromJson(Map<String, dynamic> json) =
      _$GoalsModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String? get userId;
  @override // nullable
  String get title;
  @override
  String? get description;
  @override // nullable
  DateTime get deadline;
  @override
  @JsonKey(name: 'avoid_message')
  String get avoidMessage;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'sync_updated_at')
  DateTime? get syncUpdatedAt;
  @override
  @JsonKey(name: 'target_minutes')
  int get targetMinutes;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt;
  @override
  @JsonKey(ignore: true)
  _$$GoalsModelImplCopyWith<_$GoalsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
