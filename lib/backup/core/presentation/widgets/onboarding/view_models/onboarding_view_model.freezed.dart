// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$OnboardingState {
  int get currentStep => throw _privateConstructorUsedError;
  double get progress => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String get tempUserId => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  bool get isDataMigrationInProgress => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $OnboardingStateCopyWith<OnboardingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OnboardingStateCopyWith<$Res> {
  factory $OnboardingStateCopyWith(
          OnboardingState value, $Res Function(OnboardingState) then) =
      _$OnboardingStateCopyWithImpl<$Res, OnboardingState>;
  @useResult
  $Res call(
      {int currentStep,
      double progress,
      bool isLoading,
      String tempUserId,
      String? errorMessage,
      bool isDataMigrationInProgress});
}

/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res, $Val extends OnboardingState>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? progress = null,
    Object? isLoading = null,
    Object? tempUserId = null,
    Object? errorMessage = freezed,
    Object? isDataMigrationInProgress = null,
  }) {
    return _then(_value.copyWith(
      currentStep: null == currentStep
          ? _value.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as int,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      tempUserId: null == tempUserId
          ? _value.tempUserId
          : tempUserId // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isDataMigrationInProgress: null == isDataMigrationInProgress
          ? _value.isDataMigrationInProgress
          : isDataMigrationInProgress // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OnboardingStateImplCopyWith<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  factory _$$OnboardingStateImplCopyWith(_$OnboardingStateImpl value,
          $Res Function(_$OnboardingStateImpl) then) =
      __$$OnboardingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int currentStep,
      double progress,
      bool isLoading,
      String tempUserId,
      String? errorMessage,
      bool isDataMigrationInProgress});
}

/// @nodoc
class __$$OnboardingStateImplCopyWithImpl<$Res>
    extends _$OnboardingStateCopyWithImpl<$Res, _$OnboardingStateImpl>
    implements _$$OnboardingStateImplCopyWith<$Res> {
  __$$OnboardingStateImplCopyWithImpl(
      _$OnboardingStateImpl _value, $Res Function(_$OnboardingStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? progress = null,
    Object? isLoading = null,
    Object? tempUserId = null,
    Object? errorMessage = freezed,
    Object? isDataMigrationInProgress = null,
  }) {
    return _then(_$OnboardingStateImpl(
      currentStep: null == currentStep
          ? _value.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as int,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      tempUserId: null == tempUserId
          ? _value.tempUserId
          : tempUserId // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      isDataMigrationInProgress: null == isDataMigrationInProgress
          ? _value.isDataMigrationInProgress
          : isDataMigrationInProgress // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$OnboardingStateImpl implements _OnboardingState {
  const _$OnboardingStateImpl(
      {this.currentStep = 0,
      this.progress = 0.0,
      this.isLoading = false,
      this.tempUserId = '',
      this.errorMessage,
      this.isDataMigrationInProgress = false});

  @override
  @JsonKey()
  final int currentStep;
  @override
  @JsonKey()
  final double progress;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final String tempUserId;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final bool isDataMigrationInProgress;

  @override
  String toString() {
    return 'OnboardingState(currentStep: $currentStep, progress: $progress, isLoading: $isLoading, tempUserId: $tempUserId, errorMessage: $errorMessage, isDataMigrationInProgress: $isDataMigrationInProgress)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnboardingStateImpl &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.tempUserId, tempUserId) ||
                other.tempUserId == tempUserId) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.isDataMigrationInProgress,
                    isDataMigrationInProgress) ||
                other.isDataMigrationInProgress == isDataMigrationInProgress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentStep, progress, isLoading,
      tempUserId, errorMessage, isDataMigrationInProgress);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OnboardingStateImplCopyWith<_$OnboardingStateImpl> get copyWith =>
      __$$OnboardingStateImplCopyWithImpl<_$OnboardingStateImpl>(
          this, _$identity);
}

abstract class _OnboardingState implements OnboardingState {
  const factory _OnboardingState(
      {final int currentStep,
      final double progress,
      final bool isLoading,
      final String tempUserId,
      final String? errorMessage,
      final bool isDataMigrationInProgress}) = _$OnboardingStateImpl;

  @override
  int get currentStep;
  @override
  double get progress;
  @override
  bool get isLoading;
  @override
  String get tempUserId;
  @override
  String? get errorMessage;
  @override
  bool get isDataMigrationInProgress;
  @override
  @JsonKey(ignore: true)
  _$$OnboardingStateImplCopyWith<_$OnboardingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
