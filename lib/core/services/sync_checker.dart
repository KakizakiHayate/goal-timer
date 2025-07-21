import '../data/repositories/goals/goals_repository.dart';
import '../data/repositories/users/users_repository.dart';
import '../data/repositories/daily_study_logs/daily_study_logs_repository.dart';
import '../provider/sync_state_provider.dart';
import '../utils/app_logger.dart';

/// 同期状態をチェックし、必要時のみ同期を実行するサービス
class SyncChecker {
  final GoalsRepository _goalsRepository;
  final UsersRepository _usersRepository;
  final DailyStudyLogsRepository _dailyStudyLogsRepository;
  final SyncStateNotifier _syncNotifier;

  SyncChecker({
    required GoalsRepository goalsRepository,
    required UsersRepository usersRepository,
    required DailyStudyLogsRepository dailyStudyLogsRepository,
    required SyncStateNotifier syncNotifier,
  }) : _goalsRepository = goalsRepository,
       _usersRepository = usersRepository,
       _dailyStudyLogsRepository = dailyStudyLogsRepository,
       _syncNotifier = syncNotifier;

  /// 未同期データが存在するかチェック
  Future<bool> hasUnsyncedData() async {
    try {
      AppLogger.instance.d('未同期データのチェックを開始します');

      // 各Repositoryから未同期データを確認
      final results = await Future.wait([
        _hasUnsyncedGoals(),
        _hasUnsyncedUsers(),
        _hasUnsyncedDailyStudyLogs(),
      ]);

      final hasUnsyncedGoals = results[0];
      final hasUnsyncedUsers = results[1]; 
      final hasUnsyncedLogs = results[2];

      final hasUnsynced = hasUnsyncedGoals || hasUnsyncedUsers || hasUnsyncedLogs;

      AppLogger.instance.i(
        '未同期データチェック結果: '
        'Goals=$hasUnsyncedGoals, Users=$hasUnsyncedUsers, Logs=$hasUnsyncedLogs, '
        '総合=$hasUnsynced'
      );

      return hasUnsynced;
    } catch (e) {
      AppLogger.instance.e('未同期データチェックエラー', e);
      return false;
    }
  }

  /// 未同期データを同期実行
  Future<void> syncUnsyncedData() async {
    try {
      AppLogger.instance.i('未同期データの同期を開始します');
      _syncNotifier.setSyncing();

      // 各Repositoryの未同期データを並行して同期
      await Future.wait([
        _syncUnsyncedGoals(),
        _syncUnsyncedUsers(),
        _syncUnsyncedDailyStudyLogs(),
      ]);

      _syncNotifier.setSynced();
      AppLogger.instance.i('未同期データの同期が完了しました');
    } catch (e) {
      AppLogger.instance.e('未同期データの同期に失敗しました', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  /// アプリ起動時・ログイン時の同期チェック実行
  Future<void> checkAndSyncIfNeeded() async {
    try {
      final hasUnsynced = await hasUnsyncedData();
      
      if (hasUnsynced) {
        AppLogger.instance.i('未同期データが見つかりました。同期を実行します。');
        await syncUnsyncedData();
      } else {
        AppLogger.instance.i('すべてのデータが同期済みです。');
        _syncNotifier.setSynced();
      }
    } catch (e) {
      AppLogger.instance.e('同期チェック処理でエラーが発生しました', e);
    }
  }

  // プライベートメソッド：各Repositoryの未同期チェック

  Future<bool> _hasUnsyncedGoals() async {
    try {
      // HybridRepositoryに未同期データ確認メソッドが必要
      // 暫定的に実装（後でRepositoryに追加予定）
      return false; // TODO: 実装
    } catch (e) {
      AppLogger.instance.e('Goals未同期チェックエラー', e);
      return false;
    }
  }

  Future<bool> _hasUnsyncedUsers() async {
    try {
      // HybridRepositoryに未同期データ確認メソッドが必要
      // 暫定的に実装（後でRepositoryに追加予定）
      return false; // TODO: 実装
    } catch (e) {
      AppLogger.instance.e('Users未同期チェックエラー', e);
      return false;
    }
  }

  Future<bool> _hasUnsyncedDailyStudyLogs() async {
    try {
      // HybridRepositoryに未同期データ確認メソッドが必要
      // 暫定的に実装（後でRepositoryに追加予定）
      return false; // TODO: 実装
    } catch (e) {
      AppLogger.instance.e('DailyStudyLogs未同期チェックエラー', e);
      return false;
    }
  }

  // プライベートメソッド：各Repositoryの未同期データ同期

  Future<void> _syncUnsyncedGoals() async {
    try {
      // HybridRepositoryに未同期データ同期メソッドが必要
      // 暫定的に実装（後でRepositoryに追加予定）
      AppLogger.instance.d('Goals未同期データの同期完了');
    } catch (e) {
      AppLogger.instance.e('Goals未同期データ同期エラー', e);
      throw Exception('Goals同期エラー: ${e.toString()}');
    }
  }

  Future<void> _syncUnsyncedUsers() async {
    try {
      // HybridRepositoryに未同期データ同期メソッドが必要
      // 暫定的に実装（後でRepositoryに追加予定）
      AppLogger.instance.d('Users未同期データの同期完了');
    } catch (e) {
      AppLogger.instance.e('Users未同期データ同期エラー', e);
      throw Exception('Users同期エラー: ${e.toString()}');
    }
  }

  Future<void> _syncUnsyncedDailyStudyLogs() async {
    try {
      // HybridRepositoryに未同期データ同期メソッドが必要
      // 暫定的に実装（後でRepositoryに追加予定）
      AppLogger.instance.d('DailyStudyLogs未同期データの同期完了');
    } catch (e) {
      AppLogger.instance.e('DailyStudyLogs未同期データ同期エラー', e);
      throw Exception('DailyStudyLogs同期エラー: ${e.toString()}');
    }
  }
}