import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/study_daily_logs/study_daily_logs_model.dart';
import '../../services/migration_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/streak_consts.dart';
import '../../utils/time_utils.dart';
import '../local/app_database.dart';
import '../local/local_goals_datasource.dart';
import '../local/local_study_daily_logs_datasource.dart';
import '../supabase/supabase_goals_datasource.dart';
import '../supabase/supabase_study_logs_datasource.dart';

/// 学習ログデータのRepository
///
/// マイグレーションフラグに基づいてローカル/Supabaseを振り分ける。
/// - マイグレーション済み: Supabaseを使用
/// - マイグレーション未済: ローカルDBを使用
class StudyLogsRepository {
  final LocalStudyDailyLogsDatasource _localDs;
  final SupabaseStudyLogsDatasource _supabaseDs;
  final MigrationService _migrationService;

  StudyLogsRepository({
    LocalStudyDailyLogsDatasource? localDs,
    SupabaseStudyLogsDatasource? supabaseDs,
    MigrationService? migrationService,
  })  : _localDs = localDs ??
            LocalStudyDailyLogsDatasource(database: AppDatabase()),
        _supabaseDs = supabaseDs ??
            SupabaseStudyLogsDatasource(supabase: Supabase.instance.client),
        _migrationService =
            migrationService ?? _createDefaultMigrationService();

  /// デフォルトのMigrationServiceを作成
  static MigrationService _createDefaultMigrationService() {
    final database = AppDatabase();
    final supabase = Supabase.instance.client;

    return MigrationService(
      localGoalsDatasource: LocalGoalsDatasource(database: database),
      localStudyLogsDatasource:
          LocalStudyDailyLogsDatasource(database: database),
      supabaseGoalsDatasource: SupabaseGoalsDatasource(supabase: supabase),
      supabaseStudyLogsDatasource:
          SupabaseStudyLogsDatasource(supabase: supabase),
    );
  }

  /// テスト用コンストラクタ
  ///
  /// 全ての依存関係を明示的に注入できる
  StudyLogsRepository.withDependencies({
    required LocalStudyDailyLogsDatasource localDs,
    required SupabaseStudyLogsDatasource supabaseDs,
    required MigrationService migrationService,
  })  : _localDs = localDs,
        _supabaseDs = supabaseDs,
        _migrationService = migrationService;

  /// 全ての学習ログを取得
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<List<StudyDailyLogsModel>> fetchAllLogs(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから学習ログを取得します');
      return _supabaseDs.fetchAllLogs(userId);
    } else {
      AppLogger.instance.i('ローカルDBから学習ログを取得します');
      return _localDs.fetchAllLogs();
    }
  }

  /// 特定の目標の学習ログを取得
  ///
  /// [goalId] 目標ID
  Future<List<StudyDailyLogsModel>> fetchLogsByGoalId(String goalId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから目標別学習ログを取得します');
      return _supabaseDs.fetchLogsByGoalId(goalId);
    } else {
      AppLogger.instance.i('ローカルDBから目標別学習ログを取得します');
      return _localDs.fetchLogsByGoalId(goalId);
    }
  }

  /// 目標ごとの学習時間合計（秒）を取得
  ///
  /// [goalId] 目標ID
  Future<int> fetchTotalSecondsByGoalId(String goalId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから目標別学習時間を計算します');
      final logs = await _supabaseDs.fetchLogsByGoalId(goalId);
      return logs.fold<int>(0, (sum, log) => sum + log.totalSeconds);
    } else {
      AppLogger.instance.i('ローカルDBから目標別学習時間を取得します');
      return _localDs.fetchTotalSecondsByGoalId(goalId);
    }
  }

  /// 全目標の学習時間合計をまとめて取得
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  /// `Map<goalId, totalSeconds>`の形式で返す
  Future<Map<String, int>> fetchTotalSecondsForAllGoals(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから全目標の学習時間を計算します');
      final logs = await _supabaseDs.fetchAllLogs(userId);
      final Map<String, int> totals = {};
      for (final log in logs) {
        totals[log.goalId] = (totals[log.goalId] ?? 0) + log.totalSeconds;
      }
      return totals;
    } else {
      AppLogger.instance.i('ローカルDBから全目標の学習時間を取得します');
      return _localDs.fetchTotalSecondsForAllGoals();
    }
  }

  /// 学習ログを保存
  ///
  /// [log] 保存する学習ログモデル
  Future<StudyDailyLogsModel> upsertLog(StudyDailyLogsModel log) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseに学習ログを保存します: ${log.id}');
      return _supabaseDs.upsertLog(log);
    } else {
      AppLogger.instance.i('ローカルDBに学習ログを保存します: ${log.id}');
      await _localDs.saveLog(log);
      return log;
    }
  }

  /// 学習ログを削除
  ///
  /// [logId] 削除する学習ログのID
  Future<void> deleteLog(String logId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseの学習ログを削除します: $logId');
      await _supabaseDs.deleteLog(logId);
    } else {
      AppLogger.instance.i('ローカルDBの学習ログを削除します: $logId');
      await _localDs.deleteLog(logId);
    }
  }

  /// 特定の目標に紐づく学習ログをすべて削除
  ///
  /// [goalId] 目標ID
  Future<void> deleteLogsByGoalId(String goalId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseの目標別学習ログを削除します: $goalId');
      await _supabaseDs.deleteLogsByGoalId(goalId);
    } else {
      AppLogger.instance.i('ローカルDBの目標別学習ログを削除します: $goalId');
      await _localDs.deleteLogsByGoalId(goalId);
    }
  }

  /// 現在のストリーク（連続学習日数）を計算
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<int> calculateCurrentStreak(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから現在のストリークを計算します');
      return _calculateStreakFromLogs(await _supabaseDs.fetchAllLogs(userId));
    } else {
      AppLogger.instance.i('ローカルDBから現在のストリークを計算します');
      return _localDs.calculateCurrentStreak();
    }
  }

  /// 過去の全学習ログから最長連続日数を計算
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<int> calculateHistoricalLongestStreak(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから最長ストリークを計算します');
      return _calculateLongestStreakFromLogs(
          await _supabaseDs.fetchAllLogs(userId));
    } else {
      AppLogger.instance.i('ローカルDBから最長ストリークを計算します');
      return _localDs.calculateHistoricalLongestStreak();
    }
  }

  /// 指定期間内の学習日リストを取得（合計1分以上の日のみ）
  ///
  /// [startDate] 開始日
  /// [endDate] 終了日
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<List<DateTime>> fetchStudyDatesInRange({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから期間内の学習日を取得します');
      final logs = await _supabaseDs.fetchAllLogs(userId);
      return _filterStudyDatesInRange(logs, startDate, endDate);
    } else {
      AppLogger.instance.i('ローカルDBから期間内の学習日を取得します');
      return _localDs.fetchStudyDatesInRange(
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  /// 最初の学習記録日を取得
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<DateTime?> fetchFirstStudyDate(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから最初の学習日を取得します');
      final logs = await _supabaseDs.fetchAllLogs(userId);
      if (logs.isEmpty) return null;
      return logs
          .map((log) => log.studyDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);
    } else {
      AppLogger.instance.i('ローカルDBから最初の学習日を取得します');
      return _localDs.fetchFirstStudyDate();
    }
  }

  /// 指定日の目標別学習時間を取得
  ///
  /// [date] 対象日
  /// [userId] ユーザーID（Supabase使用時に必要）
  /// `Map<goalId, totalSeconds>`の形式で返す
  Future<Map<String, int>> fetchDailyRecordsByDate(
    DateTime date,
    String userId,
  ) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから日別学習記録を取得します');
      final logs = await _supabaseDs.fetchAllLogs(userId);
      return _aggregateDailyRecords(logs, date);
    } else {
      AppLogger.instance.i('ローカルDBから日別学習記録を取得します');
      return _localDs.fetchDailyRecordsByDate(date);
    }
  }

  // ============================================
  // プライベートヘルパーメソッド（Supabase用の計算ロジック）
  // ============================================

  /// ログリストから現在のストリークを計算
  int _calculateStreakFromLogs(List<StudyDailyLogsModel> logs) {
    if (logs.isEmpty) return 0;

    // 日付ごとの合計時間を集計
    final dailyTotals = <DateTime, int>{};
    for (final log in logs) {
      final dateOnly = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      dailyTotals[dateOnly] = (dailyTotals[dateOnly] ?? 0) + log.totalSeconds;
    }

    // 1分以上学習した日のみ抽出
    final studyDates = dailyTotals.entries
        .where((e) => e.value >= StreakConsts.minStudySeconds)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 降順

    if (studyDates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = 0;
    DateTime checkDate = today;

    // 今日学習したかチェック
    final isStudiedToday =
        studyDates.isNotEmpty && studyDates.first.isSameDay(today);

    if (!isStudiedToday) {
      final yesterday = today.subtract(const Duration(days: 1));
      final isStudiedYesterday =
          studyDates.isNotEmpty && studyDates.first.isSameDay(yesterday);

      if (!isStudiedYesterday) {
        return 0;
      }
      checkDate = yesterday;
    }

    for (final studyDate in studyDates) {
      if (studyDate.isSameDay(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }
      if (studyDate.isBefore(checkDate)) {
        break;
      }
    }

    return streak;
  }

  /// ログリストから最長ストリークを計算
  int _calculateLongestStreakFromLogs(List<StudyDailyLogsModel> logs) {
    if (logs.isEmpty) return 0;

    // 日付ごとの合計時間を集計
    final dailyTotals = <DateTime, int>{};
    for (final log in logs) {
      final dateOnly = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      dailyTotals[dateOnly] = (dailyTotals[dateOnly] ?? 0) + log.totalSeconds;
    }

    // 1分以上学習した日のみ抽出し、昇順でソート
    final studyDates = dailyTotals.entries
        .where((e) => e.value >= StreakConsts.minStudySeconds)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => a.compareTo(b)); // 昇順

    if (studyDates.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;

    for (var i = 1; i < studyDates.length; i++) {
      final previousDate = studyDates[i - 1];
      final currentDate = studyDates[i];

      final difference = currentDate.difference(previousDate).inDays;

      if (difference == 1) {
        currentStreak++;
        longestStreak = max(currentStreak, longestStreak);
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  /// ログリストから指定期間内の学習日をフィルタリング
  List<DateTime> _filterStudyDatesInRange(
    List<StudyDailyLogsModel> logs,
    DateTime startDate,
    DateTime endDate,
  ) {
    // 日付ごとの合計時間を集計
    final dailyTotals = <DateTime, int>{};
    for (final log in logs) {
      final dateOnly = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      dailyTotals[dateOnly] = (dailyTotals[dateOnly] ?? 0) + log.totalSeconds;
    }

    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    // 期間内で1分以上学習した日を抽出
    return dailyTotals.entries
        .where((e) =>
            e.value >= StreakConsts.minStudySeconds &&
            !e.key.isBefore(startOnly) &&
            !e.key.isAfter(endOnly))
        .map((e) => e.key)
        .toList()
      ..sort((a, b) => a.compareTo(b));
  }

  /// ログリストから指定日の目標別合計を集計
  Map<String, int> _aggregateDailyRecords(
    List<StudyDailyLogsModel> logs,
    DateTime date,
  ) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final Map<String, int> records = {};

    for (final log in logs) {
      final logDateOnly = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      if (logDateOnly.isSameDay(dateOnly)) {
        records[log.goalId] = (records[log.goalId] ?? 0) + log.totalSeconds;
      }
    }

    return records;
  }
}
