import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/users/users_model.dart';
import '../../services/migration_service.dart';
import '../../utils/user_consts.dart';
import '../local/app_database.dart';
import '../local/local_goals_datasource.dart';
import '../local/local_study_daily_logs_datasource.dart';
import '../local/local_users_datasource.dart';
import '../supabase/supabase_goals_datasource.dart';
import '../supabase/supabase_study_logs_datasource.dart';
import '../supabase/supabase_users_datasource.dart';

class UsersRepository {
  late final LocalUsersDatasource _localDs;
  late final SupabaseUsersDatasource _supabaseDs;
  late final MigrationService _migrationService;

  UsersRepository({
    LocalUsersDatasource? localDs,
    SupabaseUsersDatasource? supabaseDs,
    MigrationService? migrationService,
  }) {
    final database = AppDatabase();
    _localDs = localDs ?? LocalUsersDatasource(database: database);
    _supabaseDs = supabaseDs ??
        SupabaseUsersDatasource(supabase: Supabase.instance.client);
    _migrationService = migrationService ??
        MigrationService(
          localGoalsDatasource:
              LocalGoalsDatasource(database: database),
          localStudyLogsDatasource:
              LocalStudyDailyLogsDatasource(database: database),
          supabaseGoalsDatasource:
              SupabaseGoalsDatasource(supabase: Supabase.instance.client),
          supabaseStudyLogsDatasource:
              SupabaseStudyLogsDatasource(
                supabase: Supabase.instance.client,
              ),
        );
  }

  Future<UsersModel?> fetchUser(String userId) async {
    if (await _migrationService.isMigrated()) {
      return _supabaseDs.fetchUser(userId);
    }
    return null;
  }

  Future<UsersModel> upsertUser(UsersModel user) async {
    if (await _migrationService.isMigrated()) {
      return _supabaseDs.upsertUser(user);
    }

    final displayName = user.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      await _localDs.updateDisplayName(displayName);
    }

    return user;
  }

  Future<String> getDisplayName(String userId) async {
    if (await _migrationService.isMigrated()) {
      final displayName = await _supabaseDs.getDisplayName(userId);
      if (displayName == null || displayName.isEmpty) {
        return UserConsts.defaultGuestName;
      }
      return displayName;
    }
    return _localDs.getDisplayName();
  }

  Future<void> updateDisplayName(String userId, String displayName) async {
    if (await _migrationService.isMigrated()) {
      await _supabaseDs.updateDisplayName(userId, displayName);
    } else {
      await _localDs.updateDisplayName(displayName);
    }
  }

  Future<void> updateLongestStreak(String userId, int streak) async {
    if (await _migrationService.isMigrated()) {
      await _supabaseDs.updateLongestStreak(userId, streak);
    } else {
      await _localDs.updateLongestStreak(streak);
    }
  }
}
