import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_devices_model.freezed.dart';
part 'user_devices_model.g.dart';

@freezed
abstract class UserDevicesModel with _$UserDevicesModel {
  const UserDevicesModel._();

  const factory UserDevicesModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'fcm_token') required String fcmToken,
    required String platform,
    @JsonKey(name: 'device_name') String? deviceName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'last_active_at') DateTime? lastActiveAt,
  }) = _UserDevicesModel;

  factory UserDevicesModel.fromJson(Map<String, dynamic> json) =>
      _$UserDevicesModelFromJson(json);
}
