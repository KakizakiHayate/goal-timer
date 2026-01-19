import 'package:flutter/material.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/utils/spacing_consts.dart';
import 'package:goal_timer/core/utils/text_consts.dart';

/// 月間カレンダーウィジェット（月曜始まり）
class MonthlyCalendar extends StatelessWidget {
  final DateTime currentMonth;
  final List<DateTime> studyDates;
  final void Function(DateTime date)? onDateTap;

  const MonthlyCalendar({
    super.key,
    required this.currentMonth,
    required this.studyDates,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    // パフォーマンス改善: DateTime.now()を一度だけ呼び出し
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // パフォーマンス改善: studyDatesをSetに変換してO(1)検索
    final studyDateSet = _createStudyDateSet();

    return Column(
      children: [
        _buildWeekdayHeader(),
        const SizedBox(height: SpacingConsts.s),
        _buildCalendarGrid(today: today, studyDateSet: studyDateSet),
      ],
    );
  }

  /// studyDatesをSetに変換（日付のみで比較するため正規化）
  Set<DateTime> _createStudyDateSet() {
    return studyDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
  }

  /// 曜日ヘッダー（月曜始まり）
  Widget _buildWeekdayHeader() {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          weekdays.map((day) {
            return SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  day,
                  style: TextConsts.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: ColorConsts.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  /// カレンダーグリッド
  Widget _buildCalendarGrid({
    required DateTime today,
    required Set<DateTime> studyDateSet,
  }) {
    final days = _generateCalendarDays();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        if (day == null) {
          return const SizedBox.shrink();
        }
        return _buildDayCell(
          date: day,
          today: today,
          studyDateSet: studyDateSet,
        );
      },
    );
  }

  /// 日付セルを構築
  Widget _buildDayCell({
    required DateTime date,
    required DateTime today,
    required Set<DateTime> studyDateSet,
  }) {
    final isToday = _isToday(date, today);
    final hasStudied = _hasStudied(date, studyDateSet);
    final isPast = date.isBefore(today);
    final isFuture = date.isAfter(today);

    return GestureDetector(
      onTap: hasStudied ? () => onDateTap?.call(date) : null,
      child: Container(
        decoration: _getCellDecoration(
          isToday: isToday,
          hasStudied: hasStudied,
          isPast: isPast,
          isFuture: isFuture,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextConsts.bodyMedium.copyWith(
              color: _getTextColor(
                isToday: isToday,
                hasStudied: hasStudied,
                isPast: isPast,
                isFuture: isFuture,
              ),
              fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// セルのデコレーションを取得
  BoxDecoration _getCellDecoration({
    required bool isToday,
    required bool hasStudied,
    required bool isPast,
    required bool isFuture,
  }) {
    if (isFuture) {
      // 未来の日付は何も表示しない
      return const BoxDecoration();
    }

    if (isToday && !hasStudied) {
      // 今日で学習なし：青枠線
      return BoxDecoration(
        border: Border.all(color: ColorConsts.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      );
    }

    if (hasStudied) {
      // 学習あり：緑背景
      return BoxDecoration(
        color: ColorConsts.success,
        borderRadius: BorderRadius.circular(8),
      );
    }

    if (isPast) {
      // 過去で学習なし：グレー背景
      return BoxDecoration(
        color: ColorConsts.disabled,
        borderRadius: BorderRadius.circular(8),
      );
    }

    return const BoxDecoration();
  }

  /// テキストカラーを取得
  Color _getTextColor({
    required bool isToday,
    required bool hasStudied,
    required bool isPast,
    required bool isFuture,
  }) {
    if (isFuture) {
      return ColorConsts.textTertiary;
    }

    if (hasStudied) {
      return Colors.white;
    }

    if (isToday) {
      return ColorConsts.primary;
    }

    return ColorConsts.textPrimary;
  }

  /// カレンダーの日付リストを生成（月曜始まり）
  List<DateTime?> _generateCalendarDays() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    );

    // 月曜始まりのため、1=月曜, 7=日曜に変換
    // DateTime.weekdayは1=月曜, 7=日曜なので調整不要
    final startWeekday = firstDayOfMonth.weekday;

    // 月曜始まりなので、月曜=1から始まる
    final leadingEmptyDays = startWeekday - 1;

    final List<DateTime?> days = [];

    // 前月の空白
    for (var i = 0; i < leadingEmptyDays; i++) {
      days.add(null);
    }

    // 当月の日付
    for (var day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, day));
    }

    return days;
  }

  /// 今日かどうか
  bool _isToday(DateTime date, DateTime today) {
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// 学習記録があるかどうか（O(1)検索）
  bool _hasStudied(DateTime date, Set<DateTime> studyDateSet) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return studyDateSet.contains(normalizedDate);
  }
}
