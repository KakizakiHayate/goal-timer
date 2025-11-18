// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_daily_logs_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

StudyDailyLogsModel _$StudyDailyLogsModelFromJson(Map<String, dynamic> json) {
  return _StudyDailyLogsModel.fromJson(json);
}

/// @nodoc
mixin _$StudyDailyLogsModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'goal_id')
  String get goalId => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'study_date')
  DateTime get studyDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'sync_updated_at')
  DateTime? get syncUpdatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_seconds')
  int get totalSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StudyDailyLogsModelCopyWith<StudyDailyLogsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudyDailyLogsModelCopyWith<$Res> {
  factory $StudyDailyLogsModelCopyWith(
          StudyDailyLogsModel value, $Res Function(StudyDailyLogsModel) then) =
      _$StudyDailyLogsModelCopyWithImpl<$Res, StudyDailyLogsModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'goal_id') String goalId,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'study_date') DateTime studyDate,
      @JsonKey(name: 'sync_updated_at') DateTime? syncUpdatedAt,
      @JsonKey(name: 'total_seconds') int totalSeconds,
      @JsonKey(name: 'user_id') String? userId});
}

/// @nodoc
class _$StudyDailyLogsModelCopyWithImpl<$Res, $Val extends StudyDailyLogsModel>
    implements $StudyDailyLogsModelCopyWith<$Res> {
  _$StudyDailyLogsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = freezed,
    Object? goalId = null,
    Object? updatedAt = freezed,
    Object? studyDate = null,
    Object? syncUpdatedAt = freezed,
    Object? totalSeconds = null,
    Object? userId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      goalId: null == goalId
          ? _value.goalId
          : goalId // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      studyDate: null == studyDate
          ? _value.studyDate
          : studyDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      syncUpdatedAt: freezed == syncUpdatedAt
          ? _value.syncUpdatedAt
          : syncUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalSeconds: null == totalSeconds
          ? _value.totalSeconds
          : totalSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StudyDailyLogsModelImplCopyWith<$Res>
    implements $StudyDailyLogsModelCopyWith<$Res> {
  factory _$$StudyDailyLogsModelImplCopyWith(_$StudyDailyLogsModelImpl value,
          $Res Function(_$StudyDailyLogsModelImpl) then) =
      __$$StudyDailyLogsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'goal_id') String goalId,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'study_date') DateTime studyDate,
      @JsonKey(name: 'sync_updated_at') DateTime? syncUpdatedAt,
      @JsonKey(name: 'total_seconds') int totalSeconds,
      @JsonKey(name: 'user_id') String? userId});
}

/// @nodoc
class __$$StudyDailyLogsModelImplCopyWithImpl<$Res>
    extends _$StudyDailyLogsModelCopyWithImpl<$Res, _$StudyDailyLogsModelImpl>
    implements _$$StudyDailyLogsModelImplCopyWith<$Res> {
  __$$StudyDailyLogsModelImplCopyWithImpl(_$StudyDailyLogsModelImpl _value,
      $Res Function(_$StudyDailyLogsModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = freezed,
    Object? goalId = null,
    Object? updatedAt = freezed,
    Object? studyDate = null,
    Object? syncUpdatedAt = freezed,
    Object? totalSeconds = null,
    Object? userId = freezed,
  }) {
    return _then(_$StudyDailyLogsModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      goalId: null == goalId
          ? _value.goalId
          : goalId // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      studyDate: null == studyDate
          ? _value.studyDate
          : studyDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      syncUpdatedAt: freezed == syncUpdatedAt
          ? _value.syncUpdatedAt
          : syncUpdatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalSeconds: null == totalSeconds
          ? _value.totalSeconds
          : totalSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StudyDailyLogsModelImpl extends _StudyDailyLogsModel {
  const _$StudyDailyLogsModelImpl(
      {required this.id,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'goal_id') required this.goalId,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'study_date') required this.studyDate,
      @JsonKey(name: 'sync_updated_at') this.syncUpdatedAt,
      @JsonKey(name: 'total_seconds') required this.totalSeconds,
      @JsonKey(name: 'user_id') this.userId})
      : super._();

  factory _$StudyDailyLogsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudyDailyLogsModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'goal_id')
  final String goalId;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'study_date')
  final DateTime studyDate;
  @override
  @JsonKey(name: 'sync_updated_at')
  final DateTime? syncUpdatedAt;
  @override
  @JsonKey(name: 'total_seconds')
  final int totalSeconds;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;

  @override
  String toString() {
    return 'StudyDailyLogsModel(id: $id, createdAt: $createdAt, goalId: $goalId, updatedAt: $updatedAt, studyDate: $studyDate, syncUpdatedAt: $syncUpdatedAt, totalSeconds: $totalSeconds, userId: $userId)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudyDailyLogsModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.goalId, goalId) || other.goalId == goalId) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.studyDate, studyDate) ||
                other.studyDate == studyDate) &&
            (identical(other.syncUpdatedAt, syncUpdatedAt) ||
                other.syncUpdatedAt == syncUpdatedAt) &&
            (identical(other.totalSeconds, totalSeconds) ||
                other.totalSeconds == totalSeconds) &&
            (identical(other.userId, userId) || other.userId == userId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, createdAt, goalId, updatedAt,
      studyDate, syncUpdatedAt, totalSeconds, userId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudyDailyLogsModelImplCopyWith<_$StudyDailyLogsModelImpl> get copyWith =>
      __$$StudyDailyLogsModelImplCopyWithImpl<_$StudyDailyLogsModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudyDailyLogsModelImplToJson(
      this,
    );
  }
}

abstract class _StudyDailyLogsModel extends StudyDailyLogsModel {
  const factory _StudyDailyLogsModel(
          {required final String id,
          @JsonKey(name: 'created_at') final DateTime? createdAt,
          @JsonKey(name: 'goal_id') required final String goalId,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt,
          @JsonKey(name: 'study_date') required final DateTime studyDate,
          @JsonKey(name: 'sync_updated_at') final DateTime? syncUpdatedAt,
          @JsonKey(name: 'total_seconds') required final int totalSeconds,
          @JsonKey(name: 'user_id') final String? userId}) =
      _$StudyDailyLogsModelImpl;
  const _StudyDailyLogsModel._() : super._();

  factory _StudyDailyLogsModel.fromJson(Map<String, dynamic> json) =
      _$StudyDailyLogsModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'goal_id')
  String get goalId;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'study_date')
  DateTime get studyDate;
  @override
  @JsonKey(name: 'sync_updated_at')
  DateTime? get syncUpdatedAt;
  @override
  @JsonKey(name: 'total_seconds')
  int get totalSeconds;
  @override
  @JsonKey(name: 'user_id')
  String? get userId;
  @override
  @JsonKey(ignore: true)
  _$$StudyDailyLogsModelImplCopyWith<_$StudyDailyLogsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
