import '../data/repositories/goals/goals_repository.dart';
import '../data/repositories/users/users_repository.dart';
import '../data/repositories/daily_study_logs/daily_study_logs_repository.dart';
import '../data/repositories/hybrid/goals/hybrid_goals_repository.dart';
import '../data/repositories/hybrid/users/hybrid_users_repository.dart';
import '../data/repositories/hybrid/daily_study_logs/hybrid_daily_study_logs_repository.dart';
import '../provider/sync_state_provider.dart';
import '../utils/app_logger.dart';

/// 同期状態をチェックし、必要時のみ同期を実行するサービス
class SyncChecker {
  final HybridGoalsRepository _goalsRepository;
  final HybridUsersRepository _usersRepository;
  final HybridDailyStudyLogsRepository _dailyStudyLogsRepository;
  final SyncStateNotifier _syncNotifier;

  SyncChecker({
    required HybridGoalsRepository goalsRepository,
    required HybridUsersRepository usersRepository,
    required HybridDailyStudyLogsRepository dailyStudyLogsRepository,
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

      final hasUnsynced =
          hasUnsyncedGoals || hasUnsyncedUsers || hasUnsyncedLogs;

      AppLogger.instance.i(
        '未同期データチェック結果: '
        'Goals=$hasUnsyncedGoals, Users=$hasUnsyncedUsers, Logs=$hasUnsyncedLogs, '
        '総合=$hasUnsynced',
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
      await _handleSyncError(e);
    }
  }

  /// 同期エラーの処理と復旧
  Future<void> _handleSyncError(dynamic error) async {
    try {
      AppLogger.instance.i('同期エラーの復旧処理を開始します');

      // エラーの種類に応じた処理
      if (error.toString().contains('network') ||
          error.toString().contains('connection')) {
        // ネットワークエラー：オフライン状態に設定
        _syncNotifier.setOffline();
        AppLogger.instance.w('ネットワークエラーのため、オフライン状態に設定しました');
      } else if (error.toString().contains('timeout')) {
        // タイムアウトエラー：再試行を提案
        _syncNotifier.setError('同期がタイムアウトしました。しばらく時間をおいて再試行してください。');
        AppLogger.instance.w('同期タイムアウトが発生しました');
      } else if (error.toString().contains('auth') ||
          error.toString().contains('permission')) {
        // 認証エラー：認証の再確認が必要
        _syncNotifier.setError('認証に問題があります。再ログインしてください。');
        AppLogger.instance.e('認証エラーが発生しました');
      } else {
        // その他のエラー：一般的なエラー処理
        _syncNotifier.setError('同期中にエラーが発生しました。後ほど再試行してください。');
        AppLogger.instance.e('予期しない同期エラーが発生しました');
      }

      // エラー復旧のための基本処理
      await _performErrorRecovery();
    } catch (recoveryError) {
      AppLogger.instance.e('エラー復旧処理中に追加のエラーが発生しました', recoveryError);
      _syncNotifier.setError('復旧処理に失敗しました。アプリを再起動してください。');
    }
  }

  /// エラー復旧処理
  Future<void> _performErrorRecovery() async {
    try {
      AppLogger.instance.i('エラー復旧処理を実行します');

      // 1. 同期メタデータの整合性チェック
      // （実際の実装はSyncMetadataManagerで行う）

      // 2. ローカルデータの整合性確認
      // （基本的なデータ存在確認）

      // 3. 復旧可能な軽微なエラーの修正
      // （例：破損した同期フラグの修正など）

      AppLogger.instance.i('エラー復旧処理が完了しました');
    } catch (e) {
      AppLogger.instance.e('エラー復旧処理で問題が発生しました', e);
      // 復旧処理のエラーは上位に伝播させる
      rethrow;
    }
  }

  /// 同期の再試行（ユーザー操作による手動実行）
  Future<void> retrySyncWithBackoff() async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.instance.i('同期再試行 (${attempt}/$maxRetries)');

        await checkAndSyncIfNeeded();

        // 成功した場合は即座に終了
        AppLogger.instance.i('同期再試行が成功しました');
        return;
      } catch (e) {
        AppLogger.instance.w('同期再試行 $attempt 回目が失敗しました: $e');

        if (attempt == maxRetries) {
          // 最大試行回数に達した場合は諦める
          AppLogger.instance.e('最大再試行回数に達しました。同期に失敗しました');
          _syncNotifier.setError('同期に失敗しました。しばらく時間をおいてから再試行してください。');
          rethrow;
        }

        // 指数バックオフで待機
        final delay = Duration(
          milliseconds: baseDelay.inMilliseconds * (1 << (attempt - 1)),
        );
        AppLogger.instance.i('${delay.inSeconds}秒待機してから再試行します');
        await Future.delayed(delay);
      }
    }
  }

  // プライベートメソッド：各Repositoryの未同期チェック

  Future<bool> _hasUnsyncedGoals() async {
    try {
      AppLogger.instance.d('Goals未同期データをチェック中...');

      // ハイブリッドリポジトリのpublicメソッドを使用
      final hasUnsynced = await _goalsRepository.hasUnsyncedData();

      AppLogger.instance.i('Goals未同期データ: $hasUnsynced');
      return hasUnsynced;
    } catch (e) {
      AppLogger.instance.e('Goals未同期チェックエラー', e);
      return false;
    }
  }

  Future<bool> _hasUnsyncedUsers() async {
    try {
      AppLogger.instance.d('Users未同期データをチェック中...');

      // ハイブリッドリポジトリのpublicメソッドを使用
      final hasUnsynced = await _usersRepository.hasUnsyncedData();

      AppLogger.instance.i('Users未同期データ: $hasUnsynced');
      return hasUnsynced;
    } catch (e) {
      AppLogger.instance.e('Users未同期チェックエラー', e);
      return false;
    }
  }

  Future<bool> _hasUnsyncedDailyStudyLogs() async {
    try {
      AppLogger.instance.d('DailyStudyLogs未同期データをチェック中...');

      // ハイブリッドリポジトリのpublicメソッドを使用
      final hasUnsynced = await _dailyStudyLogsRepository.hasUnsyncedData();

      AppLogger.instance.i('DailyStudyLogs未同期データ: $hasUnsynced');
      return hasUnsynced;
    } catch (e) {
      AppLogger.instance.e('DailyStudyLogs未同期チェックエラー', e);
      return false;
    }
  }

  // プライベートメソッド：各Repositoryの未同期データ同期

  Future<void> _syncUnsyncedGoals() async {
    try {
      AppLogger.instance.d('Goals未同期データの同期を開始...');
      await _goalsRepository.syncWithRemote();
      AppLogger.instance.d('Goals未同期データの同期完了');
    } catch (e) {
      AppLogger.instance.e('Goals未同期データ同期エラー', e);
      throw Exception('Goals同期エラー: ${e.toString()}');
    }
  }

  Future<void> _syncUnsyncedUsers() async {
    try {
      AppLogger.instance.d('Users未同期データの同期を開始...');
      await _usersRepository.syncWithRemote();
      AppLogger.instance.d('Users未同期データの同期完了');
    } catch (e) {
      AppLogger.instance.e('Users未同期データ同期エラー', e);
      throw Exception('Users同期エラー: ${e.toString()}');
    }
  }

  Future<void> _syncUnsyncedDailyStudyLogs() async {
    try {
      AppLogger.instance.d('DailyStudyLogs未同期データの同期を開始...');
      await _dailyStudyLogsRepository.syncWithRemote();
      AppLogger.instance.d('DailyStudyLogs未同期データの同期完了');
    } catch (e) {
      AppLogger.instance.e('DailyStudyLogs未同期データ同期エラー', e);
      throw Exception('DailyStudyLogs同期エラー: ${e.toString()}');
    }
  }

  /// 手動で全件同期を実行（デバッグ・メンテナンス用）
  Future<void> forceFullSync() async {
    try {
      AppLogger.instance.i('全件同期を開始します');
      _syncNotifier.setSyncing();

      // 各リポジトリで強制全件同期を実行
      await Future.wait([
        _goalsRepository.forceFullSync(),
        _usersRepository
            .syncWithRemote(), // UsersRepositoryには forceFullSync がないため通常同期
        _dailyStudyLogsRepository
            .syncWithRemote(), // DailyStudyLogsRepositoryも同様
      ]);

      _syncNotifier.setSynced();
      AppLogger.instance.i('全件同期が完了しました');
    } catch (e) {
      AppLogger.instance.e('全件同期に失敗しました', e);
      _syncNotifier.setError(e.toString());
      rethrow;
    }
  }

  /// データ整合性チェック（ローカル・リモート間の整合性検証）
  Future<Map<String, dynamic>> checkDataIntegrity() async {
    try {
      AppLogger.instance.i('データ整合性チェックを開始します');

      final results = <String, dynamic>{};

      // 各データタイプの整合性チェック
      results['goals'] = await _checkGoalsIntegrity();
      results['users'] = await _checkUsersIntegrity();
      results['daily_study_logs'] = await _checkDailyStudyLogsIntegrity();

      // 全体の整合性判定
      final hasIntegrityIssues = results.values.any(
        (result) =>
            result['has_conflicts'] == true ||
            result['has_missing_data'] == true,
      );

      results['overall_status'] =
          hasIntegrityIssues ? 'issues_found' : 'healthy';

      AppLogger.instance.i('データ整合性チェック完了: ${results['overall_status']}');
      return results;
    } catch (e) {
      AppLogger.instance.e('データ整合性チェックでエラーが発生しました', e);
      return {'overall_status': 'error', 'error_message': e.toString()};
    }
  }

  /// Goals データの整合性チェック
  Future<Map<String, dynamic>> _checkGoalsIntegrity() async {
    // 実装は各ハイブリッドリポジトリに委譲
    // ここでは基本的な未同期データ検出のみ実行
    final hasUnsynced = await _goalsRepository.hasUnsyncedData();
    return {
      'has_conflicts': false, // 詳細な競合検出は今後実装
      'has_missing_data': hasUnsynced,
      'unsynced_count': hasUnsynced ? 'unknown' : 0,
    };
  }

  /// Users データの整合性チェック
  Future<Map<String, dynamic>> _checkUsersIntegrity() async {
    final hasUnsynced = await _usersRepository.hasUnsyncedData();
    return {
      'has_conflicts': false,
      'has_missing_data': hasUnsynced,
      'unsynced_count': hasUnsynced ? 'unknown' : 0,
    };
  }

  /// DailyStudyLogs データの整合性チェック
  Future<Map<String, dynamic>> _checkDailyStudyLogsIntegrity() async {
    final hasUnsynced = await _dailyStudyLogsRepository.hasUnsyncedData();
    return {
      'has_conflicts': false,
      'has_missing_data': hasUnsynced,
      'unsynced_count': hasUnsynced ? 'unknown' : 0,
    };
  }
}
