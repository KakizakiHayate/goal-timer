import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/users/users_model.dart';
import '../../services/migration_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/user_consts.dart';
import '../local/app_database.dart';
import '../local/local_goals_datasource.dart';
import '../local/local_study_daily_logs_datasource.dart';
import '../local/local_users_datasource.dart';
import '../supabase/supabase_goals_datasource.dart';
import '../supabase/supabase_study_logs_datasource.dart';
import '../supabase/supabase_users_datasource.dart';

/// ユーザーデータのRepository
///
/// マイグレーションフラグに基づいてローカル/Supabaseを振り分ける。
/// - マイグレーション済み: Supabaseを使用
/// - マイグレーション未済: ローカルDBを使用
class UsersRepository {
  final LocalUsersDatasource _localDs;
  final SupabaseUsersDatasource _supabaseDs;
  final MigrationService _migrationService;

  UsersRepository({
    LocalUsersDatasource? localDs,
    SupabaseUsersDatasource? supabaseDs,
    MigrationService? migrationService,
  })  : _localDs = localDs ?? LocalUsersDatasource(database: AppDatabase()),
        _supabaseDs = supabaseDs ??
            SupabaseUsersDatasource(supabase: Supabase.instance.client),
        _migrationService =
            migrationService ?? _createDefaultMigrationService();

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
  UsersRepository.withDependencies({
    required LocalUsersDatasource localDs,
    required SupabaseUsersDatasource supabaseDs,
    required MigrationService migrationService,
  })  : _localDs = localDs,
        _supabaseDs = supabaseDs,
        _migrationService = migrationService;

  /// 最長ストリークを取得
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<int> getLongestStreak(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから最長ストリークを取得します');
      return _supabaseDs.getLongestStreak(userId);
    } else {
      AppLogger.instance.i('ローカルDBから最長ストリークを取得します');
      return _localDs.getLongestStreak();
    }
  }

  /// 最長ストリークを更新
  ///
  /// [streak] 新しい最長ストリーク
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<void> updateLongestStreak(int streak, String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseの最長ストリークを更新します: $streak');
      await _supabaseDs.updateLongestStreak(userId, streak);
    } else {
      AppLogger.instance.i('ローカルDBの最長ストリークを更新します: $streak');
      await _localDs.updateLongestStreak(streak);
    }
  }

  /// 現在のストリークが最長を超えていれば更新
  ///
  /// [currentStreak] 現在のストリーク
  /// [userId] ユーザーID（Supabase使用時に必要）
  /// 更新した場合はtrueを返す
  Future<bool> updateLongestStreakIfNeeded(
      int currentStreak, String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseの最長ストリークを条件付き更新します');
      final longestStreak = await _supabaseDs.getLongestStreak(userId);

      if (currentStreak > longestStreak) {
        await _supabaseDs.updateLongestStreak(userId, currentStreak);
        AppLogger.instance.i('最長ストリークを更新しました: $currentStreak');
        return true;
      }
      return false;
    } else {
      AppLogger.instance.i('ローカルDBの最長ストリークを条件付き更新します');
      return _localDs.updateLongestStreakIfNeeded(currentStreak);
    }
  }

  /// ストリークリマインダー通知の有効/無効を取得
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<bool> getStreakReminderEnabled(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseからストリークリマインダー設定を取得します');
      return _supabaseDs.getStreakReminderEnabled(userId);
    } else {
      AppLogger.instance.i('ローカルDBからストリークリマインダー設定を取得します');
      return _localDs.getStreakReminderEnabled();
    }
  }

  /// ストリークリマインダー通知の有効/無効を更新
  ///
  /// [enabled] 有効/無効
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<void> updateStreakReminderEnabled(bool enabled, String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance
          .i('Supabaseのストリークリマインダー設定を更新します: ${enabled ? "有効" : "無効"}');
      await _supabaseDs.updateStreakReminderEnabled(userId, enabled);
    } else {
      AppLogger.instance
          .i('ローカルDBのストリークリマインダー設定を更新します: ${enabled ? "有効" : "無効"}');
      await _localDs.updateStreakReminderEnabled(enabled);
    }
  }

  /// 表示名を取得
  ///
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<String> getDisplayName(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseから表示名を取得します');
      final displayName = await _supabaseDs.getDisplayName(userId);
      if (displayName == null || displayName.isEmpty) {
        return UserConsts.defaultGuestName;
      }
      return displayName;
    } else {
      AppLogger.instance.i('ローカルDBから表示名を取得します');
      return _localDs.getDisplayName();
    }
  }

  /// 表示名を更新
  ///
  /// [displayName] 新しい表示名
  /// [userId] ユーザーID（Supabase使用時に必要）
  Future<void> updateDisplayName(String displayName, String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseの表示名を更新します: $displayName');
      await _supabaseDs.updateDisplayName(userId, displayName);
    } else {
      AppLogger.instance.i('ローカルDBの表示名を更新します: $displayName');
      await _localDs.updateDisplayName(displayName);
    }
  }

  /// 表示名をデフォルト値にリセット
  ///
  /// サインアウトやアカウント削除時に呼び出す
  Future<void> resetDisplayName() async {
    // リセットはローカルDBでのみ実行（Supabaseの場合はユーザー削除で対応）
    AppLogger.instance.i('表示名をリセットします');
    await _localDs.resetDisplayName();
  }

  /// ユーザーを取得（Supabase専用）
  ///
  /// [userId] ユーザーID
  Future<UsersModel?> fetchUser(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseからユーザーを取得します');
      return _supabaseDs.fetchUser(userId);
    } else {
      // ローカルDBではUsersModelを返すAPIがないためnullを返す
      AppLogger.instance.w('ローカルDBではユーザーモデルの取得はサポートされていません');
      return null;
    }
  }

  /// ユーザーを作成または更新（Supabase専用）
  ///
  /// [user] 保存するユーザーモデル
  Future<UsersModel?> upsertUser(UsersModel user) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseにユーザーを保存します: ${user.id}');
      return _supabaseDs.upsertUser(user);
    } else {
      // ローカルDBではUsersModelをupsertするAPIがない
      AppLogger.instance.w('ローカルDBではユーザーモデルのupsertはサポートされていません');
      return null;
    }
  }

  /// 最終ログイン日時を更新（Supabase専用）
  ///
  /// [userId] ユーザーID
  Future<void> updateLastLogin(String userId) async {
    if (await _migrationService.isMigrated()) {
      AppLogger.instance.i('Supabaseの最終ログイン日時を更新します');
      await _supabaseDs.updateLastLogin(userId);
    } else {
      // ローカルDBでは最終ログイン日時を管理しない
      AppLogger.instance.i('ローカルDBでは最終ログイン日時の更新は不要です');
    }
  }
}
