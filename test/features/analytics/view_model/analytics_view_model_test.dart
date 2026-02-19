import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/data/repositories/goals_repository.dart';
import 'package:goal_timer/core/data/repositories/study_logs_repository.dart';
import 'package:goal_timer/core/models/goals/goals_model.dart';
import 'package:goal_timer/core/models/study_daily_logs/study_daily_logs_model.dart';
import 'package:goal_timer/core/services/auth_service.dart';
import 'package:goal_timer/features/analytics/view_model/analytics_state.dart';
import 'package:goal_timer/features/analytics/view_model/analytics_view_model.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalsRepository extends Mock implements GoalsRepository {}

class MockStudyLogsRepository extends Mock implements StudyLogsRepository {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late AnalyticsViewModel viewModel;
  late MockGoalsRepository mockGoalsRepository;
  late MockStudyLogsRepository mockStudyLogsRepository;
  late MockAuthService mockAuthService;

  // テスト用の目標データ
  final activeGoal1 = GoalsModel(
    id: 'goal-1',
    userId: 'test-user',
    title: '数学',
    targetMinutes: 60,
    avoidMessage: 'テスト',
    deadline: DateTime(2027, 12, 31),
    createdAt: DateTime(2026, 1, 1),
  );

  final activeGoal2 = GoalsModel(
    id: 'goal-2',
    userId: 'test-user',
    title: '英語',
    targetMinutes: 30,
    avoidMessage: 'テスト',
    deadline: DateTime(2027, 12, 31),
    createdAt: DateTime(2026, 1, 2),
  );

  final completedGoal = GoalsModel(
    id: 'goal-completed',
    userId: 'test-user',
    title: '完了済み',
    targetMinutes: 60,
    avoidMessage: 'テスト',
    deadline: DateTime(2027, 12, 31),
    completedAt: DateTime(2026, 2, 1),
    createdAt: DateTime(2026, 1, 1),
  );

  final deletedGoal = GoalsModel(
    id: 'goal-deleted',
    userId: 'test-user',
    title: '削除済み',
    targetMinutes: 60,
    avoidMessage: 'テスト',
    deadline: DateTime(2027, 12, 31),
    deletedAt: DateTime(2026, 2, 1),
    createdAt: DateTime(2026, 1, 1),
  );

  // 2026-02-16（月曜日）を基準にテストデータを生成
  final monday = DateTime(2026, 2, 16);

  StudyDailyLogsModel createLog({
    required String goalId,
    required DateTime date,
    required int totalSeconds,
  }) {
    return StudyDailyLogsModel(
      id: 'log-$goalId-${date.day}',
      goalId: goalId,
      studyDate: date,
      totalSeconds: totalSeconds,
    );
  }

  setUp(() {
    mockGoalsRepository = MockGoalsRepository();
    mockStudyLogsRepository = MockStudyLogsRepository();
    mockAuthService = MockAuthService();

    when(() => mockAuthService.currentUserId).thenReturn('test-user');

    // デフォルトモック
    when(
      () => mockGoalsRepository.fetchActiveGoals(any()),
    ).thenAnswer((_) async => [activeGoal1, activeGoal2]);

    when(
      () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => []);

    viewModel = AnalyticsViewModel(
      goalsRepository: mockGoalsRepository,
      studyLogsRepository: mockStudyLogsRepository,
      authService: mockAuthService,
    );
  });

  group('AnalyticsViewModel', () {
    // UT-01: 週表示で学習ログがある場合、日別データが正しく集計される
    test('UT-01: 週表示で日別データが正しく集計される', () async {
      final logs = [
        createLog(goalId: 'goal-1', date: monday, totalSeconds: 1800),
        createLog(
          goalId: 'goal-2',
          date: monday,
          totalSeconds: 900,
        ),
        createLog(
          goalId: 'goal-1',
          date: monday.add(const Duration(days: 2)),
          totalSeconds: 3600,
        ),
      ];

      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => logs);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      final state = viewModel.state;
      expect(state.dailyData.length, 7);

      // 月曜日のデータ確認
      final mondayData = state.dailyData
          .firstWhere((d) => d.date.day == monday.day);
      expect(mondayData.goalSeconds['goal-1'], 1800);
      expect(mondayData.goalSeconds['goal-2'], 900);
      expect(mondayData.totalSeconds, 2700);

      // 水曜日のデータ確認
      final wednesdayData = state.dailyData
          .firstWhere((d) => d.date.day == monday.add(const Duration(days: 2)).day);
      expect(wednesdayData.goalSeconds['goal-1'], 3600);
      expect(wednesdayData.totalSeconds, 3600);
    });

    // UT-02: 月表示で学習ログがある場合、日別データが正しく集計される
    test('UT-02: 月表示で日別データが正しく集計される', () async {
      final feb1 = DateTime(2026, 2, 1);
      final feb15 = DateTime(2026, 2, 15);

      final logs = [
        createLog(goalId: 'goal-1', date: feb1, totalSeconds: 1800),
        createLog(goalId: 'goal-1', date: feb15, totalSeconds: 3600),
      ];

      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => logs);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.month,
        referenceDate: feb1,
      );

      final state = viewModel.state;
      // 2月は28日
      expect(state.dailyData.length, 28);
      expect(state.periodType, AnalyticsPeriodType.month);
    });

    // UT-03: 学習ログがない期間を選択した場合、空のデータが返る
    test('UT-03: 学習ログがない場合、空のデータが返る', () async {
      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => []);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      final state = viewModel.state;
      expect(state.isEmpty, true);
      expect(state.totalSeconds, 0);
      expect(state.studyDaysCount, 0);
    });

    // UT-04: 前の週/月に移動した場合、期間が正しく更新される
    test('UT-04: 前の週に移動すると期間が1週間前にずれる', () async {
      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      final originalStart = viewModel.state.startDate;

      await viewModel.goToPreviousPeriod();

      final newStart = viewModel.state.startDate;
      expect(
        originalStart.difference(newStart).inDays,
        7,
      );
    });

    // UT-05: 次の週/月に移動した場合、現在より未来には進めない
    test('UT-05: 現在の週/月より未来には進めない', () async {
      final now = DateTime.now();

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: now,
      );

      expect(viewModel.state.canGoForward, false);

      // goToNextPeriodを呼んでも変わらないことを確認
      final stateBefore = viewModel.state;
      await viewModel.goToNextPeriod();
      expect(viewModel.state.startDate, stateBefore.startDate);
    });

    // UT-06: 週/月の切り替え時にデータが再取得される
    test('UT-06: 週→月切り替えでデータが再取得される', () async {
      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      expect(viewModel.state.periodType, AnalyticsPeriodType.week);

      await viewModel.switchPeriodType(AnalyticsPeriodType.month);

      expect(viewModel.state.periodType, AnalyticsPeriodType.month);
      // fetchLogsInRangeが2回呼ばれる（初回 + 切り替え時）
      verify(
        () => mockStudyLogsRepository.fetchLogsInRange(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          userId: any(named: 'userId'),
        ),
      ).called(2);
    });

    // UT-07: サマリー（合計時間）が正しく計算される
    test('UT-07: 合計時間が正しく計算される', () async {
      final logs = [
        createLog(goalId: 'goal-1', date: monday, totalSeconds: 1800),
        createLog(goalId: 'goal-2', date: monday, totalSeconds: 900),
        createLog(
          goalId: 'goal-1',
          date: monday.add(const Duration(days: 1)),
          totalSeconds: 3600,
        ),
      ];

      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => logs);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      expect(viewModel.state.totalSeconds, 1800 + 900 + 3600);
    });

    // UT-08: サマリー（1日平均）が期間全日で割られる
    test('UT-08: 1日平均が期間全日で割られる', () async {
      final logs = [
        createLog(goalId: 'goal-1', date: monday, totalSeconds: 3500),
      ];

      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => logs);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      // 3500秒 ÷ 7日 = 500秒/日
      expect(viewModel.state.dailyAverageSeconds, 500);
    });

    // UT-09: サマリー（学習日数）が1秒以上の日をカウントする
    test('UT-09: 学習日数が正しくカウントされる', () async {
      final logs = [
        createLog(goalId: 'goal-1', date: monday, totalSeconds: 1),
        createLog(
          goalId: 'goal-1',
          date: monday.add(const Duration(days: 2)),
          totalSeconds: 3600,
        ),
        createLog(
          goalId: 'goal-1',
          date: monday.add(const Duration(days: 4)),
          totalSeconds: 60,
        ),
      ];

      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => logs);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      expect(viewModel.state.studyDaysCount, 3);
    });

    // UT-10: 完了済み目標のログが除外される
    test('UT-10: 完了済み目標のログが除外される', () async {
      when(
        () => mockGoalsRepository.fetchActiveGoals(any()),
      ).thenAnswer((_) async => [activeGoal1]);

      final logs = [
        createLog(goalId: 'goal-1', date: monday, totalSeconds: 1800),
        createLog(
          goalId: 'goal-completed',
          date: monday,
          totalSeconds: 3600,
        ),
      ];

      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => logs);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      final mondayData = viewModel.state.dailyData
          .firstWhere((d) => d.date.day == monday.day);

      // completedGoalのログは除外される
      expect(mondayData.goalSeconds.containsKey('goal-completed'), false);
      expect(mondayData.totalSeconds, 1800);
    });

    // UT-11: 削除済み目標のログが除外される
    test('UT-11: 削除済み目標のログが除外される', () async {
      when(
        () => mockGoalsRepository.fetchActiveGoals(any()),
      ).thenAnswer((_) async => [activeGoal1]);

      final logs = [
        createLog(goalId: 'goal-1', date: monday, totalSeconds: 1800),
        createLog(
          goalId: 'goal-deleted',
          date: monday,
          totalSeconds: 3600,
        ),
      ];

      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => logs);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      final mondayData = viewModel.state.dailyData
          .firstWhere((d) => d.date.day == monday.day);

      expect(mondayData.goalSeconds.containsKey('goal-deleted'), false);
      expect(mondayData.totalSeconds, 1800);
    });

    // UT-12: 色パレットが目標の作成順に割り当てられる
    test('UT-12: 色パレットが目標の作成順に割り当てられる', () {
      final color0 = AnalyticsColors.getColor(0);
      final color1 = AnalyticsColors.getColor(1);
      final color2 = AnalyticsColors.getColor(2);

      expect(color0, AnalyticsColors.lightPalette[0]); // 青
      expect(color1, AnalyticsColors.lightPalette[1]); // 緑
      expect(color2, AnalyticsColors.lightPalette[2]); // オレンジ
    });

    // UT-13: 9個以上の目標がある場合、色が循環する
    test('UT-13: 9個以上の目標で色が循環する', () {
      final color0 = AnalyticsColors.getColor(0);
      final color8 = AnalyticsColors.getColor(8);

      // 8色パレットなので8番目は0番目と同じ
      expect(color8, color0);
    });

    // UT-14: Y軸の単位が最大値に応じて自動切替される
    test('UT-14: Y軸の単位が自動切替される', () async {
      // 1時間未満のケース
      final logsUnder1h = [
        createLog(goalId: 'goal-1', date: monday, totalSeconds: 1800),
      ];

      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => logsUnder1h);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      expect(viewModel.state.useHoursUnit, false);

      // 1時間以上のケース
      final logsOver1h = [
        createLog(goalId: 'goal-1', date: monday, totalSeconds: 7200),
      ];

      when(
        () => mockStudyLogsRepository.fetchLogsInRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        userId: any(named: 'userId'),
      ),
      ).thenAnswer((_) async => logsOver1h);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: monday,
      );

      expect(viewModel.state.useHoursUnit, true);
    });

    // UT-15: 月曜始まりで週の範囲が正しく計算される
    test('UT-15: 月曜始まりで週の範囲が正しく計算される', () async {
      // 2026-02-18は水曜日
      final wednesday = DateTime(2026, 2, 18);

      await viewModel.loadData(
        periodType: AnalyticsPeriodType.week,
        referenceDate: wednesday,
      );

      final state = viewModel.state;
      // 月曜日: 2026-02-16
      expect(state.startDate.weekday, DateTime.monday);
      expect(state.startDate, DateTime(2026, 2, 16));
      // 日曜日: 2026-02-22
      expect(state.endDate.weekday, DateTime.sunday);
      expect(state.endDate, DateTime(2026, 2, 22));
    });
  });
}
