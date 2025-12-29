// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_study_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DailyStudyLogModelImpl _$$DailyStudyLogModelImplFromJson(
  Map<String, dynamic> json,
) => _$DailyStudyLogModelImpl(
  id: json['id'] as String,
  goalId: json['goalId'] as String,
  date: DateTime.parse(json['date'] as String),
  totalSeconds: json['totalSeconds'] as int,
  createdAt:
      json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  syncUpdatedAt:
      json['syncUpdatedAt'] == null
          ? null
          : DateTime.parse(json['syncUpdatedAt'] as String),
  isSynced: json['isSynced'] as bool? ?? false,
  isTemp: json['isTemp'] as bool? ?? false,
  tempUserId: json['tempUserId'] as String? ?? null,
);

Map<String, dynamic> _$$DailyStudyLogModelImplToJson(
  _$DailyStudyLogModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'goalId': instance.goalId,
  'date': instance.date.toIso8601String(),
  'totalSeconds': instance.totalSeconds,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'syncUpdatedAt': instance.syncUpdatedAt?.toIso8601String(),
  'isSynced': instance.isSynced,
  'isTemp': instance.isTemp,
  'tempUserId': instance.tempUserId,
};
