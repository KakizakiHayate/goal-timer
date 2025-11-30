import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/data/local/local_goals_datasource.dart';
import 'package:goal_timer/core/data/local/local_study_daily_logs_datasource.dart';
import 'package:goal_timer/features/home/view_model/home_view_model.dart';

class MockLocalGoalsDatasource extends Mock implements LocalGoalsDatasource {}

class MockLocalStudyDailyLogsDatasource extends Mock
    implements LocalStudyDailyLogsDatasource {}

void main() {
  late HomeViewModel viewModel;
  late MockLocalGoalsDatasource mockGoalsDatasource;
  late MockLocalStudyDailyLogsDatasource mockStudyLogsDatasource;

  final testGoal = GoalsModel(
    id: 'test-goal-id',
    userId: null,
    title: 'Test Goal',
    description: 'Test Description',
    targetMinutes: 100,
    avoidMessage: 'Test avoid message',
    deadline: DateTime(2025, 12, 31),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final testGoal2 = GoalsModel(
    id: 'test-goal-id-2',
    userId: null,
    title: 'Test Goal 2',
    description: 'Test Description 2',
    targetMinutes: 200,
    avoidMessage: 'Test avoid message 2',
    deadline: DateTime(2025, 12, 31),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  setUp(() {
    mockGoalsDatasource = MockLocalGoalsDatasource();
    mockStudyLogsDatasource = MockLocalStudyDailyLogsDatasource();

    when(() => mockGoalsDatasource.fetchAllGoals())
        .thenAnswer((_) async => [testGoal, testGoal2]);

    viewModel = HomeViewModel(
      goalsDatasource: mockGoalsDatasource,
      studyLogsDatasource: mockStudyLogsDatasource,
    );
  });

  group('HomeViewModel', () {
    group('onDeleteGoalConfirmed', () {
      test('should delete goal and its study logs from datasources', () async {
        when(() => mockStudyLogsDatasource.deleteLogsByGoalId(testGoal.id))
            .thenAnswer((_) async {});
        when(() => mockGoalsDatasource.deleteGoal(testGoal.id))
            .thenAnswer((_) async {});

        await viewModel.loadGoals();
        expect(viewModel.state.goals.length, 2);

        final result = await viewModel.onDeleteGoalConfirmed(testGoal);

        expect(result, DeleteGoalResult.success);
        verify(() => mockStudyLogsDatasource.deleteLogsByGoalId(testGoal.id))
            .called(1);
        verify(() => mockGoalsDatasource.deleteGoal(testGoal.id)).called(1);
      });

      test('should remove goal from state after deletion', () async {
        when(() => mockStudyLogsDatasource.deleteLogsByGoalId(testGoal.id))
            .thenAnswer((_) async {});
        when(() => mockGoalsDatasource.deleteGoal(testGoal.id))
            .thenAnswer((_) async {});

        await viewModel.loadGoals();
        expect(viewModel.state.goals.length, 2);
        expect(
            viewModel.state.goals.any((g) => g.id == testGoal.id), isTrue);

        final result = await viewModel.onDeleteGoalConfirmed(testGoal);

        expect(result, DeleteGoalResult.success);
        expect(viewModel.state.goals.length, 1);
        expect(
            viewModel.state.goals.any((g) => g.id == testGoal.id), isFalse);
        expect(
            viewModel.state.goals.any((g) => g.id == testGoal2.id), isTrue);
      });

      test('should delete study logs before deleting goal (cascade delete)',
          () async {
        final callOrder = <String>[];

        when(() => mockStudyLogsDatasource.deleteLogsByGoalId(testGoal.id))
            .thenAnswer((_) async {
          callOrder.add('deleteLogsByGoalId');
        });
        when(() => mockGoalsDatasource.deleteGoal(testGoal.id))
            .thenAnswer((_) async {
          callOrder.add('deleteGoal');
        });

        await viewModel.loadGoals();
        await viewModel.onDeleteGoalConfirmed(testGoal);

        expect(callOrder, ['deleteLogsByGoalId', 'deleteGoal']);
      });

      test('should return failure when deletion fails', () async {
        when(() => mockStudyLogsDatasource.deleteLogsByGoalId(testGoal.id))
            .thenThrow(Exception('Database error'));

        await viewModel.loadGoals();

        final result = await viewModel.onDeleteGoalConfirmed(testGoal);

        expect(result, DeleteGoalResult.failure);
      });

      test('should not modify state when deletion fails', () async {
        when(() => mockStudyLogsDatasource.deleteLogsByGoalId(testGoal.id))
            .thenThrow(Exception('Database error'));

        await viewModel.loadGoals();
        final initialGoalsCount = viewModel.state.goals.length;

        await viewModel.onDeleteGoalConfirmed(testGoal);

        expect(viewModel.state.goals.length, initialGoalsCount);
      });
    });
  });
}
