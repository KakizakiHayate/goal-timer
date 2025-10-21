// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal_form_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$GoalFormData {
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get avoidMessage => throw _privateConstructorUsedError;
  int get targetMinutes => throw _privateConstructorUsedError;
  DateTime get deadline => throw _privateConstructorUsedError;
  bool get isValid => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GoalFormDataCopyWith<GoalFormData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalFormDataCopyWith<$Res> {
  factory $GoalFormDataCopyWith(
          GoalFormData value, $Res Function(GoalFormData) then) =
      _$GoalFormDataCopyWithImpl<$Res, GoalFormData>;
  @useResult
  $Res call(
      {String title,
      String description,
      String avoidMessage,
      int targetMinutes,
      DateTime deadline,
      bool isValid});
}

/// @nodoc
class _$GoalFormDataCopyWithImpl<$Res, $Val extends GoalFormData>
    implements $GoalFormDataCopyWith<$Res> {
  _$GoalFormDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? avoidMessage = null,
    Object? targetMinutes = null,
    Object? deadline = null,
    Object? isValid = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      avoidMessage: null == avoidMessage
          ? _value.avoidMessage
          : avoidMessage // ignore: cast_nullable_to_non_nullable
              as String,
      targetMinutes: null == targetMinutes
          ? _value.targetMinutes
          : targetMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      deadline: null == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoalFormDataImplCopyWith<$Res>
    implements $GoalFormDataCopyWith<$Res> {
  factory _$$GoalFormDataImplCopyWith(
          _$GoalFormDataImpl value, $Res Function(_$GoalFormDataImpl) then) =
      __$$GoalFormDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String title,
      String description,
      String avoidMessage,
      int targetMinutes,
      DateTime deadline,
      bool isValid});
}

/// @nodoc
class __$$GoalFormDataImplCopyWithImpl<$Res>
    extends _$GoalFormDataCopyWithImpl<$Res, _$GoalFormDataImpl>
    implements _$$GoalFormDataImplCopyWith<$Res> {
  __$$GoalFormDataImplCopyWithImpl(
      _$GoalFormDataImpl _value, $Res Function(_$GoalFormDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? description = null,
    Object? avoidMessage = null,
    Object? targetMinutes = null,
    Object? deadline = null,
    Object? isValid = null,
  }) {
    return _then(_$GoalFormDataImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      avoidMessage: null == avoidMessage
          ? _value.avoidMessage
          : avoidMessage // ignore: cast_nullable_to_non_nullable
              as String,
      targetMinutes: null == targetMinutes
          ? _value.targetMinutes
          : targetMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      deadline: null == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isValid: null == isValid
          ? _value.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$GoalFormDataImpl implements _GoalFormData {
  const _$GoalFormDataImpl(
      {required this.title,
      required this.description,
      required this.avoidMessage,
      required this.targetMinutes,
      required this.deadline,
      required this.isValid});

  @override
  final String title;
  @override
  final String description;
  @override
  final String avoidMessage;
  @override
  final int targetMinutes;
  @override
  final DateTime deadline;
  @override
  final bool isValid;

  @override
  String toString() {
    return 'GoalFormData(title: $title, description: $description, avoidMessage: $avoidMessage, targetMinutes: $targetMinutes, deadline: $deadline, isValid: $isValid)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalFormDataImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.avoidMessage, avoidMessage) ||
                other.avoidMessage == avoidMessage) &&
            (identical(other.targetMinutes, targetMinutes) ||
                other.targetMinutes == targetMinutes) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.isValid, isValid) || other.isValid == isValid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, title, description, avoidMessage,
      targetMinutes, deadline, isValid);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalFormDataImplCopyWith<_$GoalFormDataImpl> get copyWith =>
      __$$GoalFormDataImplCopyWithImpl<_$GoalFormDataImpl>(this, _$identity);
}

abstract class _GoalFormData implements GoalFormData {
  const factory _GoalFormData(
      {required final String title,
      required final String description,
      required final String avoidMessage,
      required final int targetMinutes,
      required final DateTime deadline,
      required final bool isValid}) = _$GoalFormDataImpl;

  @override
  String get title;
  @override
  String get description;
  @override
  String get avoidMessage;
  @override
  int get targetMinutes;
  @override
  DateTime get deadline;
  @override
  bool get isValid;
  @override
  @JsonKey(ignore: true)
  _$$GoalFormDataImplCopyWith<_$GoalFormDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
