// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_daily_logs_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudyDailyLogsModelImpl _$$StudyDailyLogsModelImplFromJson(
  Map<String, dynamic> json,
) => _$StudyDailyLogsModelImpl(
  id: json['id'] as String,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  goalId: json['goal_id'] as String,
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  studyDate: DateTime.parse(json['study_date'] as String),
  syncUpdatedAt:
      json['sync_updated_at'] == null
          ? null
          : DateTime.parse(json['sync_updated_at'] as String),
  totalSeconds: json['total_seconds'] as int,
  userId: json['user_id'] as String?,
);

Map<String, dynamic> _$$StudyDailyLogsModelImplToJson(
  _$StudyDailyLogsModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'created_at': instance.createdAt?.toIso8601String(),
  'goal_id': instance.goalId,
  'updated_at': instance.updatedAt?.toIso8601String(),
  'study_date': instance.studyDate.toIso8601String(),
  'sync_updated_at': instance.syncUpdatedAt?.toIso8601String(),
  'total_seconds': instance.totalSeconds,
  'user_id': instance.userId,
};
