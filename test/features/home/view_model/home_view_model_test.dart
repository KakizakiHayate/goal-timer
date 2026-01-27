import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/repositories/goals_repository.dart';
import 'package:goal_timer/core/data/repositories/study_logs_repository.dart';
import 'package:goal_timer/core/data/repositories/users_repository.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/services/auth_service.dart';
import 'package:goal_timer/core/services/crashlytics_service.dart';
import 'package:goal_timer/features/home/view_model/home_view_model.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalsRepository extends Mock implements GoalsRepository {}

class MockStudyLogsRepository extends Mock implements StudyLogsRepository {}

class MockUsersRepository extends Mock implements UsersRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockCrashlyticsService extends Mock implements CrashlyticsService {}

class FakeGoalsModel extends Fake implements GoalsModel {}

class FakeStackTrace extends Fake implements StackTrace {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGoalsModel());
    registerFallbackValue(FakeStackTrace());
    registerFallbackValue(Exception('fallback error'));
  });
  late HomeViewModel viewModel;
  late MockGoalsRepository mockGoalsRepository;
  late MockStudyLogsRepository mockStudyLogsRepository;
  late MockUsersRepository mockUsersRepository;
  late MockAuthService mockAuthService;
  late MockCrashlyticsService mockCrashlyticsService;

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
    mockGoalsRepository = MockGoalsRepository();
    mockStudyLogsRepository = MockStudyLogsRepository();
    mockUsersRepository = MockUsersRepository();
    mockAuthService = MockAuthService();
    mockCrashlyticsService = MockCrashlyticsService();

    // AuthService mock
    when(() => mockAuthService.currentUserId).thenReturn('test-user-id');

    // CrashlyticsService mock
    when(
      () => mockCrashlyticsService.sendFailedGoalData(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockCrashlyticsService.sendFailedGoalDelete(any(), any(), any()),
    ).thenAnswer((_) async {});

    when(
      () => mockGoalsRepository.fetchActiveGoals(any()),
    ).thenAnswer((_) async => [testGoal, testGoal2]);

    when(
      () => mockGoalsRepository.fetchAllGoals(any()),
    ).thenAnswer((_) async => [testGoal, testGoal2]);

    when(
      () => mockGoalsRepository.updateExpiredGoals(any()),
    ).thenAnswer((_) async {});

    when(
      () => mockGoalsRepository.populateMissingTotalTargetMinutes(any()),
    ).thenAnswer((_) async {});

    when(
      () => mockStudyLogsRepository.fetchTotalSecondsForAllGoals(any()),
    ).thenAnswer((_) async => <String, int>{});

    when(
      () => mockStudyLogsRepository.fetchStudyDatesInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => <DateTime>[]);

    when(
      () => mockStudyLogsRepository.calculateCurrentStreak(any()),
    ).thenAnswer((_) async => 0);

    when(
      () => mockUsersRepository.getDisplayName(any()),
    ).thenAnswer((_) async => 'テストユーザー');

    viewModel = HomeViewModel(
      goalsRepository: mockGoalsRepository,
      studyLogsRepository: mockStudyLogsRepository,
      usersRepository: mockUsersRepository,
      authService: mockAuthService,
      crashlyticsService: mockCrashlyticsService,
    );
  });

  group('HomeViewModel', () {
    group('onDeleteGoalConfirmed', () {
      test('should delete goal only (preserving study logs)', () async {
        when(
          () => mockGoalsRepository.deleteGoal(testGoal.id),
        ).thenAnswer((_) async {});

        await viewModel.loadGoals();
        expect(viewModel.state.goals.length, 2);

        final result = await viewModel.onDeleteGoalConfirmed(testGoal);

        expect(result, DeleteGoalResult.success);
        verify(() => mockGoalsRepository.deleteGoal(testGoal.id)).called(1);
      });

      test('should remove goal from state after deletion', () async {
        when(
          () => mockGoalsRepository.deleteGoal(testGoal.id),
        ).thenAnswer((_) async {});

        await viewModel.loadGoals();
        expect(viewModel.state.goals.length, 2);
        expect(viewModel.state.goals.any((g) => g.id == testGoal.id), isTrue);

        final result = await viewModel.onDeleteGoalConfirmed(testGoal);

        expect(result, DeleteGoalResult.success);
        expect(viewModel.state.goals.length, 1);
        expect(viewModel.state.goals.any((g) => g.id == testGoal.id), isFalse);
        expect(viewModel.state.goals.any((g) => g.id == testGoal2.id), isTrue);
      });

      test('should return failure when deletion fails', () async {
        when(
          () => mockGoalsRepository.deleteGoal(testGoal.id),
        ).thenThrow(Exception('Database error'));

        await viewModel.loadGoals();

        final result = await viewModel.onDeleteGoalConfirmed(testGoal);

        expect(result, DeleteGoalResult.failure);
      });

      test('should not modify state when deletion fails', () async {
        when(
          () => mockGoalsRepository.deleteGoal(testGoal.id),
        ).thenThrow(Exception('Database error'));

        await viewModel.loadGoals();
        final initialGoalsCount = viewModel.state.goals.length;

        await viewModel.onDeleteGoalConfirmed(testGoal);

        expect(viewModel.state.goals.length, initialGoalsCount);
      });
    });
  });
}
