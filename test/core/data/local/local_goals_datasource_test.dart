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
  });

  tearDown(() async {
    // テスト後にデータベースをクローズ
    await database.close();
  });

  group('LocalGoalsDatasource Tests', () {
    test('目標を保存できること', () async {
      // Arrange
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: 'テスト用の目標説明',
        targetMinutes: 1500,
        avoidMessage: 'テスト用の回避メッセージ',
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await datasource.saveGoal(goal, isSynced: false);

      // Assert
      final savedGoal = await datasource.fetchGoalById(goal.id);
      expect(savedGoal, isNotNull);
      expect(savedGoal!.id, equals(goal.id));
      expect(savedGoal.title, equals('テスト目標'));
      expect(savedGoal.description, equals('テスト用の目標説明'));
      expect(savedGoal.targetMinutes, equals(1500));
      expect(savedGoal.avoidMessage, equals('テスト用の回避メッセージ'));
    });

    test('複数の目標を保存して取得できること', () async {
      // Arrange
      final goal1 = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '目標1',
        description: '説明1',
        targetMinutes: 1000,
        avoidMessage: '回避メッセージ1',
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final goal2 = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '目標2',
        description: '説明2',
        targetMinutes: 2000,
        avoidMessage: '回避メッセージ2',
        deadline: DateTime.now().add(const Duration(days: 60)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await datasource.saveGoal(goal1, isSynced: false);
      await datasource.saveGoal(goal2, isSynced: false);

      // Assert
      final goals = await datasource.fetchAllGoals();
      expect(goals.length, equals(2));
      expect(goals.any((g) => g.id == goal1.id), isTrue);
      expect(goals.any((g) => g.id == goal2.id), isTrue);
    });

    test('目標を更新できること', () async {
      // Arrange
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '元の目標',
        description: '元の説明',
        targetMinutes: 1000,
        avoidMessage: '元の回避メッセージ',
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await datasource.saveGoal(goal, isSynced: false);

      // Act
      final updatedGoal = goal.copyWith(
        title: '更新された目標',
        targetMinutes: 2000,
      );
      await datasource.updateGoal(updatedGoal);

      // Assert
      final fetchedGoal = await datasource.fetchGoalById(goal.id);
      expect(fetchedGoal, isNotNull);
      expect(fetchedGoal!.title, equals('更新された目標'));
      expect(fetchedGoal.targetMinutes, equals(2000));
    });

    test('目標を削除できること', () async {
      // Arrange
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '削除する目標',
        description: '削除テスト',
        targetMinutes: 1000,
        avoidMessage: '削除テスト',
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await datasource.saveGoal(goal, isSynced: false);

      // Act
      await datasource.deleteGoal(goal.id);

      // Assert
      final deletedGoal = await datasource.fetchGoalById(goal.id);
      expect(deletedGoal, isNull);
    });

    test('未同期の目標を取得できること', () async {
      // Arrange
      final syncedGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '同期済み目標',
        description: '同期済み',
        targetMinutes: 1000,
        avoidMessage: '同期済み',
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final unsyncedGoal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: '未同期目標',
        description: '未同期',
        targetMinutes: 2000,
        avoidMessage: '未同期',
        deadline: DateTime.now().add(const Duration(days: 60)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await datasource.saveGoal(syncedGoal, isSynced: true);
      await datasource.saveGoal(unsyncedGoal, isSynced: false);

      // Act
      final unsyncedGoals = await datasource.fetchUnsyncedGoals();

      // Assert
      expect(unsyncedGoals.length, equals(1));
      expect(unsyncedGoals.first.id, equals(unsyncedGoal.id));
    });

    test('目標を同期済みにマークできること', () async {
      // Arrange
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'マークテスト',
        description: 'マークテスト',
        targetMinutes: 1000,
        avoidMessage: 'マークテスト',
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await datasource.saveGoal(goal, isSynced: false);

      // Act
      await datasource.markAsSynced(goal.id);

      // Assert
      final unsyncedGoals = await datasource.fetchUnsyncedGoals();
      expect(unsyncedGoals.any((g) => g.id == goal.id), isFalse);
    });

    test('descriptionがnullの目標を保存できること', () async {
      // Arrange
      final goal = GoalsModel(
        id: const Uuid().v4(),
        userId: 'test-user-1',
        title: 'テスト目標',
        description: null,
        targetMinutes: 1500,
        avoidMessage: 'テスト用の回避メッセージ',
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await datasource.saveGoal(goal, isSynced: false);

      // Assert
      final savedGoal = await datasource.fetchGoalById(goal.id);
      expect(savedGoal, isNotNull);
      expect(savedGoal!.description, isNull);
    });
  });
}
