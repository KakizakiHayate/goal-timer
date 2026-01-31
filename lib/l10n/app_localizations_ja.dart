// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Goal Timer';

  @override
  String get commonBtnCancel => 'キャンセル';

  @override
  String get commonBtnOk => 'OK';

  @override
  String get commonBtnSave => '保存';

  @override
  String get commonBtnDelete => '削除';

  @override
  String get defaultGuestName => 'ゲスト';

  @override
  String timeFormatHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String timeFormatMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String daysSuffix(int count) {
    return '$count日';
  }
}
