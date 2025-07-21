import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:goal_timer/core/data/datasources/local/users/local_users_datasource.dart';
import 'package:goal_timer/core/data/datasources/supabase/users/supabase_users_datasource.dart';
import 'package:goal_timer/core/data/repositories/users/users_repository.dart';
import 'package:goal_timer/core/models/users/users_model.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class HybridUsersRepository implements UsersRepository {
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
  @override
  Future<List<UsersModel>> getUsers() async {
    try {
      // ローカルDBからデータを取得のみ（自動同期は削除）
      final localUsers = await _localDatasource.getUsers();

      // ネットワーク接続状態のみ確認（同期は実行しない）
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      }

      return localUsers;
    } catch (e) {
      AppLogger.instance.e('ユーザーデータの取得に失敗しました', e);
      _syncNotifier.setError(e.toString());
      return [];
    }
  }

  // 特定のIDのユーザーを取得
  @override
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
  @override
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

  // 新規ユーザーを作成
  @override
  Future<UsersModel> createUser(UsersModel user) async {
    try {
      // ローカルDBのみに保存（リアルタイム同期は削除）
      final localUser = await _localDatasource.upsertUser(user);

      // ネットワーク接続状態を確認して未同期状態を設定
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      } else {
        _syncNotifier.setUnsynced(); // 未同期データありとして記録
      }

      AppLogger.instance.i('ユーザーをローカルに作成しました（手動同期が必要）');
      return localUser;
    } catch (e) {
      AppLogger.instance.e('ユーザーの作成に失敗しました', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  // ユーザー情報を更新
  @override
  Future<UsersModel> updateUser(UsersModel user) async {
    try {
      // ローカルDBのみに保存（リアルタイム同期は削除）
      final localUser = await _localDatasource.upsertUser(user);

      // ネットワーク接続状態を確認して未同期状態を設定
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      } else {
        _syncNotifier.setUnsynced(); // 未同期データありとして記録
      }

      AppLogger.instance.i('ユーザー情報をローカルで更新しました（手動同期が必要）');
      return localUser;
    } catch (e) {
      AppLogger.instance.e('ユーザー情報の更新に失敗しました', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  // ユーザーを追加または更新
  @override
  Future<UsersModel> upsertUser(UsersModel user) async {
    try {
      // ローカルDBのみに保存（リアルタイム同期は削除）
      final localUser = await _localDatasource.upsertUser(user);

      // ネットワーク接続状態を確認して未同期状態を設定
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      } else {
        _syncNotifier.setUnsynced(); // 未同期データありとして記録
      }

      AppLogger.instance.i('ユーザーをローカルでupsertしました（手動同期が必要）');
      return localUser;
    } catch (e) {
      AppLogger.instance.e('ユーザーのupsertに失敗しました', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  // リモートと同期を実行
  @override
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
            // syncUpdatedAtで比較して更新が必要かチェック
            if (localUser.syncUpdatedAt != null &&
                remoteUser.syncUpdatedAt != null &&
                localUser.syncUpdatedAt!.isAfter(remoteUser.syncUpdatedAt!)) {
              // ローカルの方が新しい場合は更新
              await _remoteDatasource.updateUser(localUser);
            }
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
            // ローカルに存在しない場合は新規作成
            final syncedUser = remoteUser.copyWith(isSynced: true);
            await _localDatasource.upsertUser(syncedUser);
            AppLogger.instance.i('ローカルにユーザーを作成しました: ${remoteUser.id}');
          } else if (remoteUser.syncUpdatedAt != null &&
              localUser.syncUpdatedAt != null &&
              remoteUser.syncUpdatedAt!.isAfter(localUser.syncUpdatedAt!)) {
            // リモートの方が新しい場合は更新
            final syncedUser = remoteUser.copyWith(isSynced: true);
            await _localDatasource.upsertUser(syncedUser);
            AppLogger.instance.i('ローカルのユーザーを更新しました: ${remoteUser.id}');
          }
        } catch (e) {
          AppLogger.instance.e('ローカルへの同期に失敗しました: ${remoteUser.id}', e);
          // 個別の失敗は全体の失敗とはせず、続行
        }
      }

      // setSynced() 削除: SyncCheckerが一元管理するため
      AppLogger.instance.i('ユーザーの差分同期が完了しました');
    } catch (e) {
      AppLogger.instance.e('同期処理に失敗しました', e);
      _syncNotifier.setError(e.toString());
    }
  }
}
