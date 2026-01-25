import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/local_settings_datasource.dart';
import '../../../core/data/local/local_users_datasource.dart';
import '../../../core/data/supabase/supabase_auth_datasource.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/streak_reminder_consts.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/utils/user_consts.dart';

/// 設定画面のViewModel
/// MVVM準拠: DataSource経由でデータアクセス
class SettingsViewModel extends GetxController {
  late final LocalSettingsDataSource _datasource;
  late final LocalUsersDatasource _usersDatasource;
  late final NotificationService _notificationService;
  late final SupabaseAuthDatasource _authDatasource;

  final RxInt defaultTimerSeconds =
      LocalSettingsDataSource.defaultTimerSeconds.obs;
  final RxBool streakReminderEnabled =
      StreakReminderConsts.defaultReminderEnabled.obs;
  final RxString displayName = UserConsts.defaultGuestName.obs;
  final RxBool isUpdatingDisplayName = false.obs;

  SettingsViewModel({
    LocalUsersDatasource? usersDatasource,
    NotificationService? notificationService,
    SupabaseAuthDatasource? authDatasource,
  }) {
    _datasource = LocalSettingsDataSource();
    _usersDatasource =
        usersDatasource ??
        LocalUsersDatasource(database: Get.find<AppDatabase>());
    _notificationService = notificationService ?? NotificationService();
    _authDatasource = authDatasource ??
        SupabaseAuthDatasource(supabase: Supabase.instance.client);
  }

  /// 初期化: SharedPreferencesとDBから設定を読み込む
  Future<void> init() async {
    final seconds = await _datasource.fetchDefaultTimerSeconds();
    defaultTimerSeconds.value = seconds;

    final reminderEnabled = await _usersDatasource.getStreakReminderEnabled();
    streakReminderEnabled.value = reminderEnabled;

    final name = await _usersDatasource.getDisplayName();
    displayName.value = name;
  }

  /// デフォルトタイマー時間を更新
  Future<void> updateDefaultTimerDuration(Duration duration) async {
    final seconds = duration.inSeconds.clamp(
      LocalSettingsDataSource.minTimerSeconds,
      LocalSettingsDataSource.maxTimerSeconds,
    );
    defaultTimerSeconds.value = seconds;
    await _datasource.saveDefaultTimerSeconds(seconds);
  }

  /// フォーマット済みのデフォルト時間を取得
  String get formattedDefaultTime {
    return TimeUtils.formatDurationFromSeconds(defaultTimerSeconds.value);
  }

  /// ストリークリマインダー設定を更新
  Future<void> updateStreakReminderEnabled(bool enabled) async {
    streakReminderEnabled.value = enabled;
    await _usersDatasource.updateStreakReminderEnabled(enabled);

    if (!enabled) {
      // リマインダーをOFFにした場合は全ての通知をキャンセル
      await _notificationService.cancelAllStreakReminders();
    }
  }

  /// ネットワーク接続を確認
  Future<bool> checkNetworkConnection() async {
    return _authDatasource.checkNetworkConnection();
  }

  /// displayNameを更新
  /// オンライン必須のため、オフライン時はエラーを返す
  Future<bool> updateDisplayName(String newName) async {
    try {
      // バリデーション
      if (newName.isEmpty) {
        AppLogger.instance.w('名前が空のため更新をスキップ');
        return false;
      }

      if (newName.length > UserConsts.maxDisplayNameLength) {
        AppLogger.instance
            .w('名前が${UserConsts.maxDisplayNameLength}文字を超えています');
        return false;
      }

      // オンラインチェック
      final hasNetwork = await checkNetworkConnection();
      if (!hasNetwork) {
        AppLogger.instance.w('オフラインのため名前を更新できません');
        return false;
      }

      isUpdatingDisplayName.value = true;

      // ローカルDBとSupabaseの両方を更新
      await _usersDatasource.updateDisplayName(newName);
      await _authDatasource.updateDisplayName(newName);

      displayName.value = newName;
      AppLogger.instance.i('displayNameを更新しました: $newName');

      isUpdatingDisplayName.value = false;
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('displayNameの更新に失敗しました', error, stackTrace);
      isUpdatingDisplayName.value = false;
      return false;
    }
  }
}
