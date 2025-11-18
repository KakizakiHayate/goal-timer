import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:goal_timer/core/utils/time_utils.dart';

part 'study_daily_logs_model.freezed.dart';
part 'study_daily_logs_model.g.dart';

@freezed
class StudyDailyLogsModel with _$StudyDailyLogsModel {
  const StudyDailyLogsModel._();

  const factory StudyDailyLogsModel({
    required String id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'goal_id') required String goalId,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'study_date') required DateTime studyDate,
    @JsonKey(name: 'sync_updated_at') DateTime? syncUpdatedAt,
    @JsonKey(name: 'total_seconds') required int totalSeconds,
    @JsonKey(name: 'user_id') String? userId,
  }) = _StudyDailyLogsModel;

  factory StudyDailyLogsModel.fromJson(Map<String, dynamic> json) =>
      _$StudyDailyLogsModelFromJson(json);
}
