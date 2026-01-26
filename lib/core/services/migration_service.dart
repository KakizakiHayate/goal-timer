import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/local_goals_datasource.dart';
import '../data/local/local_study_daily_logs_datasource.dart';
import '../data/supabase/supabase_goals_datasource.dart';
import '../data/supabase/supabase_study_logs_datasource.dart';
import '../utils/app_logger.dart';
import 'firebase_service.dart';

/// ローカルデータをSupabaseに移行するサービス
class MigrationService {
  final LocalGoalsDatasource _localGoalsDatasource;
  final LocalStudyDailyLogsDatasource _localStudyLogsDatasource;
  final SupabaseGoalsDatasource _supabaseGoalsDatasource;
  final SupabaseStudyLogsDatasource _supabaseStudyLogsDatasource;
  final FirebaseService _firebaseService;

  /// SharedPreferencesのキー: 移行済みフラグ
  static const String _keyIsMigrated = 'is_migrated_to_supabase';

  MigrationService({
    required LocalGoalsDatasource localGoalsDatasource,
    required LocalStudyDailyLogsDatasource localStudyLogsDatasource,
    required SupabaseGoalsDatasource supabaseGoalsDatasource,
    required SupabaseStudyLogsDatasource supabaseStudyLogsDatasource,
    FirebaseService? firebaseService,
  })  : _localGoalsDatasource = localGoalsDatasource,
        _localStudyLogsDatasource = localStudyLogsDatasource,
        _supabaseGoalsDatasource = supabaseGoalsDatasource,
        _supabaseStudyLogsDatasource = supabaseStudyLogsDatasource,
        _firebaseService = firebaseService ?? FirebaseService();

  /// 移行済みかどうかを確認
  Future<bool> isMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsMigrated) ?? false;
  }

  /// 移行済みフラグを設定
  Future<void> _setMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsMigrated, true);
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

  /// データ移行を実行し、結果をログ出力する
  ///
  /// [userId] SupabaseユーザーID
  /// 移行失敗時も例外をthrowせず、ローカルデータで継続使用可能
  /// ViewModelから呼び出す共通メソッド
  Future<void> migrateAndLogResult(String userId) async {
    try {
      final result = await migrate(userId);

      if (result.migrationFailed) {
        // 移行失敗時もログのみ、例外はthrowしない
        AppLogger.instance.w(
          'データ移行に失敗しましたが、ローカルデータで継続します: ${result.message}',
        );
      } else if (result.skipped) {
        AppLogger.instance.i('データ移行: ${result.message}');
      } else {
        AppLogger.instance.i(
          'データ移行成功: 目標${result.goalCount}件、ログ${result.studyLogCount}件',
        );
      }
      // 例外をthrowしない。常にホーム画面へ遷移
    } catch (error, stackTrace) {
      // 予期せぬエラーの場合もログのみ
      AppLogger.instance.e('データ移行で予期せぬエラー', error, stackTrace);
      // rethrowしない → ホーム画面へ遷移を継続
    }
  }

  /// ローカルデータをSupabaseに移行
  ///
  /// [userId] SupabaseユーザーID
  /// 移行失敗時もsuccess: trueを返し、ユーザーはローカルデータで継続使用可能
  Future<MigrationResult> migrate(String userId) async {
    AppLogger.instance.i('データ移行を開始します: userId=$userId');

    try {
      // 移行済みの場合はスキップ
      if (await isMigrated()) {
        AppLogger.instance.i('既に移行済みのためスキップします');
        await _firebaseService.logMigrationSkipped(
          userId: userId,
          reason: 'already_migrated',
        );
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
        await _firebaseService.logMigrationSkipped(
          userId: userId,
          reason: 'no_local_data',
        );
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

      // マイグレーション完了イベントを送信
      await _firebaseService.logMigrationCompleted(
        userId: userId,
        goalCount: goalCount,
        studyLogCount: logCount,
      );

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

      // Crashlyticsにエラーとデータを送信（運営が手動移行できるように）
      await _sendErrorToCrashlytics(
        error: error,
        stackTrace: stackTrace,
        userId: userId,
      );

      // マイグレーション失敗イベントを送信
      await _firebaseService.logMigrationFailed(
        userId: userId,
        errorMessage: error.toString(),
      );

      // 失敗しても success: true を返し、ユーザーはアプリを継続使用可能
      // is_migrated_to_supabase フラグは設定しない（再試行可能にする）
      return MigrationResult(
        success: true,
        skipped: false,
        message: 'データ移行に失敗しましたが、ローカルデータで継続できます',
        migrationFailed: true,
        error: error,
      );
    }
  }

  /// Crashlyticsにエラーとマイグレーションデータを送信
  Future<void> _sendErrorToCrashlytics({
    required Object error,
    required StackTrace stackTrace,
    required String userId,
  }) async {
    try {
      // ローカルデータを取得
      final goals = await _localGoalsDatasource.fetchAllGoalsIncludingDeleted();
      final studyLogs = await _localStudyLogsDatasource.fetchAllLogs();

      // JSONに変換
      final goalsJson = goals.map((g) => g.toJson()).toList();
      final logsJson = studyLogs.map((l) => l.toJson()).toList();

      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Data migration failed',
        information: [
          'userId: $userId',
          'goalCount: ${goals.length}',
          'studyLogCount: ${studyLogs.length}',
          'goals: ${jsonEncode(goalsJson)}',
          'studyLogs: ${jsonEncode(logsJson)}',
        ],
      );

      AppLogger.instance.i('Crashlyticsにエラーとデータを送信しました');
    } catch (e, st) {
      AppLogger.instance.e('Crashlytics送信に失敗しました', e, st);
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
    await prefs.remove(_keyIsMigrated);
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

  /// 移行が失敗したかどうか（success: trueでもmigrationFailed: trueの場合がある）
  final bool migrationFailed;

  const MigrationResult({
    required this.success,
    required this.skipped,
    required this.message,
    this.goalCount = 0,
    this.studyLogCount = 0,
    this.error,
    this.migrationFailed = false,
  });
}
