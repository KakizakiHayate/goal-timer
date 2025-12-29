import 'package:get/get.dart';
import 'package:goal_timer/core/data/local/app_database.dart';
import 'package:goal_timer/core/data/local/local_goals_datasource.dart';
import 'package:goal_timer/core/data/local/local_study_daily_logs_datasource.dart';
import 'package:goal_timer/core/data/local/local_users_datasource.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

/// 日別学習記録データ
class DailyRecord {
  final String goalId;
  final String goalTitle;
  final int totalSeconds;
  final bool isDeleted;

  const DailyRecord({
    required this.goalId,
    required this.goalTitle,
    required this.totalSeconds,
    required this.isDeleted,
  });
}

/// 学習記録画面の状態
class StudyRecordsState {
  final DateTime currentMonth;
  final List<DateTime> studyDates;
  final int currentStreak;
  final int longestStreak;
  final DateTime? firstStudyDate;
  final bool isLoading;

  const StudyRecordsState({
    required this.currentMonth,
    this.studyDates = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.firstStudyDate,
    this.isLoading = false,
  });

  StudyRecordsState copyWith({
    DateTime? currentMonth,
    List<DateTime>? studyDates,
    int? currentStreak,
    int? longestStreak,
    DateTime? firstStudyDate,
    bool? isLoading,
  }) {
    return StudyRecordsState(
      currentMonth: currentMonth ?? this.currentMonth,
      studyDates: studyDates ?? this.studyDates,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      firstStudyDate: firstStudyDate ?? this.firstStudyDate,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// 前月に遷移可能か
  bool get canGoPrevious {
    if (firstStudyDate == null) return false;
    final firstMonth = DateTime(firstStudyDate!.year, firstStudyDate!.month);
    return currentMonth.isAfter(firstMonth);
  }

  /// 次月に遷移可能か（今月より先には行けない）
  bool get canGoNext {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    return currentMonth.isBefore(thisMonth);
  }
}

/// 学習記録画面のViewModel
class StudyRecordsViewModel extends GetxController {
  final LocalStudyDailyLogsDatasource _studyLogsDatasource;
  final LocalGoalsDatasource _goalsDatasource;
  final LocalUsersDatasource _usersDatasource;

  StudyRecordsState _state = StudyRecordsState(
    currentMonth: DateTime(DateTime.now().year, DateTime.now().month),
  );
  StudyRecordsState get state => _state;

  /// コンストラクタ（DIパターン適用）
  /// テスト時にはDataSourceを注入可能
  StudyRecordsViewModel({
    LocalStudyDailyLogsDatasource? studyLogsDatasource,
    LocalGoalsDatasource? goalsDatasource,
    LocalUsersDatasource? usersDatasource,
  })  : _studyLogsDatasource = studyLogsDatasource ??
            LocalStudyDailyLogsDatasource(database: AppDatabase()),
        _goalsDatasource =
            goalsDatasource ?? LocalGoalsDatasource(database: AppDatabase()),
        _usersDatasource =
            usersDatasource ?? LocalUsersDatasource(database: AppDatabase());

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  /// 初期データを読み込む
  Future<void> _loadInitialData() async {
    _state = _state.copyWith(isLoading: true);
    update();

    try {
      // 並列で取得（Dart 3 レコード構文で型安全に）
      final (firstStudyDate, currentStreak, longestStreak) = await (
        _studyLogsDatasource.fetchFirstStudyDate(),
        _studyLogsDatasource.calculateCurrentStreak(),
        _getOrCalculateLongestStreak(),
      ).wait;

      _state = _state.copyWith(
        firstStudyDate: firstStudyDate,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
      );

      // 現在の月の学習日を取得
      await _loadStudyDatesForCurrentMonth();
    } catch (e, stackTrace) {
      AppLogger.instance.e('初期データの読み込みに失敗しました', e, stackTrace);
    } finally {
      _state = _state.copyWith(isLoading: false);
      update();
    }
  }

  /// 最長ストリークを取得する
  /// データがない場合は履歴から計算して保存し、その値を返す
  Future<int> _getOrCalculateLongestStreak() async {
    try {
      // 最長ストリークを取得
      final longestStreak = await _usersDatasource.getLongestStreak();

      // 最長ストリークが0の場合、履歴から計算して設定
      if (longestStreak == 0) {
        final historicalLongestStreak =
            await _studyLogsDatasource.calculateHistoricalLongestStreak();

        if (historicalLongestStreak > 0) {
          // 履歴から計算した最長ストリークを保存
          await _usersDatasource.updateLongestStreak(historicalLongestStreak);
          AppLogger.instance
              .i('最長ストリークを履歴から計算・保存しました: $historicalLongestStreak日');
          return historicalLongestStreak;
        }
      }

      return longestStreak;
    } catch (error, stackTrace) {
      AppLogger.instance.e('最長ストリークの取得に失敗しました', error, stackTrace);
      return 0;
    }
  }

  /// 現在の月の学習日を読み込む
  Future<void> _loadStudyDatesForCurrentMonth() async {
    try {
      final startDate = DateTime(
        _state.currentMonth.year,
        _state.currentMonth.month,
        1,
      );
      final endDate = DateTime(
        _state.currentMonth.year,
        _state.currentMonth.month + 1,
        0,
      );

      final studyDates = await _studyLogsDatasource.fetchStudyDatesInRange(
        startDate: startDate,
        endDate: endDate,
      );

      _state = _state.copyWith(studyDates: studyDates);
      update();
    } catch (e, stackTrace) {
      AppLogger.instance.e('学習日の取得に失敗しました', e, stackTrace);
    }
  }

  /// 前月に移動
  Future<void> goToPreviousMonth() async {
    if (!_state.canGoPrevious) return;

    final newMonth = DateTime(
      _state.currentMonth.year,
      _state.currentMonth.month - 1,
    );
    _state = _state.copyWith(currentMonth: newMonth);
    update();

    await _loadStudyDatesForCurrentMonth();
  }

  /// 次月に移動
  Future<void> goToNextMonth() async {
    if (!_state.canGoNext) return;

    final newMonth = DateTime(
      _state.currentMonth.year,
      _state.currentMonth.month + 1,
    );
    _state = _state.copyWith(currentMonth: newMonth);
    update();

    await _loadStudyDatesForCurrentMonth();
  }

  /// 指定した日に学習記録があるか確認
  bool hasStudyRecord(DateTime date) {
    return _state.studyDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  /// 指定日の学習記録を取得
  Future<List<DailyRecord>> fetchDailyRecords(DateTime date) async {
    try {
      final records = await _studyLogsDatasource.fetchDailyRecordsByDate(date);

      if (records.isEmpty) return [];

      // 目標情報を取得（削除済み含む）
      final goals = await _goalsDatasource.fetchAllGoalsIncludingDeleted();
      final goalMap = {for (final goal in goals) goal.id: goal};

      final dailyRecords = <DailyRecord>[];
      for (final entry in records.entries) {
        final goal = goalMap[entry.key];
        dailyRecords.add(DailyRecord(
          goalId: entry.key,
          goalTitle: goal?.title ?? '削除された目標',
          totalSeconds: entry.value,
          isDeleted: goal?.deletedAt != null || goal == null,
        ));
      }

      return dailyRecords;
    } catch (e, stackTrace) {
      AppLogger.instance.e('日別学習記録の取得に失敗しました', e, stackTrace);
      return [];
    }
  }
}
