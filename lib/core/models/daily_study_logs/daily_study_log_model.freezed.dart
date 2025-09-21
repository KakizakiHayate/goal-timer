// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_study_log_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

DailyStudyLogModel _$DailyStudyLogModelFromJson(Map<String, dynamic> json) {
  return _DailyStudyLogModel.fromJson(json);
}

/// @nodoc
mixin _$DailyStudyLogModel {
  /// 自動生成される一意のID
  String get id => throw _privateConstructorUsedError;

  /// 関連する目標のID
  String get goalId => throw _privateConstructorUsedError;

  /// 学習した日付
  DateTime get date => throw _privateConstructorUsedError;

  /// 学習した時間（秒）
  int get totalSeconds => throw _privateConstructorUsedError;

  /// 最終更新日時
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// 同期時の最終更新日時（同期処理で使用）
  DateTime? get syncUpdatedAt => throw _privateConstructorUsedError;

  /// 同期状態（ローカルDBのみで使用）
  bool get isSynced => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DailyStudyLogModelCopyWith<DailyStudyLogModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyStudyLogModelCopyWith<$Res> {
  factory $DailyStudyLogModelCopyWith(
          DailyStudyLogModel value, $Res Function(DailyStudyLogModel) then) =
      _$DailyStudyLogModelCopyWithImpl<$Res, DailyStudyLogModel>;
  @useResult
  $Res call(
      {String id,
      String goalId,
      DateTime date,
      int totalSeconds,
      DateTime? updatedAt,
      DateTime? syncUpdatedAt,
      bool isSynced});
}

/// @nodoc
class _$DailyStudyLogModelCopyWithImpl<$Res, $Val extends DailyStudyLogModel>
    implements $DailyStudyLogModelCopyWith<$Res> {
  _$DailyStudyLogModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? goalId = null,
    Object? date = null,
    Object? totalSeconds = null,
    Object? updatedAt = freezed,
    Object? syncUpdatedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      goalId: null == goalId
          ? _value.goalId
          : goalId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalSeconds: null == totalSeconds
          ? _value.totalSeconds
          : totalSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$DailyStudyLogModelImplCopyWith<$Res>
    implements $DailyStudyLogModelCopyWith<$Res> {
  factory _$$DailyStudyLogModelImplCopyWith(_$DailyStudyLogModelImpl value,
          $Res Function(_$DailyStudyLogModelImpl) then) =
      __$$DailyStudyLogModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String goalId,
      DateTime date,
      int totalSeconds,
      DateTime? updatedAt,
      DateTime? syncUpdatedAt,
      bool isSynced});
}

/// @nodoc
class __$$DailyStudyLogModelImplCopyWithImpl<$Res>
    extends _$DailyStudyLogModelCopyWithImpl<$Res, _$DailyStudyLogModelImpl>
    implements _$$DailyStudyLogModelImplCopyWith<$Res> {
  __$$DailyStudyLogModelImplCopyWithImpl(_$DailyStudyLogModelImpl _value,
      $Res Function(_$DailyStudyLogModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? goalId = null,
    Object? date = null,
    Object? totalSeconds = null,
    Object? updatedAt = freezed,
    Object? syncUpdatedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_$DailyStudyLogModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      goalId: null == goalId
          ? _value.goalId
          : goalId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalSeconds: null == totalSeconds
          ? _value.totalSeconds
          : totalSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
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
class _$DailyStudyLogModelImpl implements _DailyStudyLogModel {
  const _$DailyStudyLogModelImpl(
      {required this.id,
      required this.goalId,
      required this.date,
      required this.totalSeconds,
      this.updatedAt = null,
      this.syncUpdatedAt = null,
      this.isSynced = false});

  factory _$DailyStudyLogModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyStudyLogModelImplFromJson(json);

  /// 自動生成される一意のID
  @override
  final String id;

  /// 関連する目標のID
  @override
  final String goalId;

  /// 学習した日付
  @override
  final DateTime date;

  /// 学習した時間（秒）
  @override
  final int totalSeconds;

  /// 最終更新日時
  @override
  @JsonKey()
  final DateTime? updatedAt;

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
    return 'DailyStudyLogModel(id: $id, goalId: $goalId, date: $date, totalSeconds: $totalSeconds, updatedAt: $updatedAt, syncUpdatedAt: $syncUpdatedAt, isSynced: $isSynced)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyStudyLogModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.goalId, goalId) || other.goalId == goalId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.totalSeconds, totalSeconds) ||
                other.totalSeconds == totalSeconds) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.syncUpdatedAt, syncUpdatedAt) ||
                other.syncUpdatedAt == syncUpdatedAt) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, goalId, date, totalSeconds,
      updatedAt, syncUpdatedAt, isSynced);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyStudyLogModelImplCopyWith<_$DailyStudyLogModelImpl> get copyWith =>
      __$$DailyStudyLogModelImplCopyWithImpl<_$DailyStudyLogModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyStudyLogModelImplToJson(
      this,
    );
  }
}

abstract class _DailyStudyLogModel implements DailyStudyLogModel {
  const factory _DailyStudyLogModel(
      {required final String id,
      required final String goalId,
      required final DateTime date,
      required final int totalSeconds,
      final DateTime? updatedAt,
      final DateTime? syncUpdatedAt,
      final bool isSynced}) = _$DailyStudyLogModelImpl;

  factory _DailyStudyLogModel.fromJson(Map<String, dynamic> json) =
      _$DailyStudyLogModelImpl.fromJson;

  @override

  /// 自動生成される一意のID
  String get id;
  @override

  /// 関連する目標のID
  String get goalId;
  @override

  /// 学習した日付
  DateTime get date;
  @override

  /// 学習した時間（秒）
  int get totalSeconds;
  @override

  /// 最終更新日時
  DateTime? get updatedAt;
  @override

  /// 同期時の最終更新日時（同期処理で使用）
  DateTime? get syncUpdatedAt;
  @override

  /// 同期状態（ローカルDBのみで使用）
  bool get isSynced;
  @override
  @JsonKey(ignore: true)
  _$$DailyStudyLogModelImplCopyWith<_$DailyStudyLogModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
