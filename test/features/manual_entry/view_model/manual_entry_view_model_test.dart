import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:goal_timer/core/data/repositories/study_logs_repository.dart';
import 'package:goal_timer/core/data/repositories/users_repository.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/models/study_daily_logs/study_daily_logs_model.dart';
import 'package:goal_timer/core/services/auth_service.dart';
import 'package:goal_timer/core/utils/streak_consts.dart';
import 'package:goal_timer/features/manual_entry/view_model/manual_entry_view_model.dart';
import 'package:mocktail/mocktail.dart';

class MockStudyLogsRepository extends Mock implements StudyLogsRepository {}

class MockUsersRepository extends Mock implements UsersRepository {}

class MockAuthService extends Mock implements AuthService {}

class FakeStudyDailyLogsModel extends Fake implements StudyDailyLogsModel {}

void main() {
  late MockStudyLogsRepository mockStudyLogsRepository;
  late MockUsersRepository mockUsersRepository;
  late MockAuthService mockAuthService;
  late GoalsModel testGoal;

  setUpAll(() {
    registerFallbackValue(FakeStudyDailyLogsModel());
  });

  setUp(() {
    mockStudyLogsRepository = MockStudyLogsRepository();
    mockUsersRepository = MockUsersRepository();
    mockAuthService = MockAuthService();
    testGoal = GoalsModel(
      id: 'test-goal-id',
      userId: 'test-user-id',
      title: 'Test Goal',
      description: 'Test Description',
      targetMinutes: 60,
      avoidMessage: 'Test avoid message',
      deadline: DateTime.now().add(const Duration(days: 30)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockAuthService.currentUserId).thenReturn('test-user-id');
  });

  ManualEntryViewModel createTestViewModel() {
    return ManualEntryViewModel(
      studyLogsRepository: mockStudyLogsRepository,
      usersRepository: mockUsersRepository,
      authService: mockAuthService,
    );
  }

  tearDown(() {
    Get.reset();
  });

  group('ManualEntryViewModel - 状態管理', () {
    test('初期状態では目標が未選択であること', () {
      final viewModel = createTestViewModel();
      expect(viewModel.selectedGoal, isNull);
      expect(viewModel.isGoalSelected, isFalse);
    });

    test('初期状態では学習時間がゼロであること', () {
      final viewModel = createTestViewModel();
      expect(viewModel.selectedDuration, Duration.zero);
      expect(viewModel.isTimeSelected, isFalse);
    });

    test('初期状態では学習日が今日であること', () {
      final viewModel = createTestViewModel();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(viewModel.selectedDate, today);
    });

    test('selectGoalで目標を設定できること', () {
      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      expect(viewModel.selectedGoal, testGoal);
      expect(viewModel.isGoalSelected, isTrue);
    });

    test('setDurationで学習時間を設定できること', () {
      final viewModel = createTestViewModel();
      viewModel.setDuration(const Duration(hours: 1, minutes: 30));
      expect(viewModel.selectedDuration, const Duration(hours: 1, minutes: 30));
      expect(viewModel.isTimeSelected, isTrue);
    });

    test('setDateで学習日を設定できること', () {
      final viewModel = createTestViewModel();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      viewModel.setDate(yesterday);
      final expectedDate =
          DateTime(yesterday.year, yesterday.month, yesterday.day);
      expect(viewModel.selectedDate, expectedDate);
    });
  });

  group('ManualEntryViewModel - バリデーション', () {
    test('目標未選択の場合canSaveがfalseであること', () {
      final viewModel = createTestViewModel();
      viewModel.setDuration(const Duration(minutes: 30));
      expect(viewModel.canSave, isFalse);
    });

    test('学習時間が0の場合canSaveがfalseであること', () {
      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      expect(viewModel.canSave, isFalse);
    });

    test('目標と学習時間が設定されている場合canSaveがtrueであること', () {
      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      viewModel.setDuration(const Duration(minutes: 30));
      expect(viewModel.canSave, isTrue);
    });

    test('未来の日付は設定できないこと', () {
      final viewModel = createTestViewModel();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      viewModel.setDate(tomorrow);
      expect(viewModel.selectedDate, today);
    });
  });

  group('ManualEntryViewModel - 保存処理', () {
    test('保存条件を満たさない場合saveがfalseを返すこと', () async {
      final viewModel = createTestViewModel();
      final result = await viewModel.save();
      expect(result, isFalse);
    });

    test('正常に保存できた場合saveがtrueを返すこと', () async {
      when(
        () => mockStudyLogsRepository.upsertLog(any()),
      ).thenAnswer((_) async => FakeStudyDailyLogsModel());

      when(
        () => mockStudyLogsRepository.calculateCurrentStreak(any()),
      ).thenAnswer((_) async => 1);

      when(
        () => mockUsersRepository.updateLongestStreakIfNeeded(any(), any()),
      ).thenAnswer((_) async => false);

      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      viewModel.setDuration(const Duration(minutes: 30));

      final result = await viewModel.save();

      expect(result, isTrue);
      verify(() => mockStudyLogsRepository.upsertLog(any())).called(1);
    });

    test('保存時にStudyDailyLogsModelが正しいパラメータで生成されること', () async {
      StudyDailyLogsModel? capturedLog;

      when(
        () => mockStudyLogsRepository.upsertLog(any()),
      ).thenAnswer((invocation) async {
        capturedLog =
            invocation.positionalArguments[0] as StudyDailyLogsModel;
        return FakeStudyDailyLogsModel();
      });

      when(
        () => mockStudyLogsRepository.calculateCurrentStreak(any()),
      ).thenAnswer((_) async => 1);

      when(
        () => mockUsersRepository.updateLongestStreakIfNeeded(any(), any()),
      ).thenAnswer((_) async => false);

      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      viewModel.setDuration(const Duration(hours: 1, minutes: 30));
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      viewModel.setDate(yesterday);

      await viewModel.save();

      expect(capturedLog, isNotNull);
      expect(capturedLog!.goalId, 'test-goal-id');
      expect(capturedLog!.totalSeconds, 5400);
      expect(capturedLog!.userId, 'test-user-id');
      final expectedDate =
          DateTime(yesterday.year, yesterday.month, yesterday.day);
      expect(capturedLog!.studyDate, expectedDate);
    });

    test('1分以上の学習時間でストリーク更新が呼ばれること', () async {
      when(
        () => mockStudyLogsRepository.upsertLog(any()),
      ).thenAnswer((_) async => FakeStudyDailyLogsModel());

      when(
        () => mockStudyLogsRepository.calculateCurrentStreak(any()),
      ).thenAnswer((_) async => 5);

      when(
        () => mockUsersRepository.updateLongestStreakIfNeeded(any(), any()),
      ).thenAnswer((_) async => true);

      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      viewModel.setDuration(
        Duration(seconds: StreakConsts.minStudySeconds),
      );

      await viewModel.save();

      verify(
        () => mockStudyLogsRepository.calculateCurrentStreak('test-user-id'),
      ).called(1);
      verify(
        () =>
            mockUsersRepository.updateLongestStreakIfNeeded(5, 'test-user-id'),
      ).called(1);
    });

    test('1分未満の学習時間ではストリーク更新が呼ばれないこと', () async {
      when(
        () => mockStudyLogsRepository.upsertLog(any()),
      ).thenAnswer((_) async => FakeStudyDailyLogsModel());

      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      viewModel.setDuration(
        Duration(seconds: StreakConsts.minStudySeconds - 1),
      );

      await viewModel.save();

      verifyNever(
        () => mockStudyLogsRepository.calculateCurrentStreak(any()),
      );
    });

    test('保存中はisSavingがtrueになること', () async {
      when(
        () => mockStudyLogsRepository.upsertLog(any()),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return FakeStudyDailyLogsModel();
      });

      when(
        () => mockStudyLogsRepository.calculateCurrentStreak(any()),
      ).thenAnswer((_) async => 1);

      when(
        () => mockUsersRepository.updateLongestStreakIfNeeded(any(), any()),
      ).thenAnswer((_) async => false);

      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      viewModel.setDuration(const Duration(minutes: 30));

      final future = viewModel.save();
      expect(viewModel.isSaving, isTrue);
      expect(viewModel.canSave, isFalse);

      await future;
      expect(viewModel.isSaving, isFalse);
    });

    test('保存失敗時にfalseを返しisSavingがfalseになること', () async {
      when(
        () => mockStudyLogsRepository.upsertLog(any()),
      ).thenThrow(Exception('DB error'));

      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      viewModel.setDuration(const Duration(minutes: 30));

      final result = await viewModel.save();

      expect(result, isFalse);
      expect(viewModel.isSaving, isFalse);
    });
  });

  group('ManualEntryViewModel - リセット', () {
    test('resetで全ての状態がリセットされること', () {
      final viewModel = createTestViewModel();
      viewModel.selectGoal(testGoal);
      viewModel.setDuration(const Duration(hours: 1));
      viewModel.setDate(DateTime.now().subtract(const Duration(days: 3)));

      viewModel.reset();

      expect(viewModel.selectedGoal, isNull);
      expect(viewModel.selectedDuration, Duration.zero);
      expect(viewModel.isSaving, isFalse);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(viewModel.selectedDate, today);
    });
  });
}
