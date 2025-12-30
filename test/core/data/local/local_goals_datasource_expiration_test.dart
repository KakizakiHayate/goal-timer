import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/local_goals_datasource.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  late LocalGoalsDatasource datasource;
  late AppDatabase database;

  setUpAll(() {
    // sqflite_ffiを初期化（テスト環境用）
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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
        deadline: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
      );

      expect(goal.totalTargetMinutes, equals(300));
    });

    test('GoalsModel should include expiredAt field', () {
      final expiredTime = DateTime.now();
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 30,
        avoidMessage: 'テスト',
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        expiredAt: expiredTime,
        createdAt: DateTime.now(),
      );

      expect(goal.expiredAt, equals(expiredTime));
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
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        expiredAt: DateTime.now(),
        createdAt: DateTime.now(),
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
        deadline: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
      );

      expect(goal.isExpired, isFalse);
    });
  });

  group('LocalGoalsDatasource 期限切れ処理', () {
    test('updateExpiredGoals sets expiredAt for past deadline goals', () async {
      // Arrange - 期限切れ目標を作成
      final expiredGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '期限切れ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 30,
        avoidMessage: 'テスト',
        deadline: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now(),
      );

      final activeGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'アクティブ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
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
      final expiredGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '期限切れ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 30,
        avoidMessage: 'テスト',
        deadline: DateTime.now().subtract(const Duration(days: 2)),
        expiredAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final activeGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'アクティブ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
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
      final deletedGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '削除済み目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: DateTime.now().add(const Duration(days: 10)),
        deletedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final activeGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'アクティブ目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 300,
        avoidMessage: 'テスト',
        deadline: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
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
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: 'テスト',
        targetMinutes: 30,
        totalTargetMinutes: 900, // 30分 × 30日
        avoidMessage: 'テスト',
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
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
      final goalId = const Uuid().v4();
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 10));
      final db = await database.database;

      await db.insert('goals', {
        'id': goalId,
        'user_id': 'test-user-1',
        'title': 'テスト目標',
        'description': 'テスト',
        'target_minutes': 60, // 1時間/日
        'total_target_minutes': null, // NULL
        'avoid_message': 'テスト',
        'deadline': deadline.toIso8601String(),
        'created_at': now.toIso8601String(),
      });

      // Act
      await datasource.populateMissingTotalTargetMinutes();

      // Assert
      final updatedGoal = await datasource.fetchGoalById(goalId);
      expect(updatedGoal!.totalTargetMinutes, isNotNull);
      // 10日間 + 今日 = 11日 × 60分 = 660分
      expect(updatedGoal.totalTargetMinutes, equals(660));
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
        deadline: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
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
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 10));
      final db = await database.database;

      await db.insert('goals', {
        'id': goalId,
        'user_id': 'test-user-1',
        'title': '削除済み目標',
        'description': 'テスト',
        'target_minutes': 60,
        'total_target_minutes': null, // NULL
        'avoid_message': 'テスト',
        'deadline': deadline.toIso8601String(),
        'deleted_at': now.toIso8601String(), // 削除済み
        'created_at': now.toIso8601String(),
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
