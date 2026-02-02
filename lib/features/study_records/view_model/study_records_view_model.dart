import 'package:get/get.dart';
import '../../../core/data/repositories/goals_repository.dart';
import '../../../core/data/repositories/study_logs_repository.dart';
import '../../../core/data/repositories/users_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/app_logger.dart';

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
    final localFirstStudyDate = firstStudyDate;
    if (localFirstStudyDate == null) return false;
    final firstMonth = DateTime(
      localFirstStudyDate.year,
      localFirstStudyDate.month,
    );
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
  final StudyLogsRepository _studyLogsRepository;
  final GoalsRepository _goalsRepository;
  final UsersRepository _usersRepository;
  final AuthService _authService;

  StudyRecordsState _state = StudyRecordsState(
    currentMonth: DateTime(DateTime.now().year, DateTime.now().month),
  );
  StudyRecordsState get state => _state;

  /// Repositoryに渡す用のユーザーID（nullの場合は空文字）
  ///
  /// マイグレーション済み（Supabase使用時）は必ず値が存在する。
  /// マイグレーション未済（ローカルDB使用時）はnullの場合があるため空文字を返す。
  String get _userIdForRepository => _authService.currentUserId ?? '';

  /// コンストラクタ（DIパターン適用）
  /// テスト時にはRepositoryを注入可能
  StudyRecordsViewModel({
    StudyLogsRepository? studyLogsRepository,
    GoalsRepository? goalsRepository,
    UsersRepository? usersRepository,
    AuthService? authService,
  }) : _studyLogsRepository = studyLogsRepository ?? StudyLogsRepository(),
       _goalsRepository = goalsRepository ?? GoalsRepository(),
       _usersRepository = usersRepository ?? UsersRepository(),
       _authService = authService ?? AuthService();

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
      final userId = _userIdForRepository;

      // 並列で取得（Dart 3 レコード構文で型安全に）
      final (firstStudyDate, currentStreak, longestStreak) =
          await (
            _studyLogsRepository.fetchFirstStudyDate(userId),
            _studyLogsRepository.calculateCurrentStreak(userId),
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
      final userId = _userIdForRepository;

      // 最長ストリークを取得
      final longestStreak = await _usersRepository.getLongestStreak(userId);

      // 最長ストリークが0の場合、履歴から計算して設定
      if (longestStreak == 0) {
        final historicalLongestStreak =
            await _studyLogsRepository.calculateHistoricalLongestStreak(userId);

        if (historicalLongestStreak > 0) {
          // 履歴から計算した最長ストリークを保存
          await _usersRepository.updateLongestStreak(
            historicalLongestStreak,
            userId,
          );
          AppLogger.instance.i(
            '最長ストリークを履歴から計算・保存しました: $historicalLongestStreak日',
          );
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

      final studyDates = await _studyLogsRepository.fetchStudyDatesInRange(
        startDate: startDate,
        endDate: endDate,
        userId: _userIdForRepository,
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
      final userId = _userIdForRepository;

      final records = await _studyLogsRepository.fetchDailyRecordsByDate(
        date,
        userId,
      );

      if (records.isEmpty) return [];

      // 目標情報を取得（削除済み含む）
      final goals = await _goalsRepository.fetchAllGoalsIncludingDeleted(
        userId,
      );
      final goalMap = {for (final goal in goals) goal.id: goal};

      final dailyRecords = <DailyRecord>[];
      for (final entry in records.entries) {
        final goal = goalMap[entry.key];
        dailyRecords.add(
          DailyRecord(
            goalId: entry.key,
            goalTitle: goal?.title ?? 'Deleted Goal',
            totalSeconds: entry.value,
            isDeleted: goal?.deletedAt != null || goal == null,
          ),
        );
      }

      return dailyRecords;
    } catch (e, stackTrace) {
      AppLogger.instance.e('日別学習記録の取得に失敗しました', e, stackTrace);
      return [];
    }
  }
}
