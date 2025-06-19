import 'package:goal_timer/core/models/users/users_model.dart';

/// ユーザーデータのリポジトリインターフェース
abstract class UsersRepository {
  /// すべてのユーザーを取得
  Future<List<UsersModel>> getUsers();

  /// 特定のIDのユーザーを取得
  Future<UsersModel?> getUserById(String id);

  /// 現在のユーザー情報を取得
  Future<UsersModel?> getCurrentUser();

  /// 新規ユーザーを作成
  Future<UsersModel> createUser(UsersModel user);

  /// ユーザー情報を更新
  Future<UsersModel> updateUser(UsersModel user);

  /// ユーザーを追加または更新
  Future<UsersModel> upsertUser(UsersModel user);

  /// リモートと同期を実行
  Future<void> syncWithRemote();
}
