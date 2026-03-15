import 'package:intl/intl.dart';

/// カレンダー表示で使用するロケール対応のユーティリティ
class CalendarUtils {
  /// ロケールに応じた短縮曜日リスト（週の開始曜日順）を取得する
  ///
  /// 例:
  /// - ja: ['月', '火', '水', '木', '金', '土', '日']
  /// - en_US: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  static List<String> getOrderedWeekdays(String locale) {
    final df = DateFormat('', locale);
    final symbols = df.dateSymbols;
    final narrowWeekdays = symbols.SHORTWEEKDAYS;
    final firstDayOfWeek = symbols.FIRSTDAYOFWEEK;

    // SHORTWEEKDAYS は [Sun, Mon, Tue, ...] の順（index 0 = 日曜）
    // FIRSTDAYOFWEEK は 0=月曜, 1=火曜, ..., 6=日曜 (intl仕様)
    // → 実際の曜日index: (firstDayOfWeek + 1) % 7 が SHORTWEEKDAYS の開始index
    final startIndex = (firstDayOfWeek + 1) % 7;

    final ordered = <String>[];
    for (var i = 0; i < 7; i++) {
      ordered.add(narrowWeekdays[(startIndex + i) % 7]);
    }
    return ordered;
  }

  /// 指定された月の日付リストを、ロケールの週開始曜日に基づいて生成する
  ///
  /// 先頭の空白日はnullで埋められる
  static List<DateTime?> generateCalendarDays({
    required DateTime month,
    required String locale,
  }) {
    final df = DateFormat('', locale);
    final firstDayOfWeek = df.dateSymbols.FIRSTDAYOFWEEK;

    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // DateTime.weekday: 1=月曜, 7=日曜
    // intl FIRSTDAYOFWEEK: 0=月曜, 6=日曜
    // weekdayを intl体系に変換: (DateTime.weekday - 1)
    final firstWeekdayIntl = firstDayOfMonth.weekday - 1;

    // 先頭の空白日数を計算
    final leadingEmptyDays = (firstWeekdayIntl - firstDayOfWeek + 7) % 7;

    final List<DateTime?> days = [];

    for (var i = 0; i < leadingEmptyDays; i++) {
      days.add(null);
    }

    for (var day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    return days;
  }

  /// ロケールに応じた年月フォーマット文字列を取得する
  ///
  /// 例:
  /// - ja: '2026年3月'
  /// - en: 'March 2026'
  static String formatYearMonth(DateTime date, String locale) {
    return DateFormat.yMMMM(locale).format(date);
  }
}
