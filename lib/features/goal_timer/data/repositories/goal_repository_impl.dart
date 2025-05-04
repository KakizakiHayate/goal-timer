import 'package:goal_timer/features/goal_timer/data/repositories/goal_repository.dart';
import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';

// モックデータを使ったゴールリポジトリの実装
class GoalRepositoryImpl implements GoalRepository {
  // モックデータ
  final List<Goal> _goals = [
    Goal(
      id: '1',
      title: 'Flutterアプリを完成させる',
      description: 'Clean Architectureを使った簡単なゴールタイマーアプリを作成する',
      deadline: DateTime.now().add(const Duration(days: 7)),
    ),
    Goal(
      id: '2',
      title: 'Riverpodの学習',
      description: 'Riverpodの基本概念と実装方法を理解する',
      deadline: DateTime.now().add(const Duration(days: 3)),
    ),
  ];

  @override
  Future<List<Goal>> getAllGoals() async {
    // モックデータなので遅延を模倣
    await Future.delayed(const Duration(milliseconds: 500));
    return _goals;
  }

  @override
  Future<Goal?> getGoalById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _goals.firstWhere((goal) => goal.id == id,
        orElse: () => throw Exception('Goal not found'));
  }

  @override
  Future<Goal> addGoal(Goal goal) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _goals.add(goal);
    return goal;
  }

  @override
  Future<Goal> updateGoal(Goal goal) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      _goals[index] = goal;
      return goal;
    }
    throw Exception('Goal not found');
  }

  @override
  Future<void> deleteGoal(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _goals.removeWhere((goal) => goal.id == id);
  }
}
