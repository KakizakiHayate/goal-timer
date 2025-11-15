import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:goal_timer/backup/core/utils/time_utils.dart';

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

    /// 目標達成に必要な時間（分単位）
    required int targetMinutes,

    /// 実際に使った時間（分単位）
    required int spentMinutes,

    /// 最終更新日時
    @Default(null) DateTime? updatedAt,

    /// 同期時の最終更新日時（同期処理で使用）
    @Default(null) DateTime? syncUpdatedAt,

    /// 同期状態（ローカルDBのみで使用）
    @Default(false) bool isSynced,
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

    // completed_at → isCompleted変換
    bool parsedIsCompleted;
    final completedAtValue = map['completed_at'];
    if (completedAtValue != null) {
      parsedIsCompleted = true; // completed_atに値があれば完了
    } else {
      // 後方互換性: 古いis_completedフィールドもサポート
      final isCompletedValue = map['is_completed'];
      if (isCompletedValue is bool) {
        parsedIsCompleted = isCompletedValue;
      } else if (isCompletedValue is String) {
        parsedIsCompleted = isCompletedValue == 'true';
      } else {
        parsedIsCompleted = false;
      }
    }

    // 整数値の安全な変換
    int parsedTargetMinutes;
    // 互換性のため、両方のフィールド名をサポート
    final targetValue = map['target_minutes'] ?? map['total_target_hours'];
    if (targetValue is int) {
      // total_target_hoursの場合は時間から分に変換
      if (map['total_target_hours'] != null && map['target_minutes'] == null) {
        parsedTargetMinutes = targetValue * 60;
      } else {
        parsedTargetMinutes = targetValue;
      }
    } else if (targetValue is String) {
      final parsed = int.tryParse(targetValue) ?? 0;
      // total_target_hoursの場合は時間から分に変換
      if (map['total_target_hours'] != null && map['target_minutes'] == null) {
        parsedTargetMinutes = parsed * 60;
      } else {
        parsedTargetMinutes = parsed;
      }
    } else {
      parsedTargetMinutes = 0;
    }

    int parsedSpentMinutes;
    final spentMinutesValue = map['spent_minutes'];
    if (spentMinutesValue is int) {
      parsedSpentMinutes = spentMinutesValue;
    } else if (spentMinutesValue is String) {
      parsedSpentMinutes = int.tryParse(spentMinutesValue) ?? 0;
    } else {
      parsedSpentMinutes = 0;
    }

    // updatedAtの変換
    DateTime? parsedUpdatedAt;
    if (map['updated_at'] != null) {
      if (map['updated_at'] is String) {
        parsedUpdatedAt = DateTime.parse(map['updated_at']);
      } else if (map['updated_at'] is DateTime) {
        parsedUpdatedAt = map['updated_at'];
      }
    }

    // syncUpdatedAtの変換
    DateTime? parsedSyncUpdatedAt;
    if (map['sync_updated_at'] != null) {
      if (map['sync_updated_at'] is String) {
        parsedSyncUpdatedAt = DateTime.parse(map['sync_updated_at']);
      } else if (map['sync_updated_at'] is DateTime) {
        parsedSyncUpdatedAt = map['sync_updated_at'];
      }
    }

    // 同期状態の変換
    bool parsedIsSynced = false;
    if (map['is_synced'] != null) {
      if (map['is_synced'] is bool) {
        parsedIsSynced = map['is_synced'];
      } else if (map['is_synced'] is int) {
        parsedIsSynced = map['is_synced'] == 1;
      } else if (map['is_synced'] is String) {
        parsedIsSynced = map['is_synced'] == 'true' || map['is_synced'] == '1';
      }
    }

    return GoalsModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      deadline: parsedDeadline,
      isCompleted: parsedIsCompleted,
      avoidMessage: map['avoid_message'] ?? '',
      targetMinutes: parsedTargetMinutes,
      spentMinutes: parsedSpentMinutes,
      updatedAt: parsedUpdatedAt,
      syncUpdatedAt: parsedSyncUpdatedAt,
      isSynced: parsedIsSynced,
    );
  }
}

extension GoalsModelExtension on GoalsModel {
  /// SupabaseへのInsert/Update用のMapに変換
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String().split('T')[0], // 日付のみ（時間なし）
      'avoid_message': avoidMessage,
      'target_minutes': targetMinutes,
      // is_completed, spent_minutesは削除（Supabaseに存在しない）
    };

    // isCompleted → completed_at変換
    if (isCompleted) {
      map['completed_at'] = DateTime.now().toIso8601String();
    }

    // 同期関連フィールドを追加
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }

    return map;
  }

  /// 残り時間を文字列で取得
  String getRemainingTimeText() {
    return TimeUtils.calculateRemainingTimeFromMinutes(
      targetMinutes,
      spentMinutes,
    );
  }

  /// 残り時間（分）を取得
  int getRemainingMinutes() {
    return TimeUtils.calculateRemainingMinutesFromTotal(
      targetMinutes,
      spentMinutes,
    );
  }

  /// 進捗率を取得（0.0〜1.0）
  double getProgressRate() {
    return TimeUtils.calculateProgressRateFromMinutes(
      targetMinutes,
      spentMinutes,
    );
  }
}
