import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_logger.dart';

class SettingsController extends GetxController {
  static const String _keyDefaultTimerSeconds = 'default_timer_seconds';
  static const int _defaultTimerSeconds = 25 * 60;
  static const int _minTimerSeconds = 60;
  static const int _maxTimerSeconds = 24 * 60 * 60;

  final RxInt defaultTimerSeconds = _defaultTimerSeconds.obs;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_keyDefaultTimerSeconds);
      if (stored != null && stored >= _minTimerSeconds && stored <= _maxTimerSeconds) {
        defaultTimerSeconds.value = stored;
        AppLogger.instance.i('デフォルトタイマー時間を読み込みました: $stored秒');
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e('デフォルトタイマー時間の読み込みに失敗しました', error, stackTrace);
    }
  }

  Future<void> updateDefaultTimerDuration(Duration duration) async {
    try {
      final seconds = duration.inSeconds.clamp(_minTimerSeconds, _maxTimerSeconds);
      defaultTimerSeconds.value = seconds;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDefaultTimerSeconds, seconds);

      AppLogger.instance.i('デフォルトタイマー時間を保存しました: $seconds秒');
    } catch (error, stackTrace) {
      AppLogger.instance.e('デフォルトタイマー時間の保存に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  String get formattedDefaultTime {
    final hours = defaultTimerSeconds.value ~/ 3600;
    final minutes = (defaultTimerSeconds.value % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours時間$minutes分';
    } else {
      return '$minutes分';
    }
  }
}
