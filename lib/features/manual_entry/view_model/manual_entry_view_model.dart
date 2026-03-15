import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/repositories/study_logs_repository.dart';
import '../../../core/data/repositories/users_repository.dart';
import '../../../core/models/goals/goals_model.dart';
import '../../../core/models/study_daily_logs/study_daily_logs_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/streak_consts.dart';

/// 手動学習時間入力のViewModel
class ManualEntryViewModel extends GetxController {
  final StudyLogsRepository _studyLogsRepository;
  final UsersRepository _usersRepository;
  final AuthService _authService;

  /// 選択された目標
  GoalsModel? _selectedGoal;
  GoalsModel? get selectedGoal => _selectedGoal;

  /// 選択された学習時間（Duration）
  Duration _selectedDuration = Duration.zero;
  Duration get selectedDuration => _selectedDuration;

  /// 選択された学習日
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  /// 保存中フラグ
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// 現在のユーザーID
  String? get _userId => _authService.currentUserId;

  /// Repositoryに渡す用のユーザーID（nullの場合は空文字）
  String get _userIdForRepository => _authService.currentUserId ?? '';

  /// コンストラクタ（DIパターン適用）
  ManualEntryViewModel({
    StudyLogsRepository? studyLogsRepository,
    UsersRepository? usersRepository,
    AuthService? authService,
  })  : _studyLogsRepository = studyLogsRepository ?? StudyLogsRepository(),
        _usersRepository = usersRepository ?? UsersRepository(),
        _authService = authService ?? AuthService();

  /// 目標を選択する
  void selectGoal(GoalsModel goal) {
    _selectedGoal = goal;
    update();
  }

  /// 学習時間を設定する
  void setDuration(Duration duration) {
    _selectedDuration = duration;
    update();
  }

  /// 学習日を設定する
  void setDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    // 未来の日付は設定不可
    if (dateOnly.isAfter(today)) {
      AppLogger.instance.w('未来の日付は選択できません: $date');
      return;
    }

    _selectedDate = dateOnly;
    update();
  }

  /// バリデーション: 目標が選択されているか
  bool get isGoalSelected => _selectedGoal != null;

  /// バリデーション: 学習時間が設定されているか（1分以上）
  bool get isTimeSelected => _selectedDuration.inSeconds > 0;

  /// バリデーション: 保存可能な状態か
  bool get canSave => isGoalSelected && isTimeSelected && !_isSaving;

  /// 学習記録を保存する
  ///
  /// 成功時はtrue、失敗時はfalseを返す
  Future<bool> save() async {
    if (!canSave) {
      AppLogger.instance.w('保存条件を満たしていません');
      return false;
    }

    _isSaving = true;
    update();

    try {
      final log = StudyDailyLogsModel(
        id: const Uuid().v4(),
        goalId: _selectedGoal!.id,
        studyDate: selectedDate,
        totalSeconds: _selectedDuration.inSeconds,
        userId: _userId,
      );

      await _studyLogsRepository.upsertLog(log);

      AppLogger.instance.i(
        '手動学習記録を保存しました: ${log.id}, '
        '目標: ${_selectedGoal!.title}, '
        '学習日: ${log.studyDate}, '
        '${_selectedDuration.inSeconds}秒',
      );

      // 1分以上学習した場合のみストリーク処理を実行
      if (_selectedDuration.inSeconds >= StreakConsts.minStudySeconds) {
        await _updateLongestStreakIfNeeded();
      }

      _isSaving = false;
      update();
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('手動学習記録の保存に失敗しました', error, stackTrace);
      _isSaving = false;
      update();
      return false;
    }
  }

  /// ストリーク更新処理
  Future<void> _updateLongestStreakIfNeeded() async {
    try {
      final userId = _userIdForRepository;

      final currentStreak =
          await _studyLogsRepository.calculateCurrentStreak(userId);

      final updated = await _usersRepository.updateLongestStreakIfNeeded(
        currentStreak,
        userId,
      );

      if (updated) {
        AppLogger.instance.i('最長ストリークを更新しました: $currentStreak日');
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e('最長ストリークの更新に失敗しました', error, stackTrace);
    }
  }

  /// 状態をリセットする
  void reset() {
    _selectedGoal = null;
    _selectedDuration = Duration.zero;
    _selectedDate = DateTime.now();
    _isSaving = false;
    update();
  }
}
