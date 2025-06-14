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
  /// 各目標のid管理
  String get id => throw _privateConstructorUsedError;

  /// users tableのidとリレーション
  String get userId => throw _privateConstructorUsedError;

  /// 目標名
  String get title => throw _privateConstructorUsedError;

  /// 目標の詳細説明
  String get description => throw _privateConstructorUsedError;

  /// いつまで(日付)に達成するのか？
  DateTime get deadline => throw _privateConstructorUsedError;

  /// 目標を完了したかの判定フラグ
  bool get isCompleted => throw _privateConstructorUsedError;

  /// 目標達成しなかったら自分に課すこと
  String get avoidMessage => throw _privateConstructorUsedError;

  /// 目標達成に必要な総時間（時間単位）
  int get totalTargetHours => throw _privateConstructorUsedError;

  /// 実際に使った時間（分単位）
  int get spentMinutes => throw _privateConstructorUsedError;

  /// 最終更新日時
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// 同期状態（ローカルDBのみで使用）
  bool get isSynced => throw _privateConstructorUsedError;

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
      String userId,
      String title,
      String description,
      DateTime deadline,
      bool isCompleted,
      String avoidMessage,
      int totalTargetHours,
      int spentMinutes,
      DateTime? updatedAt,
      bool isSynced});
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
    Object? userId = null,
    Object? title = null,
    Object? description = null,
    Object? deadline = null,
    Object? isCompleted = null,
    Object? avoidMessage = null,
    Object? totalTargetHours = null,
    Object? spentMinutes = null,
    Object? updatedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      deadline: null == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      avoidMessage: null == avoidMessage
          ? _value.avoidMessage
          : avoidMessage // ignore: cast_nullable_to_non_nullable
              as String,
      totalTargetHours: null == totalTargetHours
          ? _value.totalTargetHours
          : totalTargetHours // ignore: cast_nullable_to_non_nullable
              as int,
      spentMinutes: null == spentMinutes
          ? _value.spentMinutes
          : spentMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isSynced: null == isSynced
          ? _value.isSynced
          : isSynced // ignore: cast_nullable_to_non_nullable
              as bool,
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
      String userId,
      String title,
      String description,
      DateTime deadline,
      bool isCompleted,
      String avoidMessage,
      int totalTargetHours,
      int spentMinutes,
      DateTime? updatedAt,
      bool isSynced});
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
    Object? userId = null,
    Object? title = null,
    Object? description = null,
    Object? deadline = null,
    Object? isCompleted = null,
    Object? avoidMessage = null,
    Object? totalTargetHours = null,
    Object? spentMinutes = null,
    Object? updatedAt = freezed,
    Object? isSynced = null,
  }) {
    return _then(_$GoalsModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      deadline: null == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      avoidMessage: null == avoidMessage
          ? _value.avoidMessage
          : avoidMessage // ignore: cast_nullable_to_non_nullable
              as String,
      totalTargetHours: null == totalTargetHours
          ? _value.totalTargetHours
          : totalTargetHours // ignore: cast_nullable_to_non_nullable
              as int,
      spentMinutes: null == spentMinutes
          ? _value.spentMinutes
          : spentMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
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
class _$GoalsModelImpl implements _GoalsModel {
  const _$GoalsModelImpl(
      {required this.id,
      required this.userId,
      required this.title,
      required this.description,
      required this.deadline,
      required this.isCompleted,
      required this.avoidMessage,
      required this.totalTargetHours,
      required this.spentMinutes,
      this.updatedAt = null,
      this.isSynced = false});

  factory _$GoalsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalsModelImplFromJson(json);

  /// 各目標のid管理
  @override
  final String id;

  /// users tableのidとリレーション
  @override
  final String userId;

  /// 目標名
  @override
  final String title;

  /// 目標の詳細説明
  @override
  final String description;

  /// いつまで(日付)に達成するのか？
  @override
  final DateTime deadline;

  /// 目標を完了したかの判定フラグ
  @override
  final bool isCompleted;

  /// 目標達成しなかったら自分に課すこと
  @override
  final String avoidMessage;

  /// 目標達成に必要な総時間（時間単位）
  @override
  final int totalTargetHours;

  /// 実際に使った時間（分単位）
  @override
  final int spentMinutes;

  /// 最終更新日時
  @override
  @JsonKey()
  final DateTime? updatedAt;

  /// 同期状態（ローカルDBのみで使用）
  @override
  @JsonKey()
  final bool isSynced;

  @override
  String toString() {
    return 'GoalsModel(id: $id, userId: $userId, title: $title, description: $description, deadline: $deadline, isCompleted: $isCompleted, avoidMessage: $avoidMessage, totalTargetHours: $totalTargetHours, spentMinutes: $spentMinutes, updatedAt: $updatedAt, isSynced: $isSynced)';
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
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.avoidMessage, avoidMessage) ||
                other.avoidMessage == avoidMessage) &&
            (identical(other.totalTargetHours, totalTargetHours) ||
                other.totalTargetHours == totalTargetHours) &&
            (identical(other.spentMinutes, spentMinutes) ||
                other.spentMinutes == spentMinutes) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
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
      isCompleted,
      avoidMessage,
      totalTargetHours,
      spentMinutes,
      updatedAt,
      isSynced);

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

abstract class _GoalsModel implements GoalsModel {
  const factory _GoalsModel(
      {required final String id,
      required final String userId,
      required final String title,
      required final String description,
      required final DateTime deadline,
      required final bool isCompleted,
      required final String avoidMessage,
      required final int totalTargetHours,
      required final int spentMinutes,
      final DateTime? updatedAt,
      final bool isSynced}) = _$GoalsModelImpl;

  factory _GoalsModel.fromJson(Map<String, dynamic> json) =
      _$GoalsModelImpl.fromJson;

  @override

  /// 各目標のid管理
  String get id;
  @override

  /// users tableのidとリレーション
  String get userId;
  @override

  /// 目標名
  String get title;
  @override

  /// 目標の詳細説明
  String get description;
  @override

  /// いつまで(日付)に達成するのか？
  DateTime get deadline;
  @override

  /// 目標を完了したかの判定フラグ
  bool get isCompleted;
  @override

  /// 目標達成しなかったら自分に課すこと
  String get avoidMessage;
  @override

  /// 目標達成に必要な総時間（時間単位）
  int get totalTargetHours;
  @override

  /// 実際に使った時間（分単位）
  int get spentMinutes;
  @override

  /// 最終更新日時
  DateTime? get updatedAt;
  @override

  /// 同期状態（ローカルDBのみで使用）
  bool get isSynced;
  @override
  @JsonKey(ignore: true)
  _$$GoalsModelImplCopyWith<_$GoalsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
