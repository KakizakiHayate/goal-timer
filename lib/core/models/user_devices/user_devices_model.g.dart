// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_devices_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDevicesModel _$UserDevicesModelFromJson(Map<String, dynamic> json) =>
    _UserDevicesModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fcmToken: json['fcm_token'] as String,
      platform: json['platform'] as String,
      deviceName: json['device_name'] as String?,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
      lastActiveAt:
          json['last_active_at'] == null
              ? null
              : DateTime.parse(json['last_active_at'] as String),
    );

Map<String, dynamic> _$UserDevicesModelToJson(_UserDevicesModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'fcm_token': instance.fcmToken,
      'platform': instance.platform,
      'device_name': instance.deviceName,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'last_active_at': instance.lastActiveAt?.toIso8601String(),
    };
