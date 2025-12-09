import 'package:get/get.dart';
import '../../../core/data/local/local_settings_datasource.dart';
import '../../../core/utils/time_utils.dart';

/// 設定画面のViewModel
/// MVVM準拠: DataSource経由でデータアクセス
class SettingsViewModel extends GetxController {
  late final LocalSettingsDataSource _datasource;

  final RxInt defaultTimerSeconds = LocalSettingsDataSource.defaultTimerSeconds.obs;

  SettingsViewModel() {
    _datasource = LocalSettingsDataSource();
  }

  /// 初期化: SharedPreferencesから設定を読み込む
  Future<void> init() async {
    final seconds = await _datasource.fetchDefaultTimerSeconds();
    defaultTimerSeconds.value = seconds;
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
}
