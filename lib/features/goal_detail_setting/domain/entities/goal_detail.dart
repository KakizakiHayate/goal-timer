// 'package:flutter/material.dart'のインポートを削除

// ゴール詳細を表すエンティティ
class GoalDetail {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;
  final String avoidMessage; // 避けたい未来のメッセージ
  final double progressPercent; // 進捗率（0.0〜1.0）
  final int targetHours; // 目標達成に必要な総時間（時間）
  final int spentMinutes; // 既に費やした時間（分）

  const GoalDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.isCompleted = false,
    required this.avoidMessage,
    this.progressPercent = 0.0,
    required this.targetHours,
    this.spentMinutes = 0,
  });

  // 残り日数を計算
  int get remainingDays {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  // 残り時間を計算（分単位）
  int get remainingMinutes {
    return (targetHours * 60) - spentMinutes;
  }

  // コピーメソッドでイミュータブルな更新を実現
  GoalDetail copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
    String? avoidMessage,
    double? progressPercent,
    int? targetHours,
    int? spentMinutes,
  }) {
    return GoalDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      avoidMessage: avoidMessage ?? this.avoidMessage,
      progressPercent: progressPercent ?? this.progressPercent,
      targetHours: targetHours ?? this.targetHours,
      spentMinutes: spentMinutes ?? this.spentMinutes,
    );
  }
}
