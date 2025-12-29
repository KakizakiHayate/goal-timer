// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GoalsModelImpl _$$GoalsModelImplFromJson(Map<String, dynamic> json) =>
    _$GoalsModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      isCompleted: json['isCompleted'] as bool,
      avoidMessage: json['avoidMessage'] as String,
      targetMinutes: json['targetMinutes'] as int,
      spentMinutes: json['spentMinutes'] as int,
      updatedAt:
          json['updatedAt'] == null
              ? null
              : DateTime.parse(json['updatedAt'] as String),
      syncUpdatedAt:
          json['syncUpdatedAt'] == null
              ? null
              : DateTime.parse(json['syncUpdatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$GoalsModelImplToJson(_$GoalsModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'deadline': instance.deadline.toIso8601String(),
      'isCompleted': instance.isCompleted,
      'avoidMessage': instance.avoidMessage,
      'targetMinutes': instance.targetMinutes,
      'spentMinutes': instance.spentMinutes,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'syncUpdatedAt': instance.syncUpdatedAt?.toIso8601String(),
      'isSynced': instance.isSynced,
    };
