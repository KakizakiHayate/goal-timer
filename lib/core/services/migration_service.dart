import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/local_goals_datasource.dart';
import '../data/local/local_study_daily_logs_datasource.dart';
import '../data/local/local_users_datasource.dart';
import '../data/supabase/supabase_goals_datasource.dart';
import '../data/supabase/supabase_study_logs_datasource.dart';
import '../data/supabase/supabase_users_datasource.dart';
import '../utils/app_logger.dart';

/// ローカルデータをSupabaseに移行するサービス
class MigrationService {
  final LocalGoalsDatasource _localGoalsDatasource;
  final LocalStudyDailyLogsDatasource _localStudyLogsDatasource;
  final SupabaseGoalsDatasource _supabaseGoalsDatasource;
  final SupabaseStudyLogsDatasource _supabaseStudyLogsDatasource;

  /// SharedPreferencesのキー: 移行済みフラグ
  static const String _keyHasMigrated = 'has_migrated_to_supabase';

  MigrationService({
    required LocalGoalsDatasource localGoalsDatasource,
    required LocalStudyDailyLogsDatasource localStudyLogsDatasource,
    required LocalUsersDatasource localUsersDatasource,
    required SupabaseGoalsDatasource supabaseGoalsDatasource,
    required SupabaseStudyLogsDatasource supabaseStudyLogsDatasource,
    required SupabaseUsersDatasource supabaseUsersDatasource,
  })  : _localGoalsDatasource = localGoalsDatasource,
        _localStudyLogsDatasource = localStudyLogsDatasource,
        _supabaseGoalsDatasource = supabaseGoalsDatasource,
        _supabaseStudyLogsDatasource = supabaseStudyLogsDatasource;

  /// 移行済みかどうかを確認
  Future<bool> hasMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasMigrated) ?? false;
  }

  /// 移行済みフラグを設定
  Future<void> _setMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasMigrated, true);
    AppLogger.instance.i('移行済みフラグを設定しました');
  }

  /// ローカルデータがあるかどうかを確認
  Future<bool> hasLocalData() async {
    try {
      final goals = await _localGoalsDatasource.fetchAllGoalsIncludingDeleted();
      final logs = await _localStudyLogsDatasource.fetchAllLogs();

      return goals.isNotEmpty || logs.isNotEmpty;
    } catch (error, stackTrace) {
      AppLogger.instance.e('ローカルデータ確認に失敗しました', error, stackTrace);
      return false;
    }
  }

  /// 移行するデータ件数を取得
  Future<MigrationDataCount> getDataCount() async {
    try {
      final goals = await _localGoalsDatasource.fetchAllGoalsIncludingDeleted();
      final logs = await _localStudyLogsDatasource.fetchAllLogs();

      return MigrationDataCount(
        goalCount: goals.length,
        studyLogCount: logs.length,
      );
    } catch (error, stackTrace) {
      AppLogger.instance.e('データ件数取得に失敗しました', error, stackTrace);
      return const MigrationDataCount(goalCount: 0, studyLogCount: 0);
    }
  }

  /// ローカルデータをSupabaseに移行
  ///
  /// [userId] SupabaseユーザーID
  Future<MigrationResult> migrate(String userId) async {
    AppLogger.instance.i('データ移行を開始します: userId=$userId');

    try {
      // 移行済みの場合はスキップ
      if (await hasMigrated()) {
        AppLogger.instance.i('既に移行済みのためスキップします');
        return const MigrationResult(
          success: true,
          skipped: true,
          message: '既に移行済みです',
        );
      }

      // ローカルデータがない場合はスキップ
      if (!await hasLocalData()) {
        AppLogger.instance.i('ローカルデータがないためスキップします');
        await _setMigrated();
        return const MigrationResult(
          success: true,
          skipped: true,
          message: 'ローカルデータがありません',
        );
      }

      // 目標を移行
      final goalCount = await _migrateGoals(userId);
      AppLogger.instance.i('目標の移行完了: $goalCount件');

      // 学習ログを移行
      final logCount = await _migrateStudyLogs(userId);
      AppLogger.instance.i('学習ログの移行完了: $logCount件');

      // 移行済みフラグを設定
      await _setMigrated();

      AppLogger.instance.i('データ移行が完了しました');
      return MigrationResult(
        success: true,
        skipped: false,
        message: '移行完了: 目標$goalCount件、学習ログ$logCount件',
        goalCount: goalCount,
        studyLogCount: logCount,
      );
    } catch (error, stackTrace) {
      AppLogger.instance.e('データ移行に失敗しました', error, stackTrace);
      return MigrationResult(
        success: false,
        skipped: false,
        message: 'データ移行に失敗しました: $error',
        error: error,
      );
    }
  }

  /// 目標を移行
  Future<int> _migrateGoals(String userId) async {
    final localGoals =
        await _localGoalsDatasource.fetchAllGoalsIncludingDeleted();

    if (localGoals.isEmpty) {
      return 0;
    }

    // user_idを更新してSupabaseに挿入
    final goalsToMigrate = localGoals.map((goal) {
      return goal.copyWith(userId: userId);
    }).toList();

    await _supabaseGoalsDatasource.insertGoals(goalsToMigrate);

    return goalsToMigrate.length;
  }

  /// 学習ログを移行
  Future<int> _migrateStudyLogs(String userId) async {
    final localLogs = await _localStudyLogsDatasource.fetchAllLogs();

    if (localLogs.isEmpty) {
      return 0;
    }

    // user_idを更新してSupabaseに挿入
    final logsToMigrate = localLogs.map((log) {
      return log.copyWith(userId: userId);
    }).toList();

    await _supabaseStudyLogsDatasource.insertLogs(logsToMigrate);

    return logsToMigrate.length;
  }

  /// 移行をリセット（デバッグ用）
  Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHasMigrated);
    AppLogger.instance.i('移行フラグをリセットしました');
  }
}

/// 移行するデータの件数
class MigrationDataCount {
  final int goalCount;
  final int studyLogCount;

  const MigrationDataCount({
    required this.goalCount,
    required this.studyLogCount,
  });

  bool get hasData => goalCount > 0 || studyLogCount > 0;
}

/// 移行結果
class MigrationResult {
  final bool success;
  final bool skipped;
  final String message;
  final int goalCount;
  final int studyLogCount;
  final Object? error;

  const MigrationResult({
    required this.success,
    required this.skipped,
    required this.message,
    this.goalCount = 0,
    this.studyLogCount = 0,
    this.error,
  });
}
