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

  /// 同期処理をスキップしてローカルデータのみを取得
  @override
  Future<List<GoalsModel>> getLocalGoalsOnly() async {
    try {
      final localGoals = await _localDatasource.getGoals();
      AppLogger.instance.i('ローカルから${localGoals.length}件の目標を取得しました（同期スキップ）');
      return localGoals;
    } catch (e) {
      AppLogger.instance.e('ローカル目標データの取得に失敗しました', e);
      rethrow;
    }
  }

  @override
  Future<List<GoalsModel>> getGoals() async {
    try {
      // ローカルDBからデータを取得のみ（自動同期は削除）
      final localGoals = await _localDatasource.getGoals();
      AppLogger.instance.i('ローカルから${localGoals.length}件の目標を取得しました');

      // ネットワーク接続状態のみ確認（同期は実行しない）
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
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

      // ネットワーク接続状態を確認
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        // オフライン時：ローカルのみ保存、未同期状態
        _syncNotifier.setOffline();
        AppLogger.instance.i('オフライン：目標をローカルに作成しました（同期待ち）: ${localGoal.title}');
        return localGoal;
      } else {
        // オンライン時：Supabaseにも即座に保存を試行
        AppLogger.instance.i('オンライン状態を検出、Supabase保存を試行します: ${localGoal.title}');
        try {
          final remoteGoal = await _remoteDatasource.createGoal(localGoal);
          
          // Supabase保存成功：ローカルも同期済み状態に更新
          final syncedGoal = localGoal.copyWith(isSynced: true);
          await _localDatasource.updateGoal(syncedGoal);
          
          _syncNotifier.setSynced();
          AppLogger.instance.i('✅ オンライン：目標をローカル＆Supabaseに保存しました: ${remoteGoal.title}');
          return syncedGoal;
        } catch (remoteError) {
          // Supabase保存失敗：ローカル保存は成功として扱い、未同期状態にする
          _syncNotifier.setUnsynced();
          AppLogger.instance.w('❌ Supabase保存に失敗、ローカルのみ保存されました: ${localGoal.title}');
          AppLogger.instance.w('Supabaseエラー詳細: $remoteError');
          return localGoal;
        }
      }
    } catch (e) {
      AppLogger.instance.e('目標の作成に失敗しました', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  @override
  Future<GoalsModel> updateGoal(GoalsModel goal) async {
    try {
      AppLogger.instance.i('🔄 [HybridGoalsRepository] 目標更新処理を開始します');
      AppLogger.instance.i('📝 [HybridGoalsRepository] 更新目標: ${goal.title} (ID: ${goal.id})');
      // AppLogger.instance.i('📝 [HybridGoalsRepository] 目標時間: ${goal.targetMinutes}分');
      AppLogger.instance.i('📝 [HybridGoalsRepository] 回避メッセージ: ${goal.avoidMessage}');

      // まずローカルDBを更新
      AppLogger.instance.i('🚀 [HybridGoalsRepository] ローカルDBの更新を開始します...');
      final updatedLocalGoal = await _localDatasource.updateGoal(goal);
      AppLogger.instance.i('✅ [HybridGoalsRepository] ローカルDB更新完了: ${updatedLocalGoal.title}');

      // ネットワーク接続状態を確認
      AppLogger.instance.i('🌐 [HybridGoalsRepository] ネットワーク接続状態を確認中...');
      final connectivityResult = await _connectivity.checkConnectivity();
      AppLogger.instance.i('🌐 [HybridGoalsRepository] 接続状態: $connectivityResult');
      
      if (connectivityResult == ConnectivityResult.none) {
        // オフライン時：ローカルのみ更新、未同期状態
        _syncNotifier.setOffline();
        AppLogger.instance.i('📴 [HybridGoalsRepository] オフライン：目標をローカルで更新しました（同期待ち）: ${updatedLocalGoal.title}');
        return updatedLocalGoal;
      } else {
        // オンライン時：Supabaseにも即座に更新を試行
        AppLogger.instance.i('🌐 [HybridGoalsRepository] オンライン状態：Supabase更新を試行します');
        try {
          AppLogger.instance.i('🚀 [HybridGoalsRepository] Supabase更新を開始します...');
          final remoteGoal = await _remoteDatasource.updateGoal(updatedLocalGoal);
          AppLogger.instance.i('✅ [HybridGoalsRepository] Supabase更新成功: ${remoteGoal.title}');
          
          // Supabase更新成功：ローカルも同期済み状態に更新
          AppLogger.instance.i('🔄 [HybridGoalsRepository] ローカルを同期済み状態に更新します...');
          final syncedGoal = updatedLocalGoal.copyWith(isSynced: true);
          await _localDatasource.updateGoal(syncedGoal);
          AppLogger.instance.i('✅ [HybridGoalsRepository] ローカルの同期状態更新完了');
          
          _syncNotifier.setSynced();
          AppLogger.instance.i('🎉 [HybridGoalsRepository] オンライン：目標をローカル＆Supabaseで更新しました: ${remoteGoal.title}');
          return syncedGoal;
        } catch (remoteError) {
          // Supabase更新失敗：ローカル更新は成功として扱い、未同期状態にする
          _syncNotifier.setUnsynced();
          AppLogger.instance.w('❌ [HybridGoalsRepository] Supabase更新に失敗、ローカルのみ更新されました: ${updatedLocalGoal.title}');
          AppLogger.instance.w('❌ [HybridGoalsRepository] Supabaseエラー詳細: $remoteError');
          AppLogger.instance.w('❌ [HybridGoalsRepository] エラータイプ: ${remoteError.runtimeType}');
          return updatedLocalGoal;
        }
      }
    } catch (e) {
      AppLogger.instance.e('❌ [HybridGoalsRepository] 目標の更新に失敗しました', e);
      AppLogger.instance.e('❌ [HybridGoalsRepository] エラー詳細: ${e.toString()}');
      AppLogger.instance.e('❌ [HybridGoalsRepository] エラータイプ: ${e.runtimeType}');
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      // ローカルDBからのみ削除（リアルタイム同期は削除）
      await _localDatasource.deleteGoal(id);

      // ネットワーク接続状態を確認して未同期状態を設定
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      } else {
        _syncNotifier.setUnsynced(); // 未同期データありとして記録
      }

      AppLogger.instance.i('目標をローカルから削除しました（手動同期が必要）: $id');
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

      // setSynced() 削除: SyncCheckerが一元管理するため
      AppLogger.instance.i('目標の差分同期が完了しました');
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
            // リモートに存在する場合は、同期更新時刻比較
            if (localGoal.syncUpdatedAt != null &&
                remoteGoal.syncUpdatedAt != null &&
                localGoal.syncUpdatedAt!.isAfter(remoteGoal.syncUpdatedAt!)) {
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
          } else if (remoteGoal.syncUpdatedAt != null &&
              localGoal.syncUpdatedAt != null &&
              remoteGoal.syncUpdatedAt!.isAfter(localGoal.syncUpdatedAt!)) {
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
          if (localGoal.syncUpdatedAt?.isAfter(lastSyncTime) ?? false) {
            final remoteGoal = await _remoteDatasource.getGoalById(
              localGoal.id,
            );

            if (remoteGoal == null) {
              await _remoteDatasource.createGoal(localGoal);
              AppLogger.instance.i('リモートに新規作成: ${localGoal.id}');
            } else if (localGoal.syncUpdatedAt != null &&
                remoteGoal.syncUpdatedAt != null &&
                localGoal.syncUpdatedAt!.isAfter(remoteGoal.syncUpdatedAt!)) {
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
          } else if (remoteGoal.syncUpdatedAt != null &&
              localGoal.syncUpdatedAt != null &&
              remoteGoal.syncUpdatedAt!.isAfter(localGoal.syncUpdatedAt!)) {
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

      // setSynced() 削除: 強制同期は手動実行時のみ通知（SyncCheckerで管理）

      AppLogger.instance.i('強制全件同期が完了しました');
    } catch (e) {
      AppLogger.instance.e('強制全件同期に失敗しました', e);
      _syncNotifier.setError(e.toString());
    }
  }
}
