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

    /// 最終更新日時
    @Default(null) DateTime? updatedAt,

    /// 同期時の最終更新日時（同期処理で使用）
    @Default(null) DateTime? syncUpdatedAt,

    /// 同期状態（ローカルDBのみで使用）
    @Default(false) bool isSynced,
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

    return DailyStudyLogModel(
      id: map['id'] ?? '',
      goalId: map['goal_id'] ?? '',
      date: parsedDate,
      minutes: parsedMinutes,
      updatedAt: parsedUpdatedAt,
      syncUpdatedAt: parsedSyncUpdatedAt,
      isSynced: parsedIsSynced,
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
