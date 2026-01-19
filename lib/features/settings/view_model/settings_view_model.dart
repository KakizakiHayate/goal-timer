import 'package:get/get.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/local_settings_datasource.dart';
import '../../../core/data/local/local_users_datasource.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/streak_reminder_consts.dart';
import '../../../core/utils/time_utils.dart';

/// 設定画面のViewModel
/// MVVM準拠: DataSource経由でデータアクセス
class SettingsViewModel extends GetxController {
  late final LocalSettingsDataSource _datasource;
  late final LocalUsersDatasource _usersDatasource;
  late final NotificationService _notificationService;

  final RxInt defaultTimerSeconds =
      LocalSettingsDataSource.defaultTimerSeconds.obs;
  final RxBool streakReminderEnabled =
      StreakReminderConsts.defaultReminderEnabled.obs;

  SettingsViewModel({
    LocalUsersDatasource? usersDatasource,
    NotificationService? notificationService,
  }) {
    _datasource = LocalSettingsDataSource();
    _usersDatasource =
        usersDatasource ??
        LocalUsersDatasource(database: Get.find<AppDatabase>());
    _notificationService = notificationService ?? NotificationService();
  }

  /// 初期化: SharedPreferencesとDBから設定を読み込む
  Future<void> init() async {
    final seconds = await _datasource.fetchDefaultTimerSeconds();
    defaultTimerSeconds.value = seconds;

    final reminderEnabled = await _usersDatasource.getStreakReminderEnabled();
    streakReminderEnabled.value = reminderEnabled;
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
}
