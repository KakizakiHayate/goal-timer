import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/local_goals_datasource.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  late LocalGoalsDatasource datasource;
  late AppDatabase database;

  // テストの決定性を保証するため固定日付を使用
  // DateTime.now()を使用するとテストがflakyになる可能性がある
  final fixedNow = DateTime(2025, 6, 15, 12, 0, 0);
  final fixedToday = DateTime(2025, 6, 15);

  setUpAll(() {
    // sqflite_ffiを初期化（テスト環境用）
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // シングルトンをリセット
    AppDatabase.resetForTesting();
  });

  setUp(() async {
    // テスト用のデータベースインスタンスを作成
    database = AppDatabase();
    datasource = LocalGoalsDatasource(database: database);

    // テストごとにgoalsテーブルをクリア
    final db = await database.database;
    await db.delete('goals');
  });

  group('GoalsModel 期限切れ関連', () {
    test('GoalsModel should include totalTargetMinutes field', () {
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: fixedToday.add(const Duration(days: 10)),
        createdAt: fixedNow,
      );

      expect(goal.totalTargetMinutes, equals(300));
    });

    test('GoalsModel should include expiredAt field', () {
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 30,
        avoidMessage: 'テスト',
        deadline: fixedToday.subtract(const Duration(days: 1)),
        expiredAt: fixedNow,
        createdAt: fixedNow,
      );

      expect(goal.expiredAt, equals(fixedNow));
    });

    test('GoalsModel.isExpired returns true when expiredAt is not null', () {
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 30,
        avoidMessage: 'テスト',
        deadline: fixedToday.subtract(const Duration(days: 1)),
        expiredAt: fixedNow,
        createdAt: fixedNow,
      );

      expect(goal.isExpired, isTrue);
    });

    test('GoalsModel.isExpired returns false when expiredAt is null', () {
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: fixedToday.add(const Duration(days: 10)),
        createdAt: fixedNow,
      );

      expect(goal.isExpired, isFalse);
    });
  });

  group('LocalGoalsDatasource 期限切れ処理', () {
    test('updateExpiredGoals sets expiredAt for past deadline goals', () async {
      // Arrange - 期限切れ目標を作成
      // updateExpiredGoals()は内部でDateTime.now()を使用するため、
      // 期限切れ目標は過去の日付、アクティブ目標は十分に未来の日付を使用
      final pastDeadline = DateTime(2020, 1, 1); // 確実に過去
      final futureDeadline = DateTime(2099, 12, 31); // 確実に未来

      final expiredGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '期限切れ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 30,
        avoidMessage: 'テスト',
        deadline: pastDeadline,
        createdAt: fixedNow,
      );

      final activeGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'アクティブ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: futureDeadline,
        createdAt: fixedNow,
      );

      await datasource.saveGoal(expiredGoal);
      await datasource.saveGoal(activeGoal);

      // Act
      await datasource.updateExpiredGoals();

      // Assert
      final updatedExpiredGoal = await datasource.fetchGoalById(expiredGoal.id);
      final updatedActiveGoal = await datasource.fetchGoalById(activeGoal.id);

      expect(updatedExpiredGoal!.expiredAt, isNotNull);
      expect(updatedActiveGoal!.expiredAt, isNull);
    });

    test('fetchActiveGoals excludes expired goals', () async {
      // Arrange
      // expiredAtが設定されている目標は期限切れとして扱われる
      final pastDeadline = DateTime(2020, 1, 1);
      final futureDeadline = DateTime(2099, 12, 31);

      final expiredGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '期限切れ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 30,
        avoidMessage: 'テスト',
        deadline: pastDeadline,
        expiredAt: fixedNow, // expiredAtが設定されているので期限切れ
        createdAt: fixedNow,
      );

      final activeGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'アクティブ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: futureDeadline,
        createdAt: fixedNow,
      );

      await datasource.saveGoal(expiredGoal);
      await datasource.saveGoal(activeGoal);

      // Act
      final activeGoals = await datasource.fetchActiveGoals();

      // Assert
      expect(activeGoals.length, equals(1));
      expect(activeGoals.first.id, equals(activeGoal.id));
    });

    test('fetchActiveGoals excludes deleted goals', () async {
      // Arrange
      final futureDeadline = DateTime(2099, 12, 31);

      final deletedGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '削除済み目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: futureDeadline,
        deletedAt: fixedNow,
        createdAt: fixedNow,
      );

      final activeGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'アクティブ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: futureDeadline,
        createdAt: fixedNow,
      );

      await datasource.saveGoal(deletedGoal);
      await datasource.saveGoal(activeGoal);

      // Act
      final activeGoals = await datasource.fetchActiveGoals();

      // Assert
      expect(activeGoals.length, equals(1));
      expect(activeGoals.first.id, equals(activeGoal.id));
    });

    test('totalTargetMinutes is correctly saved and retrieved', () async {
      // Arrange
      final futureDeadline = DateTime(2099, 12, 31);

      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 900, // 30分 × 30日
        avoidMessage: 'テスト',
        deadline: futureDeadline,
        createdAt: fixedNow,
      );

      // Act
      await datasource.saveGoal(goal);
      final savedGoal = await datasource.fetchGoalById(goal.id);

      // Assert
      expect(savedGoal!.totalTargetMinutes, equals(900));
    });
  });

  group('populateMissingTotalTargetMinutes', () {
    test('sets totalTargetMinutes for goals with null value', () async {
      // Arrange - totalTargetMinutesがnullの目標を直接DBに挿入
      // 十分に未来の日付を使用して、テスト実行時期に関係なく正の残り日数を保証
      final goalId = const Uuid().v4();
      final farFutureDeadline = DateTime(2099, 12, 31);
      final db = await database.database;

      await db.insert('goals', {
        'id': goalId,
        'user_id': 'test-user-1',
        'title': 'テスト目標',
        'description': 'テスト',
        'target_minutes': 60, // 1時間/日
        'total_target_minutes': null, // NULL
        'avoid_message': 'テスト',
        'deadline': farFutureDeadline.toIso8601String(),
        'created_at': fixedNow.toIso8601String(),
      });

      // Act
      await datasource.populateMissingTotalTargetMinutes();

      // Assert
      final updatedGoal = await datasource.fetchGoalById(goalId);
      expect(updatedGoal!.totalTargetMinutes, isNotNull);
      // 残り日数は実行時期によって変わるため、正の値であることのみ確認
      expect(updatedGoal.totalTargetMinutes, greaterThan(0));
    });

    test('does not modify goals with existing totalTargetMinutes', () async {
      // Arrange - 既にtotalTargetMinutesが設定されている目標
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: 'テスト',
        targetMinutes: 60,
        totalTargetMinutes: 1000, // 既存の値
        avoidMessage: 'テスト',
        deadline: fixedToday.add(const Duration(days: 10)),
        createdAt: fixedNow,
      );
      await datasource.saveGoal(goal);

      // Act
      await datasource.populateMissingTotalTargetMinutes();

      // Assert
      final updatedGoal = await datasource.fetchGoalById(goal.id);
      expect(updatedGoal!.totalTargetMinutes, equals(1000)); // 変更なし
    });

    test('does not update deleted goals', () async {
      // Arrange - 削除済みでtotalTargetMinutesがnullの目標を直接DBに挿入
      final goalId = const Uuid().v4();
      final farFutureDeadline = DateTime(2099, 12, 31);
      final db = await database.database;

      await db.insert('goals', {
        'id': goalId,
        'user_id': 'test-user-1',
        'title': '削除済み目標',
        'description': 'テスト',
        'target_minutes': 60,
        'total_target_minutes': null, // NULL
        'avoid_message': 'テスト',
        'deadline': farFutureDeadline.toIso8601String(),
        'deleted_at': fixedNow.toIso8601String(), // 削除済み
        'created_at': fixedNow.toIso8601String(),
      });

      // Act
      await datasource.populateMissingTotalTargetMinutes();

      // Assert - 削除済み目標は更新されない
      final result = await db.query(
        'goals',
        where: 'id = ?',
        whereArgs: [goalId],
      );
      expect(result.first['total_target_minutes'], isNull);
    });
  });
}
