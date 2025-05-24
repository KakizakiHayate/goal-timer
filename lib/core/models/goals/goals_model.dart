class GoalsModel {
  /// 各目標のid管理
  final String id;

  /// users tableのidとリレーション
  final String userId;

  /// 目標名
  final String title;

  /// 目標の詳細説明
  final String description;

  /// いつまで(日付)に達成するのか？
  final DateTime deadline;

  /// 目標を完了したかの判定フラグ
  final bool isCompleted;

  /// 目標達成しなかったら自分に課すこと
  final String avoidMessage;

  /// 目標の進捗率（0.0-100.0）
  final double progressPercent;

  /// 目標達成に必要な総時間（時間単位）
  final int totalTargetHours;

  /// 実際に使った時間（分単位）
  final int spentMinutes;

  const GoalsModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.isCompleted,
    required this.avoidMessage,
    required this.progressPercent,
    required this.totalTargetHours,
    required this.spentMinutes,
  });

  /// Supabaseからのデータを元にGoalsModelを生成
  factory GoalsModel.fromMap(Map<String, dynamic> map) {
    return GoalsModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: DateTime.parse(map['deadline']),
      isCompleted: map['is_completed'] == true || map['is_completed'] == 'true',
      avoidMessage: map['avoid_message'] ?? '',
      progressPercent: (map['progress_percent'] ?? 0.0).toDouble(),
      totalTargetHours: map['total_target_hours'] ?? 0,
      spentMinutes: map['spent_minutes'] ?? 0,
    );
  }

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

  /// GoalsModelのコピーを作成（部分的な更新用）
  GoalsModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
    String? avoidMessage,
    double? progressPercent,
    int? totalTargetHours,
    int? spentMinutes,
  }) {
    return GoalsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      avoidMessage: avoidMessage ?? this.avoidMessage,
      progressPercent: progressPercent ?? this.progressPercent,
      totalTargetHours: totalTargetHours ?? this.totalTargetHours,
      spentMinutes: spentMinutes ?? this.spentMinutes,
    );
  }

  @override
  String toString() {
    return 'GoalsModel(id: $id, userId: $userId, title: $title, description: $description, deadline: $deadline, isCompleted: $isCompleted, avoidMessage: $avoidMessage, progressPercent: $progressPercent, totalTargetHours: $totalTargetHours, spentMinutes: $spentMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalsModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.deadline == deadline &&
        other.isCompleted == isCompleted &&
        other.avoidMessage == avoidMessage &&
        other.progressPercent == progressPercent &&
        other.totalTargetHours == totalTargetHours &&
        other.spentMinutes == spentMinutes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      description,
      deadline,
      isCompleted,
      avoidMessage,
      progressPercent,
      totalTargetHours,
      spentMinutes,
    );
  }
}
