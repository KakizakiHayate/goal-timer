import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/study_daily_logs/study_daily_logs_model.dart';
import '../../services/migration_service.dart';
import '../../utils/streak_consts.dart';
import '../local/app_database.dart';
import '../local/local_goals_datasource.dart';
import '../local/local_study_daily_logs_datasource.dart';
import '../supabase/supabase_goals_datasource.dart';
import '../supabase/supabase_study_logs_datasource.dart';

class StudyLogsRepository {
  late final LocalStudyDailyLogsDatasource _localDs;
  late final SupabaseStudyLogsDatasource _supabaseDs;
  late final MigrationService _migrationService;

  StudyLogsRepository({
    LocalStudyDailyLogsDatasource? localDs,
    SupabaseStudyLogsDatasource? supabaseDs,
    MigrationService? migrationService,
  }) {
    final database = AppDatabase();
    _localDs = localDs ?? LocalStudyDailyLogsDatasource(database: database);
    _supabaseDs = supabaseDs ??
        SupabaseStudyLogsDatasource(supabase: Supabase.instance.client);
    _migrationService = migrationService ??
        MigrationService(
          localGoalsDatasource:
              LocalGoalsDatasource(database: database),
          localStudyLogsDatasource: _localDs,
          supabaseGoalsDatasource:
              SupabaseGoalsDatasource(supabase: Supabase.instance.client),
          supabaseStudyLogsDatasource: _supabaseDs,
        );
  }

  Future<List<StudyDailyLogsModel>> fetchAllLogs(String userId) async {
    if (await _migrationService.isMigrated()) {
      return _supabaseDs.fetchAllLogs(userId);
    }
    return _localDs.fetchAllLogs();
  }

  Future<List<StudyDailyLogsModel>> fetchLogsByGoalId(
    String goalId,
    String userId,
  ) async {
    if (await _migrationService.isMigrated()) {
      return _supabaseDs.fetchLogsByGoalId(goalId);
    }
    return _localDs.fetchLogsByGoalId(goalId);
  }

  Future<Map<String, int>> fetchTotalSecondsForAllGoals(
    String userId,
  ) async {
    if (await _migrationService.isMigrated()) {
      final logs = await _supabaseDs.fetchAllLogs(userId);
      return _calculateTotalSecondsMap(logs);
    }
    return _localDs.fetchTotalSecondsForAllGoals();
  }

  Future<List<DateTime>> fetchStudyDatesInRange({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    if (await _migrationService.isMigrated()) {
      final logs = await _supabaseDs.fetchAllLogs(userId);
      return _calculateStudyDatesInRange(logs, startDate, endDate);
    }
    return _localDs.fetchStudyDatesInRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<int> calculateCurrentStreak(String userId) async {
    if (await _migrationService.isMigrated()) {
      final logs = await _supabaseDs.fetchAllLogs(userId);
      return _calculateCurrentStreakFromLogs(logs);
    }
    return _localDs.calculateCurrentStreak();
  }

  Future<int> calculateHistoricalLongestStreak(String userId) async {
    if (await _migrationService.isMigrated()) {
      final logs = await _supabaseDs.fetchAllLogs(userId);
      return _calculateHistoricalLongestStreakFromLogs(logs);
    }
    return _localDs.calculateHistoricalLongestStreak();
  }

  Future<DateTime?> fetchFirstStudyDate(String userId) async {
    if (await _migrationService.isMigrated()) {
      final logs = await _supabaseDs.fetchAllLogs(userId);
      if (logs.isEmpty) return null;
      logs.sort((a, b) => a.studyDate.compareTo(b.studyDate));
      final first = logs.first.studyDate;
      return DateTime(first.year, first.month, first.day);
    }
    return _localDs.fetchFirstStudyDate();
  }

  Future<Map<String, int>> fetchDailyRecordsByDate(
    DateTime date,
    String userId,
  ) async {
    if (await _migrationService.isMigrated()) {
      final logs = await _supabaseDs.fetchAllLogs(userId);
      return _calculateDailyRecordsByDate(logs, date);
    }
    return _localDs.fetchDailyRecordsByDate(date);
  }

  Future<StudyDailyLogsModel> upsertLog(StudyDailyLogsModel log) async {
    if (await _migrationService.isMigrated()) {
      return _supabaseDs.upsertLog(log);
    }
    await _localDs.saveLog(log);
    return log;
  }

  Map<String, int> _calculateTotalSecondsMap(
    List<StudyDailyLogsModel> logs,
  ) {
    final Map<String, int> totals = {};
    for (final log in logs) {
      totals.update(
        log.goalId,
        (value) => value + log.totalSeconds,
        ifAbsent: () => log.totalSeconds,
      );
    }
    return totals;
  }

  Map<String, int> _calculateDailyRecordsByDate(
    List<StudyDailyLogsModel> logs,
    DateTime date,
  ) {
    final dateKey = _dateKey(date);
    final Map<String, int> records = {};

    for (final log in logs) {
      if (_dateKey(log.studyDate) != dateKey) continue;
      records.update(
        log.goalId,
        (value) => value + log.totalSeconds,
        ifAbsent: () => log.totalSeconds,
      );
    }
    return records;
  }

  List<DateTime> _calculateStudyDatesInRange(
    List<StudyDailyLogsModel> logs,
    DateTime startDate,
    DateTime endDate,
  ) {
    final totalsByDate = _calculateTotalsByDate(logs);
    final startKey = _dateKey(startDate);
    final endKey = _dateKey(endDate);

    final dates = totalsByDate.entries
        .where(
          (entry) =>
              entry.value >= StreakConsts.minStudySeconds &&
              entry.key.compareTo(startKey) >= 0 &&
              entry.key.compareTo(endKey) <= 0,
        )
        .map((entry) => _parseDateKey(entry.key))
        .toList();

    dates.sort((a, b) => a.compareTo(b));
    return dates;
  }

  int _calculateCurrentStreakFromLogs(List<StudyDailyLogsModel> logs) {
    final totalsByDate = _calculateTotalsByDate(logs);
    final studiedDates = totalsByDate.entries
        .where((entry) => entry.value >= StreakConsts.minStudySeconds)
        .map((entry) => entry.key)
        .toSet();

    if (studiedDates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _dateKey(today);

    if (!studiedDates.contains(todayKey)) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayKey = _dateKey(yesterday);
      if (!studiedDates.contains(yesterdayKey)) {
        return 0;
      }
    }

    int streak = 0;
    DateTime checkDate =
        studiedDates.contains(todayKey)
            ? today
            : today.subtract(const Duration(days: 1));

    while (studiedDates.contains(_dateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _calculateHistoricalLongestStreakFromLogs(
    List<StudyDailyLogsModel> logs,
  ) {
    final totalsByDate = _calculateTotalsByDate(logs);
    final dates = totalsByDate.entries
        .where((entry) => entry.value >= StreakConsts.minStudySeconds)
        .map((entry) => _parseDateKey(entry.key))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    if (dates.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;

    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      currentStreak = (diff == 1) ? currentStreak + 1 : 1;
      longestStreak = max(longestStreak, currentStreak);
    }

    return longestStreak;
  }

  Map<String, int> _calculateTotalsByDate(List<StudyDailyLogsModel> logs) {
    final Map<String, int> totalsByDate = {};
    for (final log in logs) {
      final key = _dateKey(log.studyDate);
      totalsByDate.update(
        key,
        (value) => value + log.totalSeconds,
        ifAbsent: () => log.totalSeconds,
      );
    }
    return totalsByDate;
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
