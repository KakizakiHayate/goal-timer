import 'package:get/get.dart';

import '../../../core/data/repositories/goals_repository.dart';
import '../../../core/data/repositories/study_logs_repository.dart';
import '../../../core/models/goals/goals_model.dart';
import '../../../core/models/study_daily_logs/study_daily_logs_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/app_logger.dart';
import 'analytics_state.dart';

/// 分析画面のViewModel
///
/// 週/月単位の学習データを集計し、グラフ表示用のデータを提供する。
class AnalyticsViewModel extends GetxController {
  final GoalsRepository _goalsRepository;
  final StudyLogsRepository _studyLogsRepository;
  final AuthService _authService;

  AnalyticsState _state = AnalyticsState(
    startDate: DateTime.now(),
    endDate: DateTime.now(),
  );

  AnalyticsState get state => _state;

  AnalyticsViewModel({
    GoalsRepository? goalsRepository,
    StudyLogsRepository? studyLogsRepository,
    AuthService? authService,
  })  : _goalsRepository = goalsRepository ?? GoalsRepository(),
        _studyLogsRepository = studyLogsRepository ?? StudyLogsRepository(),
        _authService = authService ?? AuthService();

  String get _userId => _authService.currentUserId ?? '';

  /// データを読み込む
  ///
  /// [periodType] 表示期間タイプ（週/月）
  /// [referenceDate] 基準日（この日を含む週/月を表示）
  Future<void> loadData({
    required AnalyticsPeriodType periodType,
    required DateTime referenceDate,
  }) async {
    try {
      _state = _state.copyWith(isLoading: true);
      update();

      final dateRange = _calculateDateRange(
        periodType: periodType,
        referenceDate: referenceDate,
      );

      final results = await Future.wait([
        _goalsRepository.fetchActiveGoals(_userId),
        _studyLogsRepository.fetchLogsInRange(
          startDate: dateRange.start,
          endDate: dateRange.end,
          userId: _userId,
        ),
      ]);

      final activeGoals = results[0] as List<GoalsModel>;
      final logs = results[1] as List<StudyDailyLogsModel>;

      // createdAt順にソート（View側での毎回のソートを回避）
      final sortedGoals = List.of(activeGoals)
        ..sort((a, b) => (a.createdAt ?? DateTime.now())
            .compareTo(b.createdAt ?? DateTime.now()));

      final dailyData = _buildDailyData(
        startDate: dateRange.start,
        endDate: dateRange.end,
        logs: logs,
        activeGoalIds: sortedGoals.map((g) => g.id).toSet(),
      );

      _state = AnalyticsState(
        periodType: periodType,
        startDate: dateRange.start,
        endDate: dateRange.end,
        dailyData: dailyData,
        activeGoals: sortedGoals,
      );
      update();
    } catch (error, stackTrace) {
      AppLogger.instance.e('分析データの読み込みに失敗しました', error, stackTrace);
      _state = _state.copyWith(isLoading: false);
      update();
      rethrow;
    }
  }

  /// 前の期間に移動
  Future<void> goToPreviousPeriod() async {
    final newReferenceDate = _calculatePreviousReferenceDate();
    await loadData(
      periodType: _state.periodType,
      referenceDate: newReferenceDate,
    );
  }

  /// 次の期間に移動
  ///
  /// 現在の週/月より未来には進めない
  Future<void> goToNextPeriod() async {
    if (!_state.canGoForward) return;

    final newReferenceDate = _calculateNextReferenceDate();
    await loadData(
      periodType: _state.periodType,
      referenceDate: newReferenceDate,
    );
  }

  /// 期間タイプを切り替える（週↔月）
  Future<void> switchPeriodType(AnalyticsPeriodType newType) async {
    if (_state.periodType == newType) return;

    await loadData(
      periodType: newType,
      referenceDate: _state.startDate,
    );
  }

  /// 期間の開始日・終了日を計算
  _DateRange _calculateDateRange({
    required AnalyticsPeriodType periodType,
    required DateTime referenceDate,
  }) {
    switch (periodType) {
      case AnalyticsPeriodType.week:
        return _calculateWeekRange(referenceDate);
      case AnalyticsPeriodType.month:
        return _calculateMonthRange(referenceDate);
    }
  }

  /// 月曜始まりの週範囲を計算
  _DateRange _calculateWeekRange(DateTime date) {
    // DateTime.monday == 1, DateTime.sunday == 7
    final daysFromMonday = (date.weekday - DateTime.monday) % 7;
    final monday = DateTime(
      date.year,
      date.month,
      date.day - daysFromMonday,
    );
    final sunday = monday.add(const Duration(days: 6));
    return _DateRange(start: monday, end: sunday);
  }

  /// 月範囲を計算
  _DateRange _calculateMonthRange(DateTime date) {
    final firstDay = DateTime(date.year, date.month);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return _DateRange(start: firstDay, end: lastDay);
  }

  /// 前の期間の基準日を計算
  DateTime _calculatePreviousReferenceDate() {
    switch (_state.periodType) {
      case AnalyticsPeriodType.week:
        return _state.startDate.subtract(const Duration(days: 7));
      case AnalyticsPeriodType.month:
        return DateTime(
          _state.startDate.year,
          _state.startDate.month - 1,
        );
    }
  }

  /// 次の期間の基準日を計算
  DateTime _calculateNextReferenceDate() {
    switch (_state.periodType) {
      case AnalyticsPeriodType.week:
        return _state.startDate.add(const Duration(days: 7));
      case AnalyticsPeriodType.month:
        return DateTime(
          _state.startDate.year,
          _state.startDate.month + 1,
        );
    }
  }

  /// 日別データを構築
  ///
  /// 期間内の全日分のデータを生成し、学習ログを集計する。
  /// アクティブな目標のログのみを含める。
  /// ログを先に日付でグループ化し、日ごとのループを効率化する。
  List<DailyStudyData> _buildDailyData({
    required DateTime startDate,
    required DateTime endDate,
    required List<StudyDailyLogsModel> logs,
    required Set<String> activeGoalIds,
  }) {
    final dayCount = endDate.difference(startDate).inDays + 1;

    // ログを日付ごとにグループ化（O(n)で一度だけ走査）
    final logsByDate = <DateTime, List<StudyDailyLogsModel>>{};
    for (final log in logs) {
      final dateOnly = DateTime(
        log.studyDate.year,
        log.studyDate.month,
        log.studyDate.day,
      );
      (logsByDate[dateOnly] ??= []).add(log);
    }

    return List.generate(dayCount, (i) {
      final date = startDate.add(Duration(days: i));
      final dailyLogs = logsByDate[date] ?? [];
      final goalSeconds = _aggregateGoalSeconds(
        logs: dailyLogs,
        activeGoalIds: activeGoalIds,
      );
      return DailyStudyData(date: date, goalSeconds: goalSeconds);
    });
  }

  /// 特定日のアクティブ目標ごとの学習秒数を集計
  Map<String, int> _aggregateGoalSeconds({
    required List<StudyDailyLogsModel> logs,
    required Set<String> activeGoalIds,
  }) {
    final goalSeconds = <String, int>{};
    for (final log in logs) {
      if (!activeGoalIds.contains(log.goalId)) continue;
      goalSeconds[log.goalId] =
          (goalSeconds[log.goalId] ?? 0) + log.totalSeconds;
    }
    return goalSeconds;
  }
}

/// 期間の開始日・終了日を保持するヘルパークラス
class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}
