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

    return UsersModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['display_name'] ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
      lastLogin: parsedLastLogin,
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
