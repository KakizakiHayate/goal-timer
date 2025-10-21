import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal_form_data.freezed.dart';

/// 目標フォームのデータクラス
/// GoalFormWidgetから親ウィジェットにデータを渡すために使用
@freezed
class GoalFormData with _$GoalFormData {
  const factory GoalFormData({
    required String title,
    required String description,
    required String avoidMessage,
    required int targetMinutes,
    required DateTime deadline,
    required bool isValid,
  }) = _GoalFormData;

  /// 空のデータを生成
  factory GoalFormData.empty() => GoalFormData(
        title: '',
        description: '',
        avoidMessage: '',
        targetMinutes: 30,
        deadline: DateTime.now().add(const Duration(days: 30)),
        isValid: false,
      );
}
