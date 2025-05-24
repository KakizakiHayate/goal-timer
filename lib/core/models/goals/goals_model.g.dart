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
      progressPercent: (json['progressPercent'] as num).toDouble(),
      totalTargetHours: json['totalTargetHours'] as int,
      spentMinutes: json['spentMinutes'] as int,
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
      'progressPercent': instance.progressPercent,
      'totalTargetHours': instance.totalTargetHours,
      'spentMinutes': instance.spentMinutes,
    };
