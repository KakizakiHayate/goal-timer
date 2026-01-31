// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Goal Timer';

  @override
  String get commonBtnCancel => 'Cancel';

  @override
  String get commonBtnOk => 'OK';

  @override
  String get commonBtnSave => 'Save';

  @override
  String get commonBtnDelete => 'Delete';

  @override
  String get defaultGuestName => 'Guest';

  @override
  String timeFormatHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String timeFormatMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String daysSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }
}
