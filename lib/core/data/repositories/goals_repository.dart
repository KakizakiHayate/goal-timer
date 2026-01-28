import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/goals/goals_model.dart';
import '../../services/migration_service.dart';
import '../../utils/time_utils.dart';
import '../local/app_database.dart';
import '../local/local_goals_datasource.dart';
import '../local/local_study_daily_logs_datasource.dart';
import '../supabase/supabase_goals_datasource.dart';
import '../supabase/supabase_study_logs_datasource.dart';

class GoalsRepository {
  late final LocalGoalsDatasource _localDs;
  late final SupabaseGoalsDatasource _supabaseDs;
  late final MigrationService _migrationService;

  GoalsRepository({
    LocalGoalsDatasource? localDs,
    SupabaseGoalsDatasource? supabaseDs,
    MigrationService? migrationService,
  }) {
    final database = AppDatabase();
    _localDs = localDs ?? LocalGoalsDatasource(database: database);
    _supabaseDs = supabaseDs ??
        SupabaseGoalsDatasource(supabase: Supabase.instance.client);
    _migrationService = migrationService ??
        MigrationService(
          localGoalsDatasource: _localDs,
          localStudyLogsDatasource:
              LocalStudyDailyLogsDatasource(database: database),
          supabaseGoalsDatasource: _supabaseDs,
          supabaseStudyLogsDatasource:
              SupabaseStudyLogsDatasource(
                supabase: Supabase.instance.client,
              ),
        );
  }

  Future<List<GoalsModel>> fetchAllGoals(String userId) async {
    if (await _migrationService.isMigrated()) {
      return _supabaseDs.fetchAllGoals(userId);
    }
    return _localDs.fetchAllGoals();
  }

  Future<List<GoalsModel>> fetchActiveGoals(String userId) async {
    if (await _migrationService.isMigrated()) {
      final goals = await _supabaseDs.fetchAllGoals(userId);
      return goals
          .where((goal) => goal.deletedAt == null && goal.expiredAt == null)
          .toList();
    }
    return _localDs.fetchActiveGoals();
  }

  Future<GoalsModel?> fetchGoalById(String goalId, String userId) async {
    if (await _migrationService.isMigrated()) {
      return _supabaseDs.fetchGoalById(goalId);
    }
    return _localDs.fetchGoalById(goalId);
  }

  Future<GoalsModel> upsertGoal(GoalsModel goal) async {
    if (await _migrationService.isMigrated()) {
      return _supabaseDs.upsertGoal(goal);
    }

    final existing = await _localDs.fetchGoalById(goal.id);
    if (existing == null) {
      await _localDs.saveGoal(goal);
    } else {
      await _localDs.updateGoal(goal);
    }
    return goal;
  }

  Future<void> deleteGoal(String goalId) async {
    if (await _migrationService.isMigrated()) {
      await _supabaseDs.deleteGoal(goalId);
    } else {
      await _localDs.deleteGoal(goalId);
    }
  }

  Future<void> updateExpiredGoals(String userId) async {
    if (!await _migrationService.isMigrated()) {
      await _localDs.updateExpiredGoals();
      return;
    }

    final goals = await _supabaseDs.fetchAllGoals(userId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final goal in goals) {
      if (!_shouldMarkAsExpired(goal, today)) continue;
      await _supabaseDs.upsertGoal(goal.copyWith(expiredAt: now));
    }
  }

  bool _shouldMarkAsExpired(GoalsModel goal, DateTime today) {
    final deadlineDate = DateTime(
      goal.deadline.year,
      goal.deadline.month,
      goal.deadline.day,
    );
    final isExpired = deadlineDate.isBefore(today);
    return goal.deletedAt == null &&
        goal.expiredAt == null &&
        goal.completedAt == null &&
        isExpired;
  }

  Future<void> populateMissingTotalTargetMinutes(String userId) async {
    if (!await _migrationService.isMigrated()) {
      await _localDs.populateMissingTotalTargetMinutes();
      return;
    }

    final goals = await _supabaseDs.fetchAllGoals(userId);

    for (final goal in goals) {
      if (_shouldSkipTotalTargetMinutesUpdate(goal)) continue;
      await _updateGoalWithTotalTargetMinutes(goal);
    }
  }

  bool _shouldSkipTotalTargetMinutesUpdate(GoalsModel goal) {
    return goal.deletedAt != null || goal.totalTargetMinutes != null;
  }

  Future<void> _updateGoalWithTotalTargetMinutes(GoalsModel goal) async {
    final remainingDays = TimeUtils.calculateRemainingDays(goal.deadline);
    final totalTargetMinutes = TimeUtils.calculateTotalTargetMinutes(
      targetMinutes: goal.targetMinutes,
      remainingDays: remainingDays,
    );
    await _supabaseDs.upsertGoal(
      goal.copyWith(totalTargetMinutes: totalTargetMinutes),
    );
  }
}
