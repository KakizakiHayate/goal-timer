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

    /// 学習した時間（秒）
    required int totalSeconds,

    /// 作成日時
    @Default(null) DateTime? createdAt,

    /// 最終更新日時
    @Default(null) DateTime? updatedAt,

    /// 同期時の最終更新日時（同期処理で使用）
    @Default(null) DateTime? syncUpdatedAt,

    /// 同期状態（ローカルDBのみで使用）
    @Default(false) bool isSynced,

    /// 仮ユーザーかどうか
    @Default(false) bool isTemp,

    /// 仮ユーザーのID
    @Default(null) String? tempUserId,
  }) = _DailyStudyLogModel;

  /// Supabaseからのデータを元にDailyStudyLogModelを生成
  factory DailyStudyLogModel.fromJson(Map<String, dynamic> json) =>
      _$DailyStudyLogModelFromJson(json);

  /// 後方互換性のためのfromMapメソッド
  factory DailyStudyLogModel.fromMap(Map<String, dynamic> map) {
    // 日付の型変換処理（新スキーマでは study_date、旧スキーマでは date）
    DateTime parsedDate;
    final dateValue = map['study_date'] ?? map['date'];
    if (dateValue is String) {
      parsedDate = DateTime.parse(dateValue);
    } else if (dateValue is DateTime) {
      parsedDate = dateValue;
    } else {
      throw ArgumentError('Invalid date format');
    }

    // 整数値の安全な変換（total_secondsまたは古いminutesフィールドに対応）
    int parsedTotalSeconds;
    if (map['total_seconds'] != null) {
      final secondsValue = map['total_seconds'];
      if (secondsValue is int) {
        parsedTotalSeconds = secondsValue;
      } else if (secondsValue is String) {
        parsedTotalSeconds = int.tryParse(secondsValue) ?? 0;
      } else {
        parsedTotalSeconds = 0;
      }
    } else if (map['minutes'] != null) {
      // 後方互換性: 古いminutesフィールドから変換
      final minutesValue = map['minutes'];
      if (minutesValue is int) {
        parsedTotalSeconds = minutesValue * 60;
      } else if (minutesValue is String) {
        parsedTotalSeconds = (int.tryParse(minutesValue) ?? 0) * 60;
      } else {
        parsedTotalSeconds = 0;
      }
    } else {
      parsedTotalSeconds = 0;
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

    // createdAtの変換
    DateTime? parsedCreatedAt;
    if (map['created_at'] != null) {
      if (map['created_at'] is String) {
        parsedCreatedAt = DateTime.parse(map['created_at']);
      } else if (map['created_at'] is DateTime) {
        parsedCreatedAt = map['created_at'];
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

    // 仮ユーザー状態の変換
    bool parsedIsTemp = false;
    if (map['is_temp'] != null) {
      if (map['is_temp'] is bool) {
        parsedIsTemp = map['is_temp'];
      } else if (map['is_temp'] is int) {
        parsedIsTemp = map['is_temp'] == 1;
      } else if (map['is_temp'] is String) {
        parsedIsTemp = map['is_temp'] == 'true' || map['is_temp'] == '1';
      }
    }

    return DailyStudyLogModel(
      id: map['id'] ?? '',
      goalId: map['goal_id'] ?? '',
      date: parsedDate,
      totalSeconds: parsedTotalSeconds,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      syncUpdatedAt: parsedSyncUpdatedAt,
      isSynced: parsedIsSynced,
      isTemp: parsedIsTemp,
      tempUserId: map['temp_user_id'],
    );
  }
}

extension DailyStudyLogModelExtension on DailyStudyLogModel {
  /// 分単位で取得
  int get totalMinutes => totalSeconds ~/ 60;

  /// 表示用にフォーマットされた時間文字列
  String get displayTime {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}時間${minutes}分';
    } else if (minutes > 0) {
      return seconds > 0 ? '${minutes}分${seconds}秒' : '${minutes}分';
    } else {
      return '${seconds}秒';
    }
  }

  /// SupabaseへのInsert/Update用のMapに変換（新スキーマ対応）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'study_date': date.toIso8601String().split('T')[0], // 日付のみ（時間なし）
      'total_seconds': totalSeconds,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_updated_at': syncUpdatedAt?.toIso8601String(),
      // is_temp, temp_user_idはローカル専用のため、Supabaseには送信しない
    };
  }
}
