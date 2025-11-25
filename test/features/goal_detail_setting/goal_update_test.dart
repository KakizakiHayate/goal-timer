import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/features/goal_timer/domain/entities/goal.dart';
import 'package:goal_timer/features/goal_timer/data/repositories/goal_repository_impl.dart';

void main() {
  group('GoalRepositoryImpl', () {
    late GoalRepositoryImpl repository;

    setUp(() {
      repository = GoalRepositoryImpl();
    });

    test('updateGoal should update an existing goal', () async {
      final goals = await repository.getAllGoals();
      expect(goals.isNotEmpty, true);

      final originalGoal = goals.first;
      final updatedGoal = originalGoal.copyWith(
        title: 'Updated Title',
        description: 'Updated Description',
      );

      final result = await repository.updateGoal(updatedGoal);

      expect(result.id, originalGoal.id);
      expect(result.title, 'Updated Title');
      expect(result.description, 'Updated Description');

      final fetchedGoals = await repository.getAllGoals();
      final fetchedGoal = fetchedGoals.firstWhere((g) => g.id == originalGoal.id);
      expect(fetchedGoal.title, 'Updated Title');
      expect(fetchedGoal.description, 'Updated Description');
    });

    test('updateGoal should throw exception for non-existent goal', () async {
      final nonExistentGoal = Goal(
        id: 'non-existent-id',
        title: 'Non-existent Goal',
        description: 'This goal does not exist',
        deadline: DateTime.now().add(const Duration(days: 7)),
      );

      expect(
        () => repository.updateGoal(nonExistentGoal),
        throwsException,
      );
    });

    test('updateGoal should preserve unchanged fields', () async {
      final goals = await repository.getAllGoals();
      expect(goals.isNotEmpty, true);

      final originalGoal = goals.first;
      final originalDeadline = originalGoal.deadline;
      final originalIsCompleted = originalGoal.isCompleted;

      final updatedGoal = originalGoal.copyWith(
        title: 'Only Title Changed',
      );

      final result = await repository.updateGoal(updatedGoal);

      expect(result.title, 'Only Title Changed');
      expect(result.description, originalGoal.description);
      expect(result.deadline, originalDeadline);
      expect(result.isCompleted, originalIsCompleted);
    });

    test('Goal copyWith should create a new instance with updated values', () {
      final original = Goal(
        id: '1',
        title: 'Original Title',
        description: 'Original Description',
        deadline: DateTime(2025, 12, 31),
        isCompleted: false,
      );

      final updated = original.copyWith(
        title: 'New Title',
        description: 'New Description',
      );

      expect(updated.id, original.id);
      expect(updated.title, 'New Title');
      expect(updated.description, 'New Description');
      expect(updated.deadline, original.deadline);
      expect(updated.isCompleted, original.isCompleted);

      expect(original.title, 'Original Title');
      expect(original.description, 'Original Description');
    });
  });
}
