import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:goal_timer/core/data/local/local_goals_datasource.dart';
import 'package:goal_timer/core/data/local/local_study_daily_logs_datasource.dart';
import 'package:goal_timer/core/services/streak_service.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/features/study_records/view_model/study_records_view_model.dart';

class MockLocalStudyDailyLogsDatasource extends Mock
    implements LocalStudyDailyLogsDatasource {}

class MockLocalGoalsDatasource extends Mock implements LocalGoalsDatasource {}

class MockStreakService extends Mock implements StreakService {}

void main() {
  late StudyRecordsViewModel viewModel;
  late MockLocalStudyDailyLogsDatasource mockStudyLogsDatasource;
  late MockLocalGoalsDatasource mockGoalsDatasource;
  late MockStreakService mockStreakService;

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

  final testDeletedGoal = GoalsModel(
    id: 'deleted-goal-id',
    userId: null,
    title: 'Deleted Goal',
    description: 'Deleted Description',
    targetMinutes: 50,
    avoidMessage: 'Deleted avoid message',
    deadline: DateTime(2025, 12, 31),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    deletedAt: DateTime(2025, 6, 1),
  );

  setUp(() {
    mockStudyLogsDatasource = MockLocalStudyDailyLogsDatasource();
    mockGoalsDatasource = MockLocalGoalsDatasource();
    mockStreakService = MockStreakService();

    // Default mock behaviors
    when(() => mockStudyLogsDatasource.fetchFirstStudyDate())
        .thenAnswer((_) async => DateTime(2025, 1, 1));
    when(() => mockStreakService.getCurrentStreak())
        .thenAnswer((_) async => 5);
    when(() => mockStreakService.getOrCalculateLongestStreak())
        .thenAnswer((_) async => 10);
    when(() => mockStudyLogsDatasource.fetchStudyDatesInRange(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => [DateTime(2025, 12, 1), DateTime(2025, 12, 15)]);

    viewModel = StudyRecordsViewModel(
      studyLogsDatasource: mockStudyLogsDatasource,
      goalsDatasource: mockGoalsDatasource,
      streakService: mockStreakService,
    );
  });

  group('StudyRecordsViewModel', () {
    group('初期化', () {
      test('初期状態が正しく設定されること', () {
        final now = DateTime.now();
        expect(viewModel.state.currentMonth.year, now.year);
        expect(viewModel.state.currentMonth.month, now.month);
        expect(viewModel.state.studyDates, isEmpty);
        expect(viewModel.state.currentStreak, 0);
        expect(viewModel.state.longestStreak, 0);
        expect(viewModel.state.isLoading, false);
      });
    });

    group('goToPreviousMonth', () {
      test('前月に移動できること', () async {
        // Set up initial state with firstStudyDate in the past
        when(() => mockStudyLogsDatasource.fetchFirstStudyDate())
            .thenAnswer((_) async => DateTime(2024, 1, 1));

        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        final currentMonth = viewModel.state.currentMonth;

        await viewModel.goToPreviousMonth();

        expect(viewModel.state.currentMonth.month, currentMonth.month - 1);
        verify(() => mockStudyLogsDatasource.fetchStudyDatesInRange(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).called(greaterThan(1));
      });

      test('最初の学習日より前には移動できないこと', () async {
        final now = DateTime.now();
        final firstStudyDate = DateTime(now.year, now.month);

        when(() => mockStudyLogsDatasource.fetchFirstStudyDate())
            .thenAnswer((_) async => firstStudyDate);

        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.state.canGoPrevious, false);
      });
    });

    group('goToNextMonth', () {
      test('今月より先には移動できないこと', () async {
        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.state.canGoNext, false);
      });

      test('過去の月から次月に移動できること', () async {
        final now = DateTime.now();
        final pastMonth = DateTime(now.year, now.month - 2);

        when(() => mockStudyLogsDatasource.fetchFirstStudyDate())
            .thenAnswer((_) async => pastMonth);

        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        // Move to previous month first
        await viewModel.goToPreviousMonth();
        await viewModel.goToPreviousMonth();

        expect(viewModel.state.canGoNext, true);

        await viewModel.goToNextMonth();

        // Should have moved forward one month
        verify(() => mockStudyLogsDatasource.fetchStudyDatesInRange(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).called(greaterThan(1));
      });
    });

    group('hasStudyRecord', () {
      test('学習記録がある日はtrueを返すこと', () async {
        final studyDate = DateTime(2025, 12, 1);
        when(() => mockStudyLogsDatasource.fetchStudyDatesInRange(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => [studyDate]);

        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.hasStudyRecord(studyDate), true);
      });

      test('学習記録がない日はfalseを返すこと', () async {
        when(() => mockStudyLogsDatasource.fetchStudyDatesInRange(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => [DateTime(2025, 12, 1)]);

        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(viewModel.hasStudyRecord(DateTime(2025, 12, 2)), false);
      });
    });

    group('fetchDailyRecords', () {
      test('指定日の学習記録を取得できること', () async {
        final testDate = DateTime(2025, 12, 1);
        final records = {'test-goal-id': 3600}; // 1時間

        when(() => mockStudyLogsDatasource.fetchDailyRecordsByDate(testDate))
            .thenAnswer((_) async => records);
        when(() => mockGoalsDatasource.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testGoal]);

        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await viewModel.fetchDailyRecords(testDate);

        expect(result.length, 1);
        expect(result.first.goalId, 'test-goal-id');
        expect(result.first.goalTitle, 'Test Goal');
        expect(result.first.totalSeconds, 3600);
        expect(result.first.isDeleted, false);
      });

      test('削除された目標の記録も取得できること', () async {
        final testDate = DateTime(2025, 12, 1);
        final records = {'deleted-goal-id': 1800}; // 30分

        when(() => mockStudyLogsDatasource.fetchDailyRecordsByDate(testDate))
            .thenAnswer((_) async => records);
        when(() => mockGoalsDatasource.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => [testDeletedGoal]);

        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await viewModel.fetchDailyRecords(testDate);

        expect(result.length, 1);
        expect(result.first.goalId, 'deleted-goal-id');
        expect(result.first.goalTitle, 'Deleted Goal');
        expect(result.first.isDeleted, true);
      });

      test('存在しない目標の記録は「削除された目標」として表示されること', () async {
        final testDate = DateTime(2025, 12, 1);
        final records = {'unknown-goal-id': 1200};

        when(() => mockStudyLogsDatasource.fetchDailyRecordsByDate(testDate))
            .thenAnswer((_) async => records);
        when(() => mockGoalsDatasource.fetchAllGoalsIncludingDeleted())
            .thenAnswer((_) async => []); // No goals found

        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await viewModel.fetchDailyRecords(testDate);

        expect(result.length, 1);
        expect(result.first.goalTitle, '削除された目標');
        expect(result.first.isDeleted, true);
      });

      test('学習記録がない場合は空リストを返すこと', () async {
        final testDate = DateTime(2025, 12, 1);

        when(() => mockStudyLogsDatasource.fetchDailyRecordsByDate(testDate))
            .thenAnswer((_) async => {});

        viewModel.onInit();
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await viewModel.fetchDailyRecords(testDate);

        expect(result, isEmpty);
      });
    });

    group('StudyRecordsState', () {
      test('canGoPreviousが正しく計算されること', () {
        final state = StudyRecordsState(
          currentMonth: DateTime(2025, 6),
          firstStudyDate: DateTime(2025, 1),
        );

        expect(state.canGoPrevious, true);
      });

      test('firstStudyDateがnullの場合canGoPreviousはfalseになること', () {
        final state = StudyRecordsState(
          currentMonth: DateTime(2025, 6),
        );

        expect(state.canGoPrevious, false);
      });

      test('canGoNextが正しく計算されること', () {
        final now = DateTime.now();
        final pastMonth = DateTime(now.year, now.month - 1);

        final state = StudyRecordsState(
          currentMonth: pastMonth,
        );

        expect(state.canGoNext, true);
      });

      test('今月の場合canGoNextはfalseになること', () {
        final now = DateTime.now();

        final state = StudyRecordsState(
          currentMonth: DateTime(now.year, now.month),
        );

        expect(state.canGoNext, false);
      });
    });
  });
}
