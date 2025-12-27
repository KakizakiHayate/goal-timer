import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/local_study_daily_logs_datasource.dart';
import 'package:goal_timer/core/models/study_daily_logs/study_daily_logs_model.dart';
import 'package:goal_timer/core/utils/streak_consts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  late LocalStudyDailyLogsDatasource datasource;
  late AppDatabase database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = AppDatabase();
    datasource = LocalStudyDailyLogsDatasource(database: database);

    final db = await database.database;
    await db.delete('study_daily_logs');
  });

  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime daysAgo(int days) {
    return today().subtract(Duration(days: days));
  }

  Future<void> createStudyLog({
    required DateTime studyDate,
    required int totalSeconds,
    String? goalId,
  }) async {
    final log = StudyDailyLogsModel(
      id: const Uuid().v4(),
      goalId: goalId ?? 'test-goal-id',
      studyDate: studyDate,
      totalSeconds: totalSeconds,
    );
    await datasource.saveLog(log);
  }

  group('fetchStudyDatesInRange', () {
    test('学習記録なし → 空のリストを返す', () async {
      final startDate = daysAgo(6);
      final endDate = today();

      final result = await datasource.fetchStudyDatesInRange(
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isEmpty);
    });

    test('1分以上の学習記録がある日のみ返す', () async {
      await createStudyLog(studyDate: today(), totalSeconds: 60);
      await createStudyLog(studyDate: daysAgo(1), totalSeconds: 59);

      final result = await datasource.fetchStudyDatesInRange(
        startDate: daysAgo(6),
        endDate: today(),
      );

      expect(result.length, equals(1));
      expect(result.first, equals(today()));
    });

    test('同じ日に複数の学習記録がある場合、合計で1分以上なら学習日としてカウント', () async {
      await createStudyLog(studyDate: today(), totalSeconds: 30);
      await createStudyLog(studyDate: today(), totalSeconds: 30);

      final result = await datasource.fetchStudyDatesInRange(
        startDate: daysAgo(6),
        endDate: today(),
      );

      expect(result.length, equals(1));
      expect(result.first, equals(today()));
    });

    test('指定期間内の学習日のみ返す', () async {
      await createStudyLog(studyDate: daysAgo(7), totalSeconds: 120);
      await createStudyLog(studyDate: daysAgo(3), totalSeconds: 120);
      await createStudyLog(studyDate: today(), totalSeconds: 120);

      final result = await datasource.fetchStudyDatesInRange(
        startDate: daysAgo(6),
        endDate: today(),
      );

      expect(result.length, equals(2));
      expect(result.contains(daysAgo(3)), isTrue);
      expect(result.contains(today()), isTrue);
      expect(result.contains(daysAgo(7)), isFalse);
    });

    test('複数の目標の学習記録を合算してカウント', () async {
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 30,
        goalId: 'goal-1',
      );
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 30,
        goalId: 'goal-2',
      );

      final result = await datasource.fetchStudyDatesInRange(
        startDate: daysAgo(6),
        endDate: today(),
      );

      expect(result.length, equals(1));
      expect(result.first, equals(today()));
    });
  });

  group('calculateCurrentStreak', () {
    test('学習記録なし → ストリーク = 0', () async {
      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(0));
    });

    test('今日のみ学習（1分以上） → ストリーク = 1', () async {
      await createStudyLog(studyDate: today(), totalSeconds: 60);

      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(1));
    });

    test('今日と昨日学習 → ストリーク = 2', () async {
      await createStudyLog(studyDate: today(), totalSeconds: 60);
      await createStudyLog(studyDate: daysAgo(1), totalSeconds: 60);

      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(2));
    });

    test('今日未学習、昨日のみ学習 → ストリーク = 1', () async {
      await createStudyLog(studyDate: daysAgo(1), totalSeconds: 60);

      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(1));
    });

    test('今日未学習、昨日も未学習、一昨日学習 → ストリーク = 0', () async {
      await createStudyLog(studyDate: daysAgo(2), totalSeconds: 60);

      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(0));
    });

    test('7日連続学習 → ストリーク = 7', () async {
      for (var i = 0; i < 7; i++) {
        await createStudyLog(studyDate: daysAgo(i), totalSeconds: 60);
      }

      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(7));
    });

    test('今日59秒学習（1分未満） → 学習日としてカウントしない', () async {
      await createStudyLog(studyDate: today(), totalSeconds: 59);

      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(0));
    });

    test('今日30秒+30秒学習（合計1分） → 学習日としてカウントする', () async {
      await createStudyLog(studyDate: today(), totalSeconds: 30);
      await createStudyLog(studyDate: today(), totalSeconds: 30);

      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(1));
    });

    test('連続が途切れた場合、途切れた後からカウント', () async {
      await createStudyLog(studyDate: today(), totalSeconds: 60);
      await createStudyLog(studyDate: daysAgo(1), totalSeconds: 60);
      await createStudyLog(studyDate: daysAgo(3), totalSeconds: 60);
      await createStudyLog(studyDate: daysAgo(4), totalSeconds: 60);

      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(2));
    });

    test('複数の目標の学習記録を合算してストリーク計算', () async {
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 30,
        goalId: 'goal-1',
      );
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 30,
        goalId: 'goal-2',
      );
      await createStudyLog(
        studyDate: daysAgo(1),
        totalSeconds: 60,
        goalId: 'goal-1',
      );

      final result = await datasource.calculateCurrentStreak();

      expect(result, equals(2));
    });

    test('minStudySeconds定数が正しく使用されている', () {
      expect(StreakConsts.minStudySeconds, equals(60));
    });
  });

  group('fetchFirstStudyDate', () {
    test('学習記録なし → nullを返す', () async {
      final result = await datasource.fetchFirstStudyDate();

      expect(result, isNull);
    });

    test('学習記録あり → 最初の学習日を返す', () async {
      await createStudyLog(studyDate: daysAgo(10), totalSeconds: 60);
      await createStudyLog(studyDate: daysAgo(5), totalSeconds: 60);
      await createStudyLog(studyDate: today(), totalSeconds: 60);

      final result = await datasource.fetchFirstStudyDate();

      expect(result, equals(daysAgo(10)));
    });

    test('同じ日の複数記録があっても、その日を返す', () async {
      await createStudyLog(studyDate: daysAgo(3), totalSeconds: 30);
      await createStudyLog(studyDate: daysAgo(3), totalSeconds: 30);

      final result = await datasource.fetchFirstStudyDate();

      expect(result, equals(daysAgo(3)));
    });
  });

  group('fetchDailyRecordsByDate', () {
    test('指定日に学習記録なし → 空のMapを返す', () async {
      final result = await datasource.fetchDailyRecordsByDate(today());

      expect(result, isEmpty);
    });

    test('指定日に1つの目標の学習記録がある → その目標のデータを返す', () async {
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 3600,
        goalId: 'goal-1',
      );

      final result = await datasource.fetchDailyRecordsByDate(today());

      expect(result.length, equals(1));
      expect(result['goal-1'], equals(3600));
    });

    test('指定日に複数の目標の学習記録がある → 全ての目標のデータを返す', () async {
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 1800,
        goalId: 'goal-1',
      );
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 3600,
        goalId: 'goal-2',
      );

      final result = await datasource.fetchDailyRecordsByDate(today());

      expect(result.length, equals(2));
      expect(result['goal-1'], equals(1800));
      expect(result['goal-2'], equals(3600));
    });

    test('同じ日に同じ目標の複数記録がある → 合計時間を返す', () async {
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 1800,
        goalId: 'goal-1',
      );
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 1200,
        goalId: 'goal-1',
      );

      final result = await datasource.fetchDailyRecordsByDate(today());

      expect(result.length, equals(1));
      expect(result['goal-1'], equals(3000)); // 1800 + 1200
    });

    test('別の日の学習記録は含まれない', () async {
      await createStudyLog(
        studyDate: today(),
        totalSeconds: 3600,
        goalId: 'goal-1',
      );
      await createStudyLog(
        studyDate: daysAgo(1),
        totalSeconds: 1800,
        goalId: 'goal-2',
      );

      final result = await datasource.fetchDailyRecordsByDate(today());

      expect(result.length, equals(1));
      expect(result['goal-1'], equals(3600));
      expect(result.containsKey('goal-2'), isFalse);
    });
  });
}
