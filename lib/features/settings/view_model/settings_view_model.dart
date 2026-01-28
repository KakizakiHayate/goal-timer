import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/local/local_settings_datasource.dart';
import '../../../core/data/repositories/users_repository.dart';
import '../../../core/data/supabase/supabase_auth_datasource.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/streak_reminder_consts.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/utils/user_consts.dart';

/// 設定画面のViewModel
/// MVVM準拠: Repository経由でデータアクセス
class SettingsViewModel extends GetxController {
  late final LocalSettingsDataSource _settingsDataSource;
  late final UsersRepository _usersRepository;
  late final NotificationService _notificationService;
  late final SupabaseAuthDatasource _authDatasource;
  late final AuthService _authService;

  final RxInt defaultTimerSeconds =
      LocalSettingsDataSource.defaultTimerSeconds.obs;
  final RxBool streakReminderEnabled =
      StreakReminderConsts.defaultReminderEnabled.obs;
  final RxString displayName = UserConsts.defaultGuestName.obs;
  final RxBool isUpdatingDisplayName = false.obs;

  /// Repositoryに渡す用のユーザーID（nullの場合は空文字）
  ///
  /// マイグレーション済み（Supabase使用時）は必ず値が存在する。
  /// マイグレーション未済（ローカルDB使用時）はnullの場合があるため空文字を返す。
  String get _userIdForRepository => _authService.currentUserId ?? '';

  SettingsViewModel({
    UsersRepository? usersRepository,
    NotificationService? notificationService,
    SupabaseAuthDatasource? authDatasource,
    AuthService? authService,
  }) {
    _settingsDataSource = LocalSettingsDataSource();
    _usersRepository = usersRepository ?? UsersRepository();
    _notificationService = notificationService ?? NotificationService();
    _authDatasource = authDatasource ??
        SupabaseAuthDatasource(supabase: Supabase.instance.client);
    _authService = authService ?? AuthService();
  }

  /// 初期化: SharedPreferencesとDBから設定を読み込む
  Future<void> init() async {
    final userId = _userIdForRepository;

    final seconds = await _settingsDataSource.fetchDefaultTimerSeconds();
    defaultTimerSeconds.value = seconds;

    final reminderEnabled = await _usersRepository.getStreakReminderEnabled(
      userId,
    );
    streakReminderEnabled.value = reminderEnabled;

    final name = await _usersRepository.getDisplayName(userId);
    displayName.value = name;
  }

  /// デフォルトタイマー時間を更新
  Future<void> updateDefaultTimerDuration(Duration duration) async {
    final seconds = duration.inSeconds.clamp(
      LocalSettingsDataSource.minTimerSeconds,
      LocalSettingsDataSource.maxTimerSeconds,
    );
    defaultTimerSeconds.value = seconds;
    await _settingsDataSource.saveDefaultTimerSeconds(seconds);
  }

  /// フォーマット済みのデフォルト時間を取得
  String get formattedDefaultTime {
    return TimeUtils.formatDurationFromSeconds(defaultTimerSeconds.value);
  }

  /// ストリークリマインダー設定を更新
  Future<void> updateStreakReminderEnabled(bool enabled) async {
    final userId = _userIdForRepository;
    streakReminderEnabled.value = enabled;
    await _usersRepository.updateStreakReminderEnabled(enabled, userId);

    if (!enabled) {
      // リマインダーをOFFにした場合は全ての通知をキャンセル
      await _notificationService.cancelAllStreakReminders();
    }
  }

  /// ネットワーク接続を確認
  Future<bool> checkNetworkConnection() async {
    return _authDatasource.checkNetworkConnection();
  }

  /// displayNameを再読み込み
  /// ログイン後や画面表示時に呼び出す
  Future<void> refreshDisplayName() async {
    final name = await _usersRepository.getDisplayName(_userIdForRepository);
    displayName.value = name;
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

      // ユーザーIDを取得
      final userId = _authService.currentUserId;
      if (userId == null) {
        AppLogger.instance.w('ユーザーIDが取得できないため更新をスキップ');
        isUpdatingDisplayName.value = false;
        return false;
      }

      // Repository経由で更新（Repository内でLocal/Supabaseを振り分け）
      await _usersRepository.updateDisplayName(newName, userId);

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
