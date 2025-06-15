import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:goal_timer/core/data/datasources/local/goals/local_goals_datasource.dart';
import 'package:goal_timer/core/data/datasources/supabase/goals/supabase_goals_datasource.dart';
import 'package:goal_timer/core/data/repositories/goals/goals_repository.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';
import 'package:goal_timer/core/data/local/sync/sync_metadata_manager.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class HybridGoalsRepository implements GoalsRepository {
  final LocalGoalsDatasource _localDatasource;
  final SupabaseGoalsDatasource _remoteDatasource;
  final SyncStateNotifier _syncNotifier;
  final Connectivity _connectivity;
  final SyncMetadataManager _syncMetadata;

  static const String _tableName = 'goals';

  HybridGoalsRepository({
    required LocalGoalsDatasource localDatasource,
    required SupabaseGoalsDatasource remoteDatasource,
    required SyncStateNotifier syncNotifier,
    Connectivity? connectivity,
    SyncMetadataManager? syncMetadata,
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _syncNotifier = syncNotifier,
       _connectivity = connectivity ?? Connectivity(),
       _syncMetadata = syncMetadata ?? SyncMetadataManager();

  @override
  Future<List<GoalsModel>> getGoals() async {
    try {
      // まずローカルDBからデータを取得
      final localGoals = await _localDatasource.getGoals();
      AppLogger.instance.i('ローカルから${localGoals.length}件の目標を取得しました');

      // ネットワーク接続がある場合は差分同期を試みる
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // ローカルとリモートの最終更新時刻を取得
        final localLastModified = await _syncMetadata.getLocalLastModified(
          _tableName,
        );
        final remoteLastModified = await _remoteDatasource.getLastModified();

        // 差分同期が必要かチェック
        final needsSync = await _syncMetadata.needsSync(
          _tableName,
          localLastModified,
          remoteLastModified,
        );

        if (needsSync) {
          AppLogger.instance.i(
            '差分同期を開始します (ローカル: $localLastModified, リモート: $remoteLastModified)',
          );
          // バックグラウンドで差分同期を開始
          _performDifferentialSync();
        } else {
          AppLogger.instance.i('差分同期は不要です（データに変更なし）');
          _syncNotifier.setSynced();
        }
      } else {
        // オフラインモードを通知
        _syncNotifier.setOffline();
      }

      return localGoals;
    } catch (e) {
      AppLogger.instance.e('目標データの取得に失敗しました', e);
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
      AppLogger.instance.e('目標データの取得に失敗しました: $id', e);
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
          AppLogger.instance.e('リモートへの目標保存に失敗しました', e);
          _syncNotifier.setUnsynced();
        }
      } else {
        _syncNotifier.setOffline();
      }

      return localGoal;
    } catch (e) {
      AppLogger.instance.e('目標の作成に失敗しました', e);
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
          AppLogger.instance.e('リモートでの目標更新に失敗しました', e);
          _syncNotifier.setUnsynced();
        }
      } else {
        _syncNotifier.setOffline();
      }

      return updatedLocalGoal;
    } catch (e) {
      AppLogger.instance.e('目標の更新に失敗しました', e);
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
          AppLogger.instance.e('リモートでの目標削除に失敗しました', e);
          _syncNotifier.setUnsynced();
        }
      } else {
        _syncNotifier.setOffline();
      }
    } catch (e) {
      AppLogger.instance.e('目標の削除に失敗しました', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  /// 差分同期を実行（バックグラウンド）
  Future<void> _performDifferentialSync() async {
    try {
      _syncNotifier.setSyncing();

      final isFirstSync = await _syncMetadata.isFirstSync(_tableName);

      if (isFirstSync) {
        AppLogger.instance.i('初回同期を実行します');
        await _performFullSync();
      } else {
        AppLogger.instance.i('差分同期を実行します');
        await _performIncrementalSync();
      }

      // 同期時刻を更新
      await _syncMetadata.updateLastSyncTime(_tableName, DateTime.now());

      // リモートの最終更新時刻を保存
      final remoteLastModified = await _remoteDatasource.getLastModified();
      if (remoteLastModified != null) {
        await _syncMetadata.saveRemoteLastModified(
          _tableName,
          remoteLastModified,
        );
      }

      _syncNotifier.setSynced();

      AppLogger.instance.i('差分同期が完了しました');
    } catch (e) {
      AppLogger.instance.e('差分同期に失敗しました', e);
      _syncNotifier.setError(e.toString());
    }
  }

  /// 全件同期（初回同期時）
  Future<void> _performFullSync() async {
    try {
      // 1. ローカルの未同期データをリモートに反映
      final unsyncedGoals = await _localDatasource.getUnsyncedGoals();
      AppLogger.instance.i('未同期のローカルデータ: ${unsyncedGoals.length}件');

      for (final localGoal in unsyncedGoals) {
        try {
          // リモートに存在するか確認
          final remoteGoal = await _remoteDatasource.getGoalById(localGoal.id);

          if (remoteGoal == null) {
            // リモートに存在しない場合は新規作成
            await _remoteDatasource.createGoal(localGoal);
            AppLogger.instance.i('リモートに新規作成: ${localGoal.id}');
          } else {
            // リモートに存在する場合は、更新時刻比較
            if (localGoal.updatedAt != null &&
                remoteGoal.updatedAt != null &&
                localGoal.updatedAt!.isAfter(remoteGoal.updatedAt!)) {
              // ローカルの方が新しい場合は更新
              await _remoteDatasource.updateGoal(localGoal);
              AppLogger.instance.i('リモートを更新: ${localGoal.id}');
            }
          }

          // 同期済みとしてマーク
          await _localDatasource.markAsSynced(localGoal.id);
        } catch (e) {
          AppLogger.instance.e('リモートへの同期に失敗しました: ${localGoal.id}', e);
          // 個別の失敗は全体の失敗とはせず、続行
        }
      }

      // 2. リモートの全データをローカルに反映
      final remoteGoals = await _remoteDatasource.getGoals();
      AppLogger.instance.i('リモートデータ: ${remoteGoals.length}件');

      for (final remoteGoal in remoteGoals) {
        try {
          final localGoal = await _localDatasource.getGoalById(remoteGoal.id);

          if (localGoal == null) {
            // ローカルに存在しない場合は新規作成
            final syncedGoal = remoteGoal.copyWith(isSynced: true);
            await _localDatasource.createGoal(syncedGoal);
            AppLogger.instance.i('ローカルに新規作成: ${remoteGoal.id}');
          } else if (remoteGoal.updatedAt != null &&
              localGoal.updatedAt != null &&
              remoteGoal.updatedAt!.isAfter(localGoal.updatedAt!)) {
            // リモートの方が新しい場合は更新
            final syncedGoal = remoteGoal.copyWith(isSynced: true);
            await _localDatasource.updateGoal(syncedGoal);
            AppLogger.instance.i('ローカルを更新: ${remoteGoal.id}');
          }
        } catch (e) {
          AppLogger.instance.e('ローカルへの同期に失敗しました: ${remoteGoal.id}', e);
          // 個別の失敗は全体の失敗とはせず、続行
        }
      }
    } catch (e) {
      AppLogger.instance.e('全件同期に失敗しました', e);
      rethrow;
    }
  }

  /// 増分同期（差分同期）
  Future<void> _performIncrementalSync() async {
    try {
      final lastSyncTime = await _syncMetadata.getLastSyncTime(_tableName);
      if (lastSyncTime == null) {
        // 最終同期時刻が不明な場合は全件同期にフォールバック
        await _performFullSync();
        return;
      }

      // 1. ローカルの未同期データをリモートに反映
      final unsyncedGoals = await _localDatasource.getUnsyncedGoals();
      AppLogger.instance.i('未同期のローカルデータ: ${unsyncedGoals.length}件');

      for (final localGoal in unsyncedGoals) {
        try {
          // 最終同期時刻以降に更新されたもののみ処理
          if (localGoal.updatedAt?.isAfter(lastSyncTime) ?? false) {
            final remoteGoal = await _remoteDatasource.getGoalById(
              localGoal.id,
            );

            if (remoteGoal == null) {
              await _remoteDatasource.createGoal(localGoal);
              AppLogger.instance.i('リモートに新規作成: ${localGoal.id}');
            } else if (localGoal.updatedAt != null &&
                remoteGoal.updatedAt != null &&
                localGoal.updatedAt!.isAfter(remoteGoal.updatedAt!)) {
              await _remoteDatasource.updateGoal(localGoal);
              AppLogger.instance.i('リモートを更新: ${localGoal.id}');
            }

            await _localDatasource.markAsSynced(localGoal.id);
          }
        } catch (e) {
          AppLogger.instance.e('リモートへの差分同期に失敗しました: ${localGoal.id}', e);
        }
      }

      // 2. リモートの差分データをローカルに反映
      // 注意: Supabaseの場合、updated_atフィールドでフィルタリング
      final remoteGoals = await _remoteDatasource.getGoalsUpdatedAfter(
        lastSyncTime,
      );
      AppLogger.instance.i('リモートの差分データ: ${remoteGoals.length}件');

      for (final remoteGoal in remoteGoals) {
        try {
          final localGoal = await _localDatasource.getGoalById(remoteGoal.id);

          if (localGoal == null) {
            final syncedGoal = remoteGoal.copyWith(isSynced: true);
            await _localDatasource.createGoal(syncedGoal);
            AppLogger.instance.i('ローカルに新規作成: ${remoteGoal.id}');
          } else if (remoteGoal.updatedAt != null &&
              localGoal.updatedAt != null &&
              remoteGoal.updatedAt!.isAfter(localGoal.updatedAt!)) {
            final syncedGoal = remoteGoal.copyWith(isSynced: true);
            await _localDatasource.updateGoal(syncedGoal);
            AppLogger.instance.i('ローカルを更新: ${remoteGoal.id}');
          }
        } catch (e) {
          AppLogger.instance.e('ローカルへの差分同期に失敗しました: ${remoteGoal.id}', e);
        }
      }
    } catch (e) {
      AppLogger.instance.e('増分同期に失敗しました', e);
      // エラー時は全件同期にフォールバック
      AppLogger.instance.i('全件同期にフォールバックします');
      await _performFullSync();
    }
  }

  /// リモートと同期を実行（外部から呼び出し可能）
  Future<void> syncWithRemote() async {
    try {
      // 接続確認
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
        return;
      }

      // 差分同期を実行
      await _performDifferentialSync();
    } catch (e) {
      AppLogger.instance.e('同期に失敗しました', e);
      _syncNotifier.setError(e.toString());
    }
  }

  /// 強制的に全件同期を実行（デバッグ用）
  Future<void> forceFullSync() async {
    try {
      _syncNotifier.setSyncing();

      // 同期メタデータをリセット
      await _syncMetadata.resetSyncMetadata(_tableName);

      // 全件同期を実行
      await _performFullSync();

      // 同期時刻を更新
      await _syncMetadata.updateLastSyncTime(_tableName, DateTime.now());

      // リモートの最終更新時刻を保存
      final remoteLastModified = await _remoteDatasource.getLastModified();
      if (remoteLastModified != null) {
        await _syncMetadata.saveRemoteLastModified(
          _tableName,
          remoteLastModified,
        );
      }

      _syncNotifier.setSynced();

      AppLogger.instance.i('強制全件同期が完了しました');
    } catch (e) {
      AppLogger.instance.e('強制全件同期に失敗しました', e);
      _syncNotifier.setError(e.toString());
    }
  }
}
