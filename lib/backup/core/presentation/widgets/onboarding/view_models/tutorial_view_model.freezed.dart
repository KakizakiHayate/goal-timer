// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tutorial_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$TutorialState {
  bool get isTutorialActive => throw _privateConstructorUsedError;
  String get currentStepId => throw _privateConstructorUsedError;
  int get currentStepIndex => throw _privateConstructorUsedError;
  int get totalSteps => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  String? get tempUserId => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TutorialStateCopyWith<TutorialState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TutorialStateCopyWith<$Res> {
  factory $TutorialStateCopyWith(
          TutorialState value, $Res Function(TutorialState) then) =
      _$TutorialStateCopyWithImpl<$Res, TutorialState>;
  @useResult
  $Res call(
      {bool isTutorialActive,
      String currentStepId,
      int currentStepIndex,
      int totalSteps,
      bool isCompleted,
      String? tempUserId});
}

/// @nodoc
class _$TutorialStateCopyWithImpl<$Res, $Val extends TutorialState>
    implements $TutorialStateCopyWith<$Res> {
  _$TutorialStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isTutorialActive = null,
    Object? currentStepId = null,
    Object? currentStepIndex = null,
    Object? totalSteps = null,
    Object? isCompleted = null,
    Object? tempUserId = freezed,
  }) {
    return _then(_value.copyWith(
      isTutorialActive: null == isTutorialActive
          ? _value.isTutorialActive
          : isTutorialActive // ignore: cast_nullable_to_non_nullable
              as bool,
      currentStepId: null == currentStepId
          ? _value.currentStepId
          : currentStepId // ignore: cast_nullable_to_non_nullable
              as String,
      currentStepIndex: null == currentStepIndex
          ? _value.currentStepIndex
          : currentStepIndex // ignore: cast_nullable_to_non_nullable
              as int,
      totalSteps: null == totalSteps
          ? _value.totalSteps
          : totalSteps // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      tempUserId: freezed == tempUserId
          ? _value.tempUserId
          : tempUserId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TutorialStateImplCopyWith<$Res>
    implements $TutorialStateCopyWith<$Res> {
  factory _$$TutorialStateImplCopyWith(
          _$TutorialStateImpl value, $Res Function(_$TutorialStateImpl) then) =
      __$$TutorialStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isTutorialActive,
      String currentStepId,
      int currentStepIndex,
      int totalSteps,
      bool isCompleted,
      String? tempUserId});
}

/// @nodoc
class __$$TutorialStateImplCopyWithImpl<$Res>
    extends _$TutorialStateCopyWithImpl<$Res, _$TutorialStateImpl>
    implements _$$TutorialStateImplCopyWith<$Res> {
  __$$TutorialStateImplCopyWithImpl(
      _$TutorialStateImpl _value, $Res Function(_$TutorialStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isTutorialActive = null,
    Object? currentStepId = null,
    Object? currentStepIndex = null,
    Object? totalSteps = null,
    Object? isCompleted = null,
    Object? tempUserId = freezed,
  }) {
    return _then(_$TutorialStateImpl(
      isTutorialActive: null == isTutorialActive
          ? _value.isTutorialActive
          : isTutorialActive // ignore: cast_nullable_to_non_nullable
              as bool,
      currentStepId: null == currentStepId
          ? _value.currentStepId
          : currentStepId // ignore: cast_nullable_to_non_nullable
              as String,
      currentStepIndex: null == currentStepIndex
          ? _value.currentStepIndex
          : currentStepIndex // ignore: cast_nullable_to_non_nullable
              as int,
      totalSteps: null == totalSteps
          ? _value.totalSteps
          : totalSteps // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      tempUserId: freezed == tempUserId
          ? _value.tempUserId
          : tempUserId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$TutorialStateImpl implements _TutorialState {
  const _$TutorialStateImpl(
      {this.isTutorialActive = false,
      this.currentStepId = '',
      this.currentStepIndex = 0,
      this.totalSteps = 0,
      this.isCompleted = false,
      this.tempUserId});

  @override
  @JsonKey()
  final bool isTutorialActive;
  @override
  @JsonKey()
  final String currentStepId;
  @override
  @JsonKey()
  final int currentStepIndex;
  @override
  @JsonKey()
  final int totalSteps;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final String? tempUserId;

  @override
  String toString() {
    return 'TutorialState(isTutorialActive: $isTutorialActive, currentStepId: $currentStepId, currentStepIndex: $currentStepIndex, totalSteps: $totalSteps, isCompleted: $isCompleted, tempUserId: $tempUserId)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TutorialStateImpl &&
            (identical(other.isTutorialActive, isTutorialActive) ||
                other.isTutorialActive == isTutorialActive) &&
            (identical(other.currentStepId, currentStepId) ||
                other.currentStepId == currentStepId) &&
            (identical(other.currentStepIndex, currentStepIndex) ||
                other.currentStepIndex == currentStepIndex) &&
            (identical(other.totalSteps, totalSteps) ||
                other.totalSteps == totalSteps) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.tempUserId, tempUserId) ||
                other.tempUserId == tempUserId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isTutorialActive, currentStepId,
      currentStepIndex, totalSteps, isCompleted, tempUserId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TutorialStateImplCopyWith<_$TutorialStateImpl> get copyWith =>
      __$$TutorialStateImplCopyWithImpl<_$TutorialStateImpl>(this, _$identity);
}

abstract class _TutorialState implements TutorialState {
  const factory _TutorialState(
      {final bool isTutorialActive,
      final String currentStepId,
      final int currentStepIndex,
      final int totalSteps,
      final bool isCompleted,
      final String? tempUserId}) = _$TutorialStateImpl;

  @override
  bool get isTutorialActive;
  @override
  String get currentStepId;
  @override
  int get currentStepIndex;
  @override
  int get totalSteps;
  @override
  bool get isCompleted;
  @override
  String? get tempUserId;
  @override
  @JsonKey(ignore: true)
  _$$TutorialStateImplCopyWith<_$TutorialStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
