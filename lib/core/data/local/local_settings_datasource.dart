import 'package:shared_preferences/shared_preferences.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

/// 設定データのローカルDataSource
/// SharedPreferencesを使用して設定を永続化
class LocalSettingsDataSource {
  static const String _keyDefaultTimerSeconds = 'default_timer_seconds';
  static const int defaultTimerSeconds = 25 * 60;
  static const int minTimerSeconds = 60;
  static const int maxTimerSeconds = 24 * 60 * 60;

  /// デフォルトタイマー時間を取得
  Future<int> fetchDefaultTimerSeconds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_keyDefaultTimerSeconds);
      if (stored != null && stored >= minTimerSeconds && stored <= maxTimerSeconds) {
        AppLogger.instance.i('デフォルトタイマー時間を読み込みました: $stored秒');
        return stored;
      }
      return defaultTimerSeconds;
    } catch (error, stackTrace) {
      AppLogger.instance.e('デフォルトタイマー時間の読み込みに失敗しました', error, stackTrace);
      return defaultTimerSeconds;
    }
  }

  /// デフォルトタイマー時間を保存
  Future<void> saveDefaultTimerSeconds(int seconds) async {
    try {
      final clampedSeconds = seconds.clamp(minTimerSeconds, maxTimerSeconds);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDefaultTimerSeconds, clampedSeconds);
      AppLogger.instance.i('デフォルトタイマー時間を保存しました: $clampedSeconds秒');
    } catch (error, stackTrace) {
      AppLogger.instance.e('デフォルトタイマー時間の保存に失敗しました', error, stackTrace);
      rethrow;
    }
  }
}
