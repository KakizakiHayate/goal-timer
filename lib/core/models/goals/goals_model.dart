import 'package:freezed_annotation/freezed_annotation.dart';

part 'goals_model.freezed.dart';
part 'goals_model.g.dart';

@freezed
class GoalsModel with _$GoalsModel {
  const factory GoalsModel({
    /// 各目標のid管理
    required String id,

    /// users tableのidとリレーション
    required String userId,

    /// 目標名
    required String title,

    /// 目標の詳細説明
    required String description,

    /// いつまで(日付)に達成するのか？
    required DateTime deadline,

    /// 目標を完了したかの判定フラグ
    required bool isCompleted,

    /// 目標達成しなかったら自分に課すこと
    required String avoidMessage,

    /// 目標の進捗率（0.0-100.0）
    required double progressPercent,

    /// 目標達成に必要な総時間（時間単位）
    required int totalTargetHours,

    /// 実際に使った時間（分単位）
    required int spentMinutes,
  }) = _GoalsModel;

  /// Supabaseからのデータを元にGoalsModelを生成
  factory GoalsModel.fromJson(Map<String, dynamic> json) =>
      _$GoalsModelFromJson(json);

  /// 後方互換性のためのfromMapメソッド
  factory GoalsModel.fromMap(Map<String, dynamic> map) {
    // deadlineの型変換処理を追加
    DateTime parsedDeadline;
    if (map['deadline'] is String) {
      parsedDeadline = DateTime.parse(map['deadline']);
    } else if (map['deadline'] is DateTime) {
      parsedDeadline = map['deadline'];
    } else {
      throw ArgumentError('Invalid deadline format');
    }

    // booleanの型変換処理を追加
    bool parsedIsCompleted;
    final isCompletedValue = map['is_completed'];
    if (isCompletedValue is bool) {
      parsedIsCompleted = isCompletedValue;
    } else if (isCompletedValue is String) {
      parsedIsCompleted = isCompletedValue == 'true';
    } else {
      parsedIsCompleted = false;
    }

    return GoalsModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: parsedDeadline,
      isCompleted: parsedIsCompleted,
      avoidMessage: map['avoid_message'] ?? '',
      progressPercent: (map['progress_percent'] ?? 0.0).toDouble(),
      totalTargetHours: map['total_target_hours'] ?? 0,
      spentMinutes: map['spent_minutes'] ?? 0,
    );
  }
}

extension GoalsModelExtension on GoalsModel {
  /// SupabaseへのInsert/Update用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'is_completed': isCompleted,
      'avoid_message': avoidMessage,
      'progress_percent': progressPercent,
      'total_target_hours': totalTargetHours,
      'spent_minutes': spentMinutes,
    };
  }
}
