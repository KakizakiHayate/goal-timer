// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_study_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DailyStudyLogModelImpl _$$DailyStudyLogModelImplFromJson(
        Map<String, dynamic> json) =>
    _$DailyStudyLogModelImpl(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      date: DateTime.parse(json['date'] as String),
      minutes: json['minutes'] as int,
    );

Map<String, dynamic> _$$DailyStudyLogModelImplToJson(
        _$DailyStudyLogModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'goalId': instance.goalId,
      'date': instance.date.toIso8601String(),
      'minutes': instance.minutes,
    };
