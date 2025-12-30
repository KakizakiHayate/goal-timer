// ゴールを表すエンティティクラス
class Goal {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;

  const Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.isCompleted = false,
  });

  // コピーメソッドでイミュータブルな更新を実現
  Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
