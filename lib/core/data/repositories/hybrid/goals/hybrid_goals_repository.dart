import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:goal_timer/core/data/datasources/local/goals/local_goals_datasource.dart';
import 'package:goal_timer/core/data/datasources/supabase/goals/supabase_goals_datasource.dart';
import 'package:goal_timer/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';

class HybridGoalsRepository implements GoalsRepository {
  final LocalGoalsDatasource _localDatasource;
  final SupabaseGoalsDatasource _remoteDatasource;
  final SyncStateNotifier _syncNotifier;
  final Connectivity _connectivity;

  HybridGoalsRepository({
    required LocalGoalsDatasource localDatasource,
    required SupabaseGoalsDatasource remoteDatasource,
    required SyncStateNotifier syncNotifier,
    Connectivity? connectivity,
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _syncNotifier = syncNotifier,
       _connectivity = connectivity ?? Connectivity();

  @override
  Future<List<GoalsModel>> getGoals() async {
    try {
      // まずローカルDBからデータを取得
      final localGoals = await _localDatasource.getGoals();

      // ネットワーク接続がある場合は同期を試みる
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // バックグラウンドで同期を開始
        syncWithRemote();
      } else {
        // オフラインモードを通知
        _syncNotifier.setOffline();
      }

      return localGoals;
    } catch (e) {
      print('目標データの取得に失敗しました: $e');
      // エラー通知
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  @override
  Future<GoalsModel?> getGoalById(String id) async {
    try {
      // まずローカルDBから検索
      final localGoal = await _localDatasource.getGoalById(id);

      // ローカルに存在する場合はそれを返す
      if (localGoal != null) {
        return localGoal;
      }

      // ローカルに存在しない場合、ネットワーク接続があればリモートから取得
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final remoteGoal = await _remoteDatasource.getGoalById(id);

        // リモートから取得できた場合はローカルに保存
        if (remoteGoal != null) {
          // 同期済みフラグをセット
          final syncedGoal = remoteGoal.copyWith(isSynced: true);
          await _localDatasource.createGoal(syncedGoal);
          return syncedGoal;
        }
      } else {
        _syncNotifier.setOffline();
      }

      // 見つからない場合はnullを返す
      return null;
    } catch (e) {
      print('目標データの取得に失敗しました: $id, $e');
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  @override
  Future<GoalsModel> createGoal(GoalsModel goal) async {
    try {
      // まずローカルDBに保存
      final localGoal = await _localDatasource.createGoal(goal);

      // ネットワーク接続がある場合はリモートにも保存
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          // リモートに保存
          final remoteGoal = await _remoteDatasource.createGoal(localGoal);

          // 同期済みとしてマーク
          await _localDatasource.markAsSynced(remoteGoal.id);

          // 同期成功を通知
          _syncNotifier.setSynced();

          return remoteGoal;
        } catch (e) {
          // リモート保存に失敗しても、ローカル保存は成功しているのでエラーにはしない
          print('リモートへの目標保存に失敗しました: $e');
          _syncNotifier.setUnsynced();
        }
      } else {
        _syncNotifier.setOffline();
      }

      return localGoal;
    } catch (e) {
      print('目標の作成に失敗しました: $e');
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  @override
  Future<GoalsModel> updateGoal(GoalsModel goal) async {
    try {
      // まずローカルDBを更新
      final updatedLocalGoal = await _localDatasource.updateGoal(goal);

      // ネットワーク接続がある場合はリモートも更新
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          // リモートを更新
          final updatedRemoteGoal = await _remoteDatasource.updateGoal(
            updatedLocalGoal,
          );

          // 同期済みとしてマーク
          await _localDatasource.markAsSynced(updatedRemoteGoal.id);

          // 同期成功を通知
          _syncNotifier.setSynced();

          return updatedRemoteGoal;
        } catch (e) {
          // リモート更新に失敗しても、ローカル更新は成功しているのでエラーにはしない
          print('リモートでの目標更新に失敗しました: $e');
          _syncNotifier.setUnsynced();
        }
      } else {
        _syncNotifier.setOffline();
      }

      return updatedLocalGoal;
    } catch (e) {
      print('目標の更新に失敗しました: $e');
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      // まずローカルDBから削除
      await _localDatasource.deleteGoal(id);

      // ネットワーク接続がある場合はリモートからも削除
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          // リモートから削除
          await _remoteDatasource.deleteGoal(id);

          // 同期成功を通知
          _syncNotifier.setSynced();
        } catch (e) {
          // リモート削除に失敗しても、ローカル削除は成功しているのでエラーにはしない
          print('リモートでの目標削除に失敗しました: $e');
          _syncNotifier.setUnsynced();
        }
      } else {
        _syncNotifier.setOffline();
      }
    } catch (e) {
      print('目標の削除に失敗しました: $e');
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  /// リモートと同期を実行
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
      final unsyncedGoals = await _localDatasource.getUnsyncedGoals();
      for (final localGoal in unsyncedGoals) {
        try {
          // リモートに存在するか確認
          final remoteGoal = await _remoteDatasource.getGoalById(localGoal.id);

          if (remoteGoal == null) {
            // リモートに存在しない場合は新規作成
            await _remoteDatasource.createGoal(localGoal);
          } else {
            // リモートに存在する場合は、バージョン比較
            if (localGoal.version > remoteGoal.version) {
              // ローカルの方が新しい場合は更新
              await _remoteDatasource.updateGoal(localGoal);
            }
          }

          // 同期済みとしてマーク
          await _localDatasource.markAsSynced(localGoal.id);
        } catch (e) {
          print('リモートへの同期に失敗しました: ${localGoal.id}, $e');
          // 個別の失敗は全体の失敗とはせず、続行
        }
      }

      // 2. リモートの新しいデータをローカルに反映
      final remoteGoals = await _remoteDatasource.getGoals();
      for (final remoteGoal in remoteGoals) {
        try {
          final localGoal = await _localDatasource.getGoalById(remoteGoal.id);

          if (localGoal == null) {
            // ローカルに存在しない場合は新規作成
            final syncedGoal = remoteGoal.copyWith(isSynced: true);
            await _localDatasource.createGoal(syncedGoal);
          } else if (remoteGoal.version > localGoal.version) {
            // リモートの方が新しい場合は更新
            final syncedGoal = remoteGoal.copyWith(isSynced: true);
            await _localDatasource.updateGoal(syncedGoal);
          }
        } catch (e) {
          print('ローカルへの同期に失敗しました: ${remoteGoal.id}, $e');
          // 個別の失敗は全体の失敗とはせず、続行
        }
      }

      // 同期成功を通知
      _syncNotifier.setSynced();
    } catch (e) {
      print('同期に失敗しました: $e');
      _syncNotifier.setError(e.toString());
    }
  }
}
