// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods',
);

/// @nodoc
mixin _$StudyStatistics {
  /// 今日の進捗率（0.0 - 1.0）
  double get todayProgress => throw _privateConstructorUsedError;

  /// 今日の学習時間（分）
  int get totalMinutes => throw _privateConstructorUsedError;

  /// 今日の目標時間（分）
  int get targetMinutes => throw _privateConstructorUsedError;

  /// 連続学習日数（ストリーク）
  int get currentStreak => throw _privateConstructorUsedError;

  /// 総目標数
  int get totalGoals => throw _privateConstructorUsedError;

  /// 完了済み目標数
  int get completedGoals => throw _privateConstructorUsedError;

  /// 今日の残り時間（分）
  int get remainingMinutes => throw _privateConstructorUsedError;

  /// データ更新日時
  DateTime? get lastUpdated => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $StudyStatisticsCopyWith<StudyStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudyStatisticsCopyWith<$Res> {
  factory $StudyStatisticsCopyWith(
    StudyStatistics value,
    $Res Function(StudyStatistics) then,
  ) = _$StudyStatisticsCopyWithImpl<$Res, StudyStatistics>;
  @useResult
  $Res call({
    double todayProgress,
    int totalMinutes,
    int targetMinutes,
    int currentStreak,
    int totalGoals,
    int completedGoals,
    int remainingMinutes,
    DateTime? lastUpdated,
  });
}

/// @nodoc
class _$StudyStatisticsCopyWithImpl<$Res, $Val extends StudyStatistics>
    implements $StudyStatisticsCopyWith<$Res> {
  _$StudyStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todayProgress = null,
    Object? totalMinutes = null,
    Object? targetMinutes = null,
    Object? currentStreak = null,
    Object? totalGoals = null,
    Object? completedGoals = null,
    Object? remainingMinutes = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(
      _value.copyWith(
            todayProgress:
                null == todayProgress
                    ? _value.todayProgress
                    : todayProgress // ignore: cast_nullable_to_non_nullable
                        as double,
            totalMinutes:
                null == totalMinutes
                    ? _value.totalMinutes
                    : totalMinutes // ignore: cast_nullable_to_non_nullable
                        as int,
            targetMinutes:
                null == targetMinutes
                    ? _value.targetMinutes
                    : targetMinutes // ignore: cast_nullable_to_non_nullable
                        as int,
            currentStreak:
                null == currentStreak
                    ? _value.currentStreak
                    : currentStreak // ignore: cast_nullable_to_non_nullable
                        as int,
            totalGoals:
                null == totalGoals
                    ? _value.totalGoals
                    : totalGoals // ignore: cast_nullable_to_non_nullable
                        as int,
            completedGoals:
                null == completedGoals
                    ? _value.completedGoals
                    : completedGoals // ignore: cast_nullable_to_non_nullable
                        as int,
            remainingMinutes:
                null == remainingMinutes
                    ? _value.remainingMinutes
                    : remainingMinutes // ignore: cast_nullable_to_non_nullable
                        as int,
            lastUpdated:
                freezed == lastUpdated
                    ? _value.lastUpdated
                    : lastUpdated // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StudyStatisticsImplCopyWith<$Res>
    implements $StudyStatisticsCopyWith<$Res> {
  factory _$$StudyStatisticsImplCopyWith(
    _$StudyStatisticsImpl value,
    $Res Function(_$StudyStatisticsImpl) then,
  ) = __$$StudyStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double todayProgress,
    int totalMinutes,
    int targetMinutes,
    int currentStreak,
    int totalGoals,
    int completedGoals,
    int remainingMinutes,
    DateTime? lastUpdated,
  });
}

/// @nodoc
class __$$StudyStatisticsImplCopyWithImpl<$Res>
    extends _$StudyStatisticsCopyWithImpl<$Res, _$StudyStatisticsImpl>
    implements _$$StudyStatisticsImplCopyWith<$Res> {
  __$$StudyStatisticsImplCopyWithImpl(
    _$StudyStatisticsImpl _value,
    $Res Function(_$StudyStatisticsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? todayProgress = null,
    Object? totalMinutes = null,
    Object? targetMinutes = null,
    Object? currentStreak = null,
    Object? totalGoals = null,
    Object? completedGoals = null,
    Object? remainingMinutes = null,
    Object? lastUpdated = freezed,
  }) {
    return _then(
      _$StudyStatisticsImpl(
        todayProgress:
            null == todayProgress
                ? _value.todayProgress
                : todayProgress // ignore: cast_nullable_to_non_nullable
                    as double,
        totalMinutes:
            null == totalMinutes
                ? _value.totalMinutes
                : totalMinutes // ignore: cast_nullable_to_non_nullable
                    as int,
        targetMinutes:
            null == targetMinutes
                ? _value.targetMinutes
                : targetMinutes // ignore: cast_nullable_to_non_nullable
                    as int,
        currentStreak:
            null == currentStreak
                ? _value.currentStreak
                : currentStreak // ignore: cast_nullable_to_non_nullable
                    as int,
        totalGoals:
            null == totalGoals
                ? _value.totalGoals
                : totalGoals // ignore: cast_nullable_to_non_nullable
                    as int,
        completedGoals:
            null == completedGoals
                ? _value.completedGoals
                : completedGoals // ignore: cast_nullable_to_non_nullable
                    as int,
        remainingMinutes:
            null == remainingMinutes
                ? _value.remainingMinutes
                : remainingMinutes // ignore: cast_nullable_to_non_nullable
                    as int,
        lastUpdated:
            freezed == lastUpdated
                ? _value.lastUpdated
                : lastUpdated // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$StudyStatisticsImpl implements _StudyStatistics {
  const _$StudyStatisticsImpl({
    this.todayProgress = 0.0,
    this.totalMinutes = 0,
    this.targetMinutes = 0,
    this.currentStreak = 0,
    this.totalGoals = 0,
    this.completedGoals = 0,
    this.remainingMinutes = 0,
    this.lastUpdated,
  });

  /// 今日の進捗率（0.0 - 1.0）
  @override
  @JsonKey()
  final double todayProgress;

  /// 今日の学習時間（分）
  @override
  @JsonKey()
  final int totalMinutes;

  /// 今日の目標時間（分）
  @override
  @JsonKey()
  final int targetMinutes;

  /// 連続学習日数（ストリーク）
  @override
  @JsonKey()
  final int currentStreak;

  /// 総目標数
  @override
  @JsonKey()
  final int totalGoals;

  /// 完了済み目標数
  @override
  @JsonKey()
  final int completedGoals;

  /// 今日の残り時間（分）
  @override
  @JsonKey()
  final int remainingMinutes;

  /// データ更新日時
  @override
  final DateTime? lastUpdated;

  @override
  String toString() {
    return 'StudyStatistics(todayProgress: $todayProgress, totalMinutes: $totalMinutes, targetMinutes: $targetMinutes, currentStreak: $currentStreak, totalGoals: $totalGoals, completedGoals: $completedGoals, remainingMinutes: $remainingMinutes, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudyStatisticsImpl &&
            (identical(other.todayProgress, todayProgress) ||
                other.todayProgress == todayProgress) &&
            (identical(other.totalMinutes, totalMinutes) ||
                other.totalMinutes == totalMinutes) &&
            (identical(other.targetMinutes, targetMinutes) ||
                other.targetMinutes == targetMinutes) &&
            (identical(other.currentStreak, currentStreak) ||
                other.currentStreak == currentStreak) &&
            (identical(other.totalGoals, totalGoals) ||
                other.totalGoals == totalGoals) &&
            (identical(other.completedGoals, completedGoals) ||
                other.completedGoals == completedGoals) &&
            (identical(other.remainingMinutes, remainingMinutes) ||
                other.remainingMinutes == remainingMinutes) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    todayProgress,
    totalMinutes,
    targetMinutes,
    currentStreak,
    totalGoals,
    completedGoals,
    remainingMinutes,
    lastUpdated,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StudyStatisticsImplCopyWith<_$StudyStatisticsImpl> get copyWith =>
      __$$StudyStatisticsImplCopyWithImpl<_$StudyStatisticsImpl>(
        this,
        _$identity,
      );
}

abstract class _StudyStatistics implements StudyStatistics {
  const factory _StudyStatistics({
    final double todayProgress,
    final int totalMinutes,
    final int targetMinutes,
    final int currentStreak,
    final int totalGoals,
    final int completedGoals,
    final int remainingMinutes,
    final DateTime? lastUpdated,
  }) = _$StudyStatisticsImpl;

  @override
  /// 今日の進捗率（0.0 - 1.0）
  double get todayProgress;
  @override
  /// 今日の学習時間（分）
  int get totalMinutes;
  @override
  /// 今日の目標時間（分）
  int get targetMinutes;
  @override
  /// 連続学習日数（ストリーク）
  int get currentStreak;
  @override
  /// 総目標数
  int get totalGoals;
  @override
  /// 完了済み目標数
  int get completedGoals;
  @override
  /// 今日の残り時間（分）
  int get remainingMinutes;
  @override
  /// データ更新日時
  DateTime? get lastUpdated;
  @override
  @JsonKey(ignore: true)
  _$$StudyStatisticsImplCopyWith<_$StudyStatisticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
