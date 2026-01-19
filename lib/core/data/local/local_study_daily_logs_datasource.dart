import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../models/study_daily_logs/study_daily_logs_model.dart';
import '../../utils/streak_consts.dart';
import '../../utils/time_utils.dart';
import 'app_database.dart';
import 'database_consts.dart';

class LocalStudyDailyLogsDatasource {
  final AppDatabase _database;

  LocalStudyDailyLogsDatasource({required AppDatabase database})
    : _database = database;

  /// 全ての学習ログを取得
  Future<List<StudyDailyLogsModel>> fetchAllLogs() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConsts.tableStudyDailyLogs,
    );

    return maps.map((map) => _mapToModel(map)).toList();
  }

  /// 特定の目標の学習ログを取得
  Future<List<StudyDailyLogsModel>> fetchLogsByGoalId(String goalId) async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConsts.tableStudyDailyLogs,
      where: '${DatabaseConsts.columnGoalId} = ?',
      whereArgs: [goalId],
    );

    return maps.map((map) => _mapToModel(map)).toList();
  }

  /// 目標ごとの学習時間合計（秒）を取得
  /// SQLで直接集計することで効率的に取得
  Future<int> fetchTotalSecondsByGoalId(String goalId) async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT SUM(${DatabaseConsts.columnTotalSeconds}) as total FROM ${DatabaseConsts.tableStudyDailyLogs} WHERE ${DatabaseConsts.columnGoalId} = ?',
      [goalId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// 全目標の学習時間合計をまとめて取得
  /// Map`goalId, totalSeconds`の形式で返す
  Future<Map<String, int>> fetchTotalSecondsForAllGoals() async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT ${DatabaseConsts.columnGoalId}, SUM(${DatabaseConsts.columnTotalSeconds}) as total FROM ${DatabaseConsts.tableStudyDailyLogs} GROUP BY ${DatabaseConsts.columnGoalId}',
    );

    final Map<String, int> totals = {};
    for (final row in result) {
      final goalId = row[DatabaseConsts.columnGoalId] as String;
      final total = (row['total'] as int?) ?? 0;
      totals[goalId] = total;
    }
    return totals;
  }

  /// 学習ログを保存
  Future<void> saveLog(StudyDailyLogsModel log) async {
    final db = await _database.database;
    await db.insert(
      DatabaseConsts.tableStudyDailyLogs,
      _modelToMap(log),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 学習ログを削除
  Future<void> deleteLog(String id) async {
    final db = await _database.database;
    await db.delete(
      DatabaseConsts.tableStudyDailyLogs,
      where: '${DatabaseConsts.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 特定の目標に紐づく学習ログをすべて削除
  Future<void> deleteLogsByGoalId(String goalId) async {
    final db = await _database.database;
    await db.delete(
      DatabaseConsts.tableStudyDailyLogs,
      where: '${DatabaseConsts.columnGoalId} = ?',
      whereArgs: [goalId],
    );
  }

  /// 未同期のログを取得
  Future<List<StudyDailyLogsModel>> fetchUnsyncedLogs() async {
    final db = await _database.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConsts.tableStudyDailyLogs,
      where: '${DatabaseConsts.columnSyncUpdatedAt} IS NULL',
    );

    return maps.map((map) => _mapToModel(map)).toList();
  }

  /// 同期済みフラグを更新
  Future<void> markAsSynced(String id) async {
    final db = await _database.database;
    await db.update(
      DatabaseConsts.tableStudyDailyLogs,
      {DatabaseConsts.columnSyncUpdatedAt: DateTime.now().toIso8601String()},
      where: '${DatabaseConsts.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 指定期間内の学習日リストを取得（合計1分以上の日のみ）
  /// 全ての目標を合算してカウント
  Future<List<DateTime>> fetchStudyDatesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _database.database;

    final startDateStr = _formatDateOnly(startDate);
    final endDateStr = _formatDateOnly(endDate);

    final result = await db.rawQuery(
      '''
      SELECT DATE(${DatabaseConsts.columnStudyDate}) as study_day, 
             SUM(${DatabaseConsts.columnTotalSeconds}) as total
      FROM ${DatabaseConsts.tableStudyDailyLogs}
      WHERE DATE(${DatabaseConsts.columnStudyDate}) >= DATE(?)
        AND DATE(${DatabaseConsts.columnStudyDate}) <= DATE(?)
      GROUP BY DATE(${DatabaseConsts.columnStudyDate})
      HAVING SUM(${DatabaseConsts.columnTotalSeconds}) >= ?
      ORDER BY study_day ASC
      ''',
      [startDateStr, endDateStr, StreakConsts.minStudySeconds],
    );

    return result.map((row) {
      final dateStr = row['study_day'] as String;
      return DateTime.parse(dateStr);
    }).toList();
  }

  /// 現在のストリーク（連続学習日数）を計算
  /// 今日または昨日から遡って連続した学習日をカウント
  Future<int> calculateCurrentStreak() async {
    final db = await _database.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final result = await db.rawQuery(
      '''
      SELECT DATE(${DatabaseConsts.columnStudyDate}) as study_day, 
             SUM(${DatabaseConsts.columnTotalSeconds}) as total
      FROM ${DatabaseConsts.tableStudyDailyLogs}
      GROUP BY DATE(${DatabaseConsts.columnStudyDate})
      HAVING SUM(${DatabaseConsts.columnTotalSeconds}) >= ?
      ORDER BY study_day DESC
      LIMIT ?
      ''',
      [StreakConsts.minStudySeconds, StreakConsts.maxStreakQueryLimit],
    );

    if (result.isEmpty) {
      return 0;
    }

    final studyDates =
        result.map((row) {
          final dateStr = row['study_day'] as String;
          return DateTime.parse(dateStr);
        }).toList();

    int streak = 0;
    DateTime checkDate = today;

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

  /// 過去の全学習ログから最長連続日数を計算
  /// 現在のストリークではなく、履歴全体から最長を算出
  Future<int> calculateHistoricalLongestStreak() async {
    final db = await _database.database;

    // 1分以上学習した日を日付順（昇順）で取得
    final result = await db.rawQuery(
      '''
      SELECT DATE(${DatabaseConsts.columnStudyDate}) as study_day,
             SUM(${DatabaseConsts.columnTotalSeconds}) as total
      FROM ${DatabaseConsts.tableStudyDailyLogs}
      GROUP BY DATE(${DatabaseConsts.columnStudyDate})
      HAVING SUM(${DatabaseConsts.columnTotalSeconds}) >= ?
      ORDER BY study_day ASC
      ''',
      [StreakConsts.minStudySeconds],
    );

    if (result.isEmpty) {
      return 0;
    }

    // 日付リストに変換
    final studyDates =
        result.map((row) {
          final dateStr = row['study_day'] as String;
          return DateTime.parse(dateStr);
        }).toList();

    // 最長連続日数を計算
    int longestStreak = 1;
    int currentStreak = 1;

    for (var i = 1; i < studyDates.length; i++) {
      final previousDate = studyDates[i - 1];
      final currentDate = studyDates[i];

      // 前日との差が1日なら連続
      final difference = currentDate.difference(previousDate).inDays;

      if (difference == 1) {
        currentStreak++;
        longestStreak = max(currentStreak, longestStreak);
      } else {
        // 連続が途切れた
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  /// 最初の学習記録日を取得
  /// 学習記録がない場合はnullを返す
  Future<DateTime?> fetchFirstStudyDate() async {
    final db = await _database.database;

    final result = await db.rawQuery('''
      SELECT MIN(DATE(${DatabaseConsts.columnStudyDate})) as first_date
      FROM ${DatabaseConsts.tableStudyDailyLogs}
      ''');

    if (result.isEmpty || result.first['first_date'] == null) {
      return null;
    }

    final dateStr = result.first['first_date'] as String;
    return DateTime.parse(dateStr);
  }

  /// 指定日の目標別学習時間を取得
  /// Map`goalId, totalSeconds`の形式で返す
  Future<Map<String, int>> fetchDailyRecordsByDate(DateTime date) async {
    final db = await _database.database;
    final dateStr = _formatDateOnly(date);

    final result = await db.rawQuery(
      '''
      SELECT ${DatabaseConsts.columnGoalId}, SUM(${DatabaseConsts.columnTotalSeconds}) as total
      FROM ${DatabaseConsts.tableStudyDailyLogs}
      WHERE DATE(${DatabaseConsts.columnStudyDate}) = DATE(?)
      GROUP BY ${DatabaseConsts.columnGoalId}
      ''',
      [dateStr],
    );

    final Map<String, int> records = {};
    for (final row in result) {
      final goalId = row[DatabaseConsts.columnGoalId] as String;
      final total = (row['total'] as int?) ?? 0;
      records[goalId] = total;
    }
    return records;
  }

  // ヘルパーメソッド: 日付のみをYYYY-MM-DD形式で取得
  String _formatDateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ヘルパーメソッド: Map → Model
  StudyDailyLogsModel _mapToModel(Map<String, dynamic> map) {
    try {
      return StudyDailyLogsModel(
        id: map[DatabaseConsts.columnId] as String,
        goalId: map[DatabaseConsts.columnGoalId] as String,
        studyDate: DateTime.parse(
          map[DatabaseConsts.columnStudyDate] as String,
        ),
        totalSeconds: map[DatabaseConsts.columnTotalSeconds] as int,
        userId: map[DatabaseConsts.columnUserId] as String?,
        createdAt:
            map[DatabaseConsts.columnCreatedAt] != null
                ? DateTime.parse(map[DatabaseConsts.columnCreatedAt] as String)
                : null,
        updatedAt:
            map[DatabaseConsts.columnUpdatedAt] != null
                ? DateTime.parse(map[DatabaseConsts.columnUpdatedAt] as String)
                : null,
        syncUpdatedAt:
            map[DatabaseConsts.columnSyncUpdatedAt] != null
                ? DateTime.parse(
                  map[DatabaseConsts.columnSyncUpdatedAt] as String,
                )
                : null,
      );
    } catch (e) {
      throw Exception('データベースからのモデル変換に失敗しました: $e');
    }
  }

  // ヘルパーメソッド: Model → Map
  Map<String, dynamic> _modelToMap(StudyDailyLogsModel model) {
    return {
      DatabaseConsts.columnId: model.id,
      DatabaseConsts.columnGoalId: model.goalId,
      DatabaseConsts.columnStudyDate: model.studyDate.toIso8601String(),
      DatabaseConsts.columnTotalSeconds: model.totalSeconds,
      DatabaseConsts.columnUserId: model.userId,
      DatabaseConsts.columnCreatedAt: model.createdAt?.toIso8601String(),
      DatabaseConsts.columnUpdatedAt: model.updatedAt?.toIso8601String(),
      DatabaseConsts.columnSyncUpdatedAt:
          model.syncUpdatedAt?.toIso8601String(),
    };
  }
}
