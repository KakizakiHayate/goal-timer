import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:goal_timer/core/data/datasources/local/daily_study_logs/local_daily_study_logs_datasource.dart';
import 'package:goal_timer/core/data/datasources/supabase/daily_study_logs/supabase_daily_study_logs_datasource.dart';
import 'package:goal_timer/core/data/repositories/daily_study_logs/daily_study_logs_repository.dart';
import 'package:goal_timer/core/models/daily_study_logs/daily_study_log_model.dart';
import 'package:goal_timer/core/provider/sync_state_provider.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class HybridDailyStudyLogsRepository implements DailyStudyLogsRepository {
  final LocalDailyStudyLogsDatasource _localDatasource;
  final SupabaseDailyStudyLogsDatasource _remoteDatasource;
  final SyncStateNotifier _syncNotifier;
  final Connectivity _connectivity;

  HybridDailyStudyLogsRepository({
    required LocalDailyStudyLogsDatasource localDatasource,
    required SupabaseDailyStudyLogsDatasource remoteDatasource,
    required SyncStateNotifier syncNotifier,
    Connectivity? connectivity,
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _syncNotifier = syncNotifier,
       _connectivity = connectivity ?? Connectivity();

  @override
  Future<List<DailyStudyLogModel>> getAllLogs() async {
    try {
      // ローカルDBからデータを取得のみ（自動同期は削除）
      final localLogs = await _localDatasource.getAllLogs();

      // ネットワーク接続状態のみ確認（同期は実行しない）
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      }

      return localLogs;
    } catch (e) {
      AppLogger.instance.e('学習記録データの取得に失敗しました', e);
      _syncNotifier.setError(e.toString());
      return [];
    }
  }

  @override
  Future<List<DailyStudyLogModel>> getDailyLogs(DateTime date) async {
    try {
      // ローカルDBからデータを取得のみ（自動同期は削除）
      final localLogs = await _localDatasource.getDailyLogs(date);

      // ネットワーク接続状態のみ確認（同期は実行しない）
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      }

      return localLogs;
    } catch (e) {
      AppLogger.instance.e('日付別学習記録データの取得に失敗しました', e);
      _syncNotifier.setError(e.toString());
      return [];
    }
  }

  @override
  Future<List<DailyStudyLogModel>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // ローカルDBからデータを取得のみ（自動同期は削除）
      final localLogs = await _localDatasource.getLogsByDateRange(
        startDate,
        endDate,
      );

      // ネットワーク接続状態のみ確認（同期は実行しない）
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      }

      return localLogs;
    } catch (e) {
      AppLogger.instance.e('期間別学習記録データの取得に失敗しました', e);
      _syncNotifier.setError(e.toString());
      return [];
    }
  }

  @override
  Future<List<DailyStudyLogModel>> getLogsByGoalId(String goalId) async {
    try {
      // ローカルDBからデータを取得のみ（自動同期は削除）
      final localLogs = await _localDatasource.getLogsByGoalId(goalId);

      // ネットワーク接続状態のみ確認（同期は実行しない）
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      }

      return localLogs;
    } catch (e) {
      AppLogger.instance.e('目標別学習記録データの取得に失敗しました', e);
      _syncNotifier.setError(e.toString());
      return [];
    }
  }

  @override
  Future<DailyStudyLogModel?> getLogById(String id) async {
    try {
      // まずローカルDBから検索
      final localLog = await _localDatasource.getLogById(id);

      // ローカルに存在する場合はそれを返す
      if (localLog != null) {
        return localLog;
      }

      // ローカルに存在しない場合、ネットワーク接続があればリモートから取得
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final remoteLog = await _remoteDatasource.getLogById(id);

        // リモートから取得できた場合はローカルに保存
        if (remoteLog != null) {
          await _localDatasource.upsertDailyLog(remoteLog);
          await _localDatasource.markAsSynced(remoteLog.id);
          return remoteLog;
        }
      } else {
        _syncNotifier.setOffline();
      }

      // 見つからない場合はnullを返す
      return null;
    } catch (e) {
      AppLogger.instance.e('学習記録データの取得に失敗しました: $id', e);
      _syncNotifier.setError(e.toString());
      return null;
    }
  }

  @override
  Future<DailyStudyLogModel> upsertDailyLog(DailyStudyLogModel log) async {
    try {
      // 1. ローカルDBに保存
      final localLog = await _localDatasource.upsertDailyLog(log);

      // 2. ネットワーク接続があればSupabaseにも保存
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          // ローカルDBから最新のデータを取得（仮ユーザー情報を含む）
          final latestLocalLog = await _localDatasource.getLogById(localLog.id);
          if (latestLocalLog != null) {
            // 仮ユーザー情報が設定されている場合は、Supabase用に仮ユーザー情報を追加
            DailyStudyLogModel logToSync = latestLocalLog;
            if (latestLocalLog.isTemp || latestLocalLog.tempUserId != null) {
              logToSync = latestLocalLog.copyWith(
                isTemp: true,
                tempUserId:
                    latestLocalLog.tempUserId ??
                    'local_user_temp_${DateTime.now().millisecondsSinceEpoch}',
              );
            }

            // Supabaseに同期
            await _remoteDatasource.upsertDailyLog(logToSync);
          } else {
            // fallback: 元のlogを使用
            await _remoteDatasource.upsertDailyLog(log);
          }

          // 同期成功したらフラグを更新
          final syncedLog = localLog.copyWith(isSynced: true);
          await _localDatasource.upsertDailyLog(syncedLog);
          await _localDatasource.markAsSynced(localLog.id);

          _syncNotifier.setSynced();
          AppLogger.instance.i('学習記録をSupabaseに同期しました');
        } catch (e) {
          // リモート保存失敗してもローカルは保持
          print('保存が必要');
          _syncNotifier.setUnsynced();
          AppLogger.instance.w('Supabase同期失敗（後で再試行）: $e');
          print('保存が必要2');
        }
      } else {
        _syncNotifier.setOffline();
        AppLogger.instance.i('オフラインのためローカルのみに保存');
      }

      return localLog;
    } catch (e) {
      AppLogger.instance.e('学習記録の保存に失敗', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  @override
  Future<bool> deleteDailyLog(String id) async {
    try {
      // ローカルDBからのみ削除（リアルタイム同期は削除）
      final success = await _localDatasource.deleteDailyLog(id);

      if (!success) {
        return false;
      }

      // ネットワーク接続状態を確認して未同期状態を設定
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncNotifier.setOffline();
      } else {
        _syncNotifier.setUnsynced(); // 未同期データありとして記録
      }

      AppLogger.instance.i('学習記録をローカルから削除しました（手動同期が必要）: $id');
      return true;
    } catch (e) {
      AppLogger.instance.e('学習記録の削除に失敗しました: $id', e);
      _syncNotifier.setError(e.toString());
      return false;
    }
  }

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
      final unsyncedLogs = await _localDatasource.getUnsyncedLogs();
      for (final localLog in unsyncedLogs) {
        try {
          // リモートに存在するか確認
          final remoteLog = await _remoteDatasource.getLogById(localLog.id);

          if (remoteLog == null) {
            // リモートに存在しない場合は新規作成
            await _remoteDatasource.createDailyLog(localLog);
          } else {
            // syncUpdatedAtで比較して更新が必要かチェック
            if (localLog.syncUpdatedAt != null &&
                remoteLog.syncUpdatedAt != null &&
                localLog.syncUpdatedAt!.isAfter(remoteLog.syncUpdatedAt!)) {
              // ローカルの方が新しい場合は更新
              await _remoteDatasource.updateDailyLog(localLog);
            }
          }

          // 同期済みとしてマーク
          await _localDatasource.markAsSynced(localLog.id);
        } catch (e) {
          AppLogger.instance.e('リモートへの同期に失敗しました: ${localLog.id}', e);
          // 個別の失敗は全体の失敗とはせず、続行
        }
      }

      // 2. リモートの新しいデータをローカルに反映
      final remoteLogs = await _remoteDatasource.getAllLogs();
      for (final remoteLog in remoteLogs) {
        try {
          // ローカルに存在するか確認
          final localLog = await _localDatasource.getLogById(remoteLog.id);

          if (localLog == null) {
            // ローカルに存在しない場合は新規作成
            final syncedLog = remoteLog.copyWith(isSynced: true);
            await _localDatasource.upsertDailyLog(syncedLog);
          } else if (remoteLog.syncUpdatedAt != null &&
              localLog.syncUpdatedAt != null &&
              remoteLog.syncUpdatedAt!.isAfter(localLog.syncUpdatedAt!)) {
            // リモートの方が新しい場合は更新
            final syncedLog = remoteLog.copyWith(isSynced: true);
            await _localDatasource.upsertDailyLog(syncedLog);
          }
        } catch (e) {
          AppLogger.instance.e('ローカルへの同期に失敗しました: ${remoteLog.id}', e);
          // 個別の失敗は全体の失敗とはせず、続行
        }
      }

      // setSynced() 削除: SyncCheckerが一元管理するため
      AppLogger.instance.i('学習ログの差分同期が完了しました');
    } catch (e) {
      AppLogger.instance.e('同期処理に失敗しました', e);
      _syncNotifier.setError(e.toString());
    }
  }

  /// 未同期データの有無をチェック（SyncChecker用）
  Future<bool> hasUnsyncedData() async {
    try {
      final unsyncedLogs = await _localDatasource.getUnsyncedLogs();
      return unsyncedLogs.isNotEmpty;
    } catch (e) {
      AppLogger.instance.e('未同期データチェックエラー', e);
      return false;
    }
  }
}
