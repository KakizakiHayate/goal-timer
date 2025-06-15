import 'package:goal_timer/core/models/users/users_model.dart';

/// ユーザーデータのリポジトリインターフェース
abstract class UsersRepository {
  /// すべてのユーザーを取得
  Future<List<UsersModel>> getUsers();

  /// 特定のIDのユーザーを取得
  Future<UsersModel?> getUserById(String id);

  /// 現在のユーザー情報を取得
  Future<UsersModel?> getCurrentUser();

  /// ユーザー情報を更新
  Future<UsersModel> updateUser(UsersModel user);

  /// リモートと同期を実行
  Future<void> syncWithRemote();
}
