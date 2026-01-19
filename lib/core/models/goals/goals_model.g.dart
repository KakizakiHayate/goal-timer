// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GoalsModelImpl _$$GoalsModelImplFromJson(Map<String, dynamic> json) =>
    _$GoalsModelImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: DateTime.parse(json['deadline'] as String),
      avoidMessage: json['avoid_message'] as String,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      syncUpdatedAt: json['sync_updated_at'] == null
          ? null
          : DateTime.parse(json['sync_updated_at'] as String),
      targetMinutes: json['target_minutes'] as int,
      totalTargetMinutes: json['total_target_minutes'] as int?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      expiredAt: json['expired_at'] == null
          ? null
          : DateTime.parse(json['expired_at'] as String),
    );

Map<String, dynamic> _$$GoalsModelImplToJson(_$GoalsModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'deadline': instance.deadline.toIso8601String(),
      'avoid_message': instance.avoidMessage,
      'updated_at': instance.updatedAt?.toIso8601String(),
      'sync_updated_at': instance.syncUpdatedAt?.toIso8601String(),
      'target_minutes': instance.targetMinutes,
      'total_target_minutes': instance.totalTargetMinutes,
      'created_at': instance.createdAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'expired_at': instance.expiredAt?.toIso8601String(),
    };
