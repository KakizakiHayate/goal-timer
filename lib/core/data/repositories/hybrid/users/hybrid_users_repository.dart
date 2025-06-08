import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:goal_timer/core/data/datasources/local/users/local_users_datasource.dart';
import 'package:goal_timer/core/data/datasources/supabase/users/supabase_users_datasource.dart';
import 'package:goal_timer/core/models/users/users_model.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class HybridUsersRepository {
  final LocalUsersDatasource _localDatasource;
  final SupabaseUsersDatasource _remoteDatasource;
  final SyncStateNotifier _syncNotifier;
  final Connectivity _connectivity;

  HybridUsersRepository({
    required LocalUsersDatasource localDatasource,
    required SupabaseUsersDatasource remoteDatasource,
    required SyncStateNotifier syncNotifier,
    Connectivity? connectivity,
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _syncNotifier = syncNotifier,
       _connectivity = connectivity ?? Connectivity();

  // 全ユーザーを取得
  Future<List<UsersModel>> getUsers() async {
    try {
      // まずローカルDBからデータを取得
      final localUsers = await _localDatasource.getUsers();

      // ネットワーク接続がある場合は同期を試みる
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // バックグラウンドで同期を開始
        syncWithRemote();
      } else {
        // オフラインモードを通知
        _syncNotifier.setOffline();
      }

      return localUsers;
    } catch (e) {
      AppLogger.instance.e('ユーザーデータの取得に失敗しました', e);
      // エラー通知
      _syncNotifier.setError(e.toString());
      return [];
    }
  }

  // 特定のIDのユーザーを取得
  Future<UsersModel?> getUserById(String id) async {
    try {
      // まずローカルDBから検索
      final localUser = await _localDatasource.getUserById(id);

      // ローカルに存在する場合はそれを返す
      if (localUser != null) {
        return localUser;
      }

      // ローカルに存在しない場合、ネットワーク接続があればリモートから取得
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final remoteUser = await _remoteDatasource.getUserById(id);

        // リモートから取得できた場合はローカルに保存
        if (remoteUser != null) {
          await _localDatasource.upsertUser(remoteUser);
          await _localDatasource.markAsSynced(remoteUser.id);
          return remoteUser;
        }
      } else {
        _syncNotifier.setOffline();
      }

      // 見つからない場合はnullを返す
      return null;
    } catch (e) {
      AppLogger.instance.e('ユーザーデータの取得に失敗しました: $id', e);
      _syncNotifier.setError(e.toString());
      return null;
    }
  }

  // 現在のユーザー情報を取得
  Future<UsersModel?> getCurrentUser() async {
    try {
      // リモートから現在のユーザー情報を取得
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final remoteUser = await _remoteDatasource.getCurrentUser();

        if (remoteUser != null) {
          // ローカルに保存
          await _localDatasource.upsertUser(remoteUser);
          await _localDatasource.markAsSynced(remoteUser.id);
          return remoteUser;
        }
      } else {
        _syncNotifier.setOffline();
        // オフライン時は最後に保存されたユーザーを取得（実装が必要）
        // ここでは簡易的に最初のユーザーを返す
        final users = await _localDatasource.getUsers();
        if (users.isNotEmpty) {
          return users.first;
        }
      }

      return null;
    } catch (e) {
      AppLogger.instance.e('現在のユーザー情報の取得に失敗しました', e);
      _syncNotifier.setError(e.toString());
      return null;
    }
  }

  // ユーザー情報を更新
  Future<UsersModel> updateUser(UsersModel user) async {
    try {
      // まずローカルDBに保存
      final localUser = await _localDatasource.upsertUser(user);

      // ネットワーク接続がある場合はリモートにも保存
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          // リモートに保存
          final remoteUser = await _remoteDatasource.updateUser(localUser);

          // 同期済みとしてマーク
          await _localDatasource.markAsSynced(remoteUser.id);

          // 同期成功を通知
          _syncNotifier.setSynced();

          return remoteUser;
        } catch (e) {
          // リモート保存に失敗しても、ローカル保存は成功しているのでエラーにはしない
          AppLogger.instance.e('リモートへのユーザー情報保存に失敗しました', e);
          _syncNotifier.setUnsynced();
        }
      } else {
        _syncNotifier.setOffline();
      }

      return localUser;
    } catch (e) {
      AppLogger.instance.e('ユーザー情報の更新に失敗しました', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  // リモートと同期を実行
  Future<void> syncWithRemote() async {
    _syncNotifier.setSyncing();

    try {
      // 接続確認
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
        return;
      }

      // 1. ローカルの未同期データをリモートに反映
      final unsyncedUsers = await _localDatasource.getUnsyncedUsers();
      for (final localUser in unsyncedUsers) {
        try {
          // リモートに存在するか確認
          final remoteUser = await _remoteDatasource.getUserById(localUser.id);

          if (remoteUser == null) {
            // リモートに存在しない場合は新規作成
            await _remoteDatasource.createUser(localUser);
          } else {
            // リモートに存在する場合は更新
            await _remoteDatasource.updateUser(localUser);
          }

          // 同期済みとしてマーク
          await _localDatasource.markAsSynced(localUser.id);
        } catch (e) {
          AppLogger.instance.e('リモートへの同期に失敗しました: ${localUser.id}', e);
          // 個別の失敗は全体の失敗とはせず、続行
        }
      }

      // 2. リモートの新しいデータをローカルに反映
      final remoteUsers = await _remoteDatasource.getUsers();
      for (final remoteUser in remoteUsers) {
        try {
          // ローカルに存在するか確認
          final localUser = await _localDatasource.getUserById(remoteUser.id);

          if (localUser == null) {
            // ローカルに存在しない場合は新規作成を試みる
            try {
              await _localDatasource.upsertUser(remoteUser);
              await _localDatasource.markAsSynced(remoteUser.id);
              AppLogger.instance.i('ローカルにユーザーを作成しました: ${remoteUser.id}');
            } catch (insertError) {
              // 主キー制約エラーが発生した場合は、ログに記録
              AppLogger.instance.w(
                'ユーザー作成に失敗: ${remoteUser.id} - ${insertError.toString()}',
              );
            }
          } else {
            // 既に同期されているかどうかをLocalUsersDatasourceから取得した情報でチェック
            final isLocalDataUnsynced = await _isUserUnsynced(localUser.id);

            if (isLocalDataUnsynced) {
              // ローカルに存在し、未同期の場合（ローカルでの変更がある場合）
              // この場合はローカルの変更を優先
              AppLogger.instance.i('ローカルの変更を優先: ${remoteUser.id}');
            } else {
              // ローカルに存在し、かつ同期済みの場合は更新
              await _localDatasource.upsertUser(remoteUser);
              await _localDatasource.markAsSynced(remoteUser.id);
              AppLogger.instance.i('ローカルのユーザーを更新しました: ${remoteUser.id}');
            }
          }
        } catch (e) {
          AppLogger.instance.e('ローカルへの同期に失敗しました: ${remoteUser.id}', e);
          // 個別の失敗は全体の失敗とはせず、続行
        }
      }

      // 同期完了を通知
      _syncNotifier.setSynced();
    } catch (e) {
      AppLogger.instance.e('同期処理に失敗しました', e);
      _syncNotifier.setError(e.toString());
    }
  }

  // ユーザーが未同期かどうかを確認するヘルパーメソッド
  Future<bool> _isUserUnsynced(String userId) async {
    final unsyncedUsers = await _localDatasource.getUnsyncedUsers();
    return unsyncedUsers.any((user) => user.id == userId);
  }
}
