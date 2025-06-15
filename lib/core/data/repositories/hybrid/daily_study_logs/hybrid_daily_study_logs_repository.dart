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
      // まずローカルDBからデータを取得
      final localLogs = await _localDatasource.getAllLogs();

      // ネットワーク接続がある場合は同期を試みる
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // バックグラウンドで同期を開始
        syncWithRemote();
      } else {
        // オフラインモードを通知
        _syncNotifier.setOffline();
      }

      return localLogs;
    } catch (e) {
      AppLogger.instance.e('学習記録データの取得に失敗しました', e);
      // エラー通知
      _syncNotifier.setError(e.toString());
      return [];
    }
  }

  @override
  Future<List<DailyStudyLogModel>> getDailyLogs(DateTime date) async {
    try {
      // まずローカルDBからデータを取得
      final localLogs = await _localDatasource.getDailyLogs(date);

      // ネットワーク接続がある場合は同期を試みる
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // バックグラウンドで同期を開始
        syncWithRemote();
      } else {
        // オフラインモードを通知
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
      // まずローカルDBからデータを取得
      final localLogs = await _localDatasource.getLogsByDateRange(
        startDate,
        endDate,
      );

      // ネットワーク接続がある場合は同期を試みる
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // バックグラウンドで同期を開始
        syncWithRemote();
      } else {
        // オフラインモードを通知
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
      // まずローカルDBからデータを取得
      final localLogs = await _localDatasource.getLogsByGoalId(goalId);

      // ネットワーク接続がある場合は同期を試みる
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // バックグラウンドで同期を開始
        syncWithRemote();
      } else {
        // オフラインモードを通知
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
      // まずローカルDBに保存
      final localLog = await _localDatasource.upsertDailyLog(log);

      // ネットワーク接続がある場合はリモートにも保存
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          // リモートに保存
          final remoteLog = await _remoteDatasource.upsertDailyLog(localLog);

          // 同期済みとしてマーク
          await _localDatasource.markAsSynced(remoteLog.id);

          // 同期成功を通知
          _syncNotifier.setSynced();

          return remoteLog;
        } catch (e) {
          // リモート保存に失敗しても、ローカル保存は成功しているのでエラーにはしない
          AppLogger.instance.e('リモートへの学習記録保存に失敗しました', e);
          _syncNotifier.setUnsynced();
        }
      } else {
        _syncNotifier.setOffline();
      }

      return localLog;
    } catch (e) {
      AppLogger.instance.e('学習記録の作成に失敗しました', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  @override
  Future<bool> deleteDailyLog(String id) async {
    try {
      // まずローカルDBから削除
      final success = await _localDatasource.deleteDailyLog(id);

      if (!success) {
        return false;
      }

      // ネットワーク接続がある場合はリモートからも削除
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          // リモートから削除
          await _remoteDatasource.deleteDailyLog(id);

          // 同期成功を通知
          _syncNotifier.setSynced();
        } catch (e) {
          // リモート削除に失敗しても、ローカル削除は成功しているのでエラーにはしない
          AppLogger.instance.e('リモートでの学習記録削除に失敗しました', e);
          _syncNotifier.setUnsynced();
        }
      } else {
        _syncNotifier.setOffline();
      }

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
            // リモートに存在する場合は更新
            await _remoteDatasource.updateDailyLog(localLog);
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
            await _localDatasource.upsertDailyLog(remoteLog);
            await _localDatasource.markAsSynced(remoteLog.id);
          }
          // ローカルに存在する場合は何もしない（ローカルの変更が優先）
        } catch (e) {
          AppLogger.instance.e('ローカルへの同期に失敗しました: ${remoteLog.id}', e);
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
}
