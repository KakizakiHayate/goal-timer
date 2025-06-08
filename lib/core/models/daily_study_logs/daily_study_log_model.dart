import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_study_log_model.freezed.dart';
part 'daily_study_log_model.g.dart';

@freezed
class DailyStudyLogModel with _$DailyStudyLogModel {
  const factory DailyStudyLogModel({
    /// 自動生成される一意のID
    required String id,

    /// 関連する目標のID
    required String goalId,

    /// 学習した日付
    required DateTime date,

    /// 学習した時間（分）
    required int minutes,
  }) = _DailyStudyLogModel;

  /// Supabaseからのデータを元にDailyStudyLogModelを生成
  factory DailyStudyLogModel.fromJson(Map<String, dynamic> json) =>
      _$DailyStudyLogModelFromJson(json);

  /// 後方互換性のためのfromMapメソッド
  factory DailyStudyLogModel.fromMap(Map<String, dynamic> map) {
    // 日付の型変換処理
    DateTime parsedDate;
    if (map['date'] is String) {
      parsedDate = DateTime.parse(map['date']);
    } else if (map['date'] is DateTime) {
      parsedDate = map['date'];
    } else {
      throw ArgumentError('Invalid date format');
    }

    // 整数値の安全な変換
    int parsedMinutes;
    final minutesValue = map['minutes'];
    if (minutesValue is int) {
      parsedMinutes = minutesValue;
    } else if (minutesValue is String) {
      parsedMinutes = int.tryParse(minutesValue) ?? 0;
    } else {
      parsedMinutes = 0;
    }

    return DailyStudyLogModel(
      id: map['id'] ?? '',
      goalId: map['goal_id'] ?? '',
      date: parsedDate,
      minutes: parsedMinutes,
    );
  }
}

extension DailyStudyLogModelExtension on DailyStudyLogModel {
  /// SupabaseへのInsert/Update用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'date': date.toIso8601String(),
      'minutes': minutes,
    };
  }
}
