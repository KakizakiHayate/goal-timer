import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/goals/goals_model.dart';
import '../../services/migration_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/time_utils.dart';
import '../local/app_database.dart';
import '../local/local_goals_datasource.dart';
import '../local/local_study_daily_logs_datasource.dart';
import '../supabase/supabase_goals_datasource.dart';
import '../supabase/supabase_study_logs_datasource.dart';

/// 目標データのRepository
///
/// マイグレーションフラグに基づいてローカル/Supabaseを振り分ける。
/// - マイグレーション済み: Supabaseを使用
/// - マイグレーション未済: ローカルDBを使用
class GoalsRepository {
  final LocalGoalsDatasource _localDs;
  final SupabaseGoalsDatasource _supabaseDs;
  final MigrationService _migrationService;

  GoalsRepository({
    LocalGoalsDatasource? localDs,
    SupabaseGoalsDatasource? supabaseDs,
    MigrationService? migrationService,
  })  : _localDs = localDs ?? LocalGoalsDatasource(database: AppDatabase()),
        _supabaseDs = supabaseDs ??
            SupabaseGoalsDatasource(supabase: Supabase.instance.client),
        _migrationService = migrationService ?? _createDefaultMigrationService();

  /// デフォルトのMigrationServiceを作成
  static MigrationService _createDefaultMigrationService() {
    final database = AppDatabase();
    final supabase = Supabase.instance.client;

    return MigrationService(
      localGoalsDatasource: LocalGoalsDatasource(database: database),
      localStudyLogsDatasource:
          LocalStudyDailyLogsDatasource(database: database),
      supabaseGoalsDatasource: SupabaseGoalsDatasource(supabase: supabase),
      supabaseStudyLogsDatasource:
          SupabaseStudyLogsDatasource(supabase: supabase),
    );
  }

  /// テスト用コンストラクタ
  ///
  /// 全ての依存関係を明示的に注入できる
  GoalsRepository.withDependencies({
    required LocalGoalsDatasource localDs,
    required SupabaseGoalsDatasource supabaseDs,
    required MigrationService migrationService,
  })  : _localDs = localDs,
        _supabaseDs = supabaseDs,
        _migrationService = migrationService;

  /// 全ての目標を取得（削除済みを除く）
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<List<GoalsModel>> fetchAllGoals(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから目標を取得します');
      return _supabaseDs.fetchAllGoals(userId);
    } else {
      AppLogger.instance.i('ローカルDBから目標を取得します');
      return _localDs.fetchAllGoals();
    }
  }

  /// アクティブな目標を取得（削除済み・期限切れを除く）
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<List<GoalsModel>> fetchActiveGoals(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseからアクティブな目標を取得します');
      // Supabaseから全件取得してRepository内でフィルタリング
      final goals = await _supabaseDs.fetchAllGoals(userId);
      return goals
          .where((g) => g.deletedAt == null && g.expiredAt == null)
          .toList();
    } else {
      AppLogger.instance.i('ローカルDBからアクティブな目標を取得します');
      return _localDs.fetchActiveGoals();
    }
  }

  /// 特定の目標を取得
  ///
  /// [goalId] 目標ID
  /// [userId] ユーザーID（Supabase使用時に必要、ローカルでは未使用）
  Future<GoalsModel?> fetchGoalById(String goalId, String userId) async {
    if (await _migrationService.isMigrated()) {
      return _supabaseDs.fetchGoalById(goalId);
    } else {
      return _localDs.fetchGoalById(goalId);
    }
  }

  /// 目標を作成または更新
  ///
  /// [goal] 保存する目標モデル
  Future<GoalsModel> upsertGoal(GoalsModel goal) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseに目標を保存します: ${goal.id}');
      return _supabaseDs.upsertGoal(goal);
    } else {
      AppLogger.instance.i('ローカルDBに目標を保存します: ${goal.id}');
      await _localDs.saveGoal(goal);
      return goal;
    }
  }

  /// 目標を更新
  ///
  /// [goal] 更新する目標モデル
  Future<GoalsModel> updateGoal(GoalsModel goal) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseの目標を更新します: ${goal.id}');
      return _supabaseDs.upsertGoal(goal);
    } else {
      AppLogger.instance.i('ローカルDBの目標を更新します: ${goal.id}');
      await _localDs.updateGoal(goal);
      return goal;
    }
  }

  /// 目標を論理削除
  ///
  /// [goalId] 削除する目標のID
  Future<void> deleteGoal(String goalId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseの目標を削除します: $goalId');
      await _supabaseDs.deleteGoal(goalId);
    } else {
      AppLogger.instance.i('ローカルDBの目標を削除します: $goalId');
      await _localDs.deleteGoal(goalId);
    }
  }

  /// 期限切れの目標を更新（expiredAtを設定）
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<void> updateExpiredGoals(String userId) async {
    if (!await _migrationService.isMigrated()) {
      AppLogger.instance.i('ローカルDBの期限切れ目標を更新します');
      await _localDs.updateExpiredGoals();
      return;
    }

    AppLogger.instance.i('Supabaseの期限切れ目標を更新します');
    final goals = await _supabaseDs.fetchAllGoals(userId);
    await _updateExpiredGoalsInSupabase(goals);
  }

  /// Supabase上の期限切れ目標を更新
  Future<void> _updateExpiredGoalsInSupabase(List<GoalsModel> goals) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final goal in goals) {
      if (!_shouldMarkAsExpired(goal, today)) continue;

      final expiredGoal = goal.copyWith(expiredAt: now);
      await _supabaseDs.upsertGoal(expiredGoal);
    }
  }

  /// 目標を期限切れとしてマークすべきか判定
  bool _shouldMarkAsExpired(GoalsModel goal, DateTime today) {
    // 削除済み・既に期限切れ・完了済みを除く
    if (goal.deletedAt != null) return false;
    if (goal.expiredAt != null) return false;
    if (goal.completedAt != null) return false;
    // 期限が過去の目標を更新対象とする
    return goal.deadline.isBefore(today);
  }

  /// 既存目標のtotalTargetMinutesを計算・更新する
  ///
  /// Issue #111実装前に作成された目標に対応
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<void> populateMissingTotalTargetMinutes(String userId) async {
    if (!await _migrationService.isMigrated()) {
      AppLogger.instance.i('ローカルDBのtotalTargetMinutesを補完します');
      await _localDs.populateMissingTotalTargetMinutes();
      return;
    }

    AppLogger.instance.i('SupabaseのtotalTargetMinutesを補完します');
    final goals = await _supabaseDs.fetchAllGoals(userId);
    await _populateTotalTargetMinutesInSupabase(goals);
  }

  /// Supabase上の目標のtotalTargetMinutesを補完
  Future<void> _populateTotalTargetMinutesInSupabase(
    List<GoalsModel> goals,
  ) async {
    for (final goal in goals) {
      if (!_needsTotalTargetMinutes(goal)) continue;

      final remainingDays = TimeUtils.calculateRemainingDays(goal.deadline);
      final totalTargetMinutes = TimeUtils.calculateTotalTargetMinutes(
        targetMinutes: goal.targetMinutes,
        remainingDays: remainingDays,
      );

      final updatedGoal = goal.copyWith(totalTargetMinutes: totalTargetMinutes);
      await _supabaseDs.upsertGoal(updatedGoal);
    }
  }

  /// totalTargetMinutesの設定が必要か判定
  bool _needsTotalTargetMinutes(GoalsModel goal) {
    // 既に設定済みまたは削除済みの目標は対象外
    return goal.totalTargetMinutes == null && goal.deletedAt == null;
  }

  /// 削除済みを含む全ての目標を取得
  ///
  /// マイグレーション時などに使用
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<List<GoalsModel>> fetchAllGoalsIncludingDeleted(String userId) async {
    if (await _migrationService.isMigrated()) {
      // Supabaseでは削除済みも含めて取得するAPIがないため、
      // fetchAllGoalsを使用（Supabase側で論理削除をフィルタリングしている場合は要調整）
      return _supabaseDs.fetchAllGoals(userId);
    } else {
      return _localDs.fetchAllGoalsIncludingDeleted();
    }
  }
}
