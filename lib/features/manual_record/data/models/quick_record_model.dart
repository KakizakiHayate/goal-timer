import '../../domain/entities/quick_record.dart';

/// Issue #44: 手動学習記録データモデル
class QuickRecordModel extends QuickRecord {
  const QuickRecordModel({
    required super.goalId,
    required super.date,
    required super.hours,
    required super.minutes,
  });

  /// エンティティから変換
  factory QuickRecordModel.fromEntity(QuickRecord entity) {
    return QuickRecordModel(
      goalId: entity.goalId,
      date: entity.date,
      hours: entity.hours,
      minutes: entity.minutes,
    );
  }

  /// エンティティに変換
  QuickRecord toEntity() {
    return QuickRecord(
      goalId: goalId,
      date: date,
      hours: hours,
      minutes: minutes,
    );
  }

  /// JSONから変換
  factory QuickRecordModel.fromJson(Map<String, dynamic> json) {
    return QuickRecordModel(
      goalId: json['goalId'] as String,
      date: DateTime.parse(json['date'] as String),
      hours: json['hours'] as int,
      minutes: json['minutes'] as int,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'goalId': goalId,
      'date': date.toIso8601String(),
      'hours': hours,
      'minutes': minutes,
    };
  }

  @override
  QuickRecordModel copyWith({
    String? goalId,
    DateTime? date,
    int? hours,
    int? minutes,
  }) {
    return QuickRecordModel(
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      minutes: minutes ?? this.minutes,
    );
  }
}