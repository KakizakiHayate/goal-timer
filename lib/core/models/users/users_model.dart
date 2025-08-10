import 'package:freezed_annotation/freezed_annotation.dart';

part 'users_model.freezed.dart';
part 'users_model.g.dart';

@freezed
class UsersModel with _$UsersModel {
  const factory UsersModel({
    /// ユーザーのid管理
    required String id,

    /// ユーザーのメールアドレス
    required String email,

    /// ユーザーの表示名
    required String displayName,

    /// アカウント作成日時
    required DateTime createdAt,

    /// 最終更新日時
    required DateTime updatedAt,

    /// 最終ログイン日時
    DateTime? lastLogin,

    /// 同期時の最終更新日時（同期処理で使用）
    @Default(null) DateTime? syncUpdatedAt,

    /// 同期状態（ローカルDBのみで使用）
    @Default(false) bool isSynced,
  }) = _UsersModel;

  /// Supabaseからのデータを元にUsersModelを生成
  factory UsersModel.fromJson(Map<String, dynamic> json) =>
      _$UsersModelFromJson(json);

  /// 後方互換性のためのfromMapメソッド
  factory UsersModel.fromMap(Map<String, dynamic> map) {
    // created_atの型変換処理
    DateTime parsedCreatedAt;
    if (map['created_at'] is String) {
      parsedCreatedAt = DateTime.parse(map['created_at']);
    } else if (map['created_at'] is DateTime) {
      parsedCreatedAt = map['created_at'];
    } else {
      throw ArgumentError('Invalid created_at format');
    }

    // updated_atの型変換処理
    DateTime parsedUpdatedAt;
    if (map['updated_at'] is String) {
      parsedUpdatedAt = DateTime.parse(map['updated_at']);
    } else if (map['updated_at'] is DateTime) {
      parsedUpdatedAt = map['updated_at'];
    } else {
      throw ArgumentError('Invalid updated_at format');
    }

    // last_loginの型変換処理（nullable）
    DateTime? parsedLastLogin;
    if (map['last_login'] != null) {
      if (map['last_login'] is String) {
        parsedLastLogin = DateTime.parse(map['last_login']);
      } else if (map['last_login'] is DateTime) {
        parsedLastLogin = map['last_login'];
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

    return UsersModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['display_name'] ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      lastLogin: parsedLastLogin,
      syncUpdatedAt: parsedSyncUpdatedAt,
      isSynced: parsedIsSynced,
    );
  }
}

extension UsersModelExtension on UsersModel {
  /// SupabaseへのInsert/Update用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }
}
