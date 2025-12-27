import 'package:freezed_annotation/freezed_annotation.dart';

part 'goals_model.freezed.dart';
part 'goals_model.g.dart';

@freezed
class GoalsModel with _$GoalsModel {
  const GoalsModel._();

  const factory GoalsModel({
    required String id,
    @JsonKey(name: 'user_id') String? userId,
    required String title,
    String? description, // nullable
    required DateTime deadline,
    @JsonKey(name: 'avoid_message') required String avoidMessage,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'sync_updated_at') DateTime? syncUpdatedAt,
    @JsonKey(name: 'target_minutes') required int targetMinutes,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _GoalsModel;

  /// Supabaseからのデータを元にGoalsModelを生成
  factory GoalsModel.fromJson(Map<String, dynamic> json) =>
      _$GoalsModelFromJson(json);

  bool get isGoalCompleted => completedAt != null;
}
