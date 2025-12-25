import 'package:flutter/material.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/utils/streak_consts.dart';

/// ミニヒートマップウィジェット
/// 直近7日間の学習状況を7つのドットで表示する
class MiniHeatmap extends StatelessWidget {
  final List<DateTime> studyDates;

  const MiniHeatmap({
    super.key,
    required this.studyDates,
  });

  /// 今日の学習済みドットの色（濃い緑）
  static const Color todayStudiedColor = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(StreakConsts.recentDaysCount, (index) {
        final daysAgo = StreakConsts.recentDaysCount - 1 - index;
        final date = today.subtract(Duration(days: daysAgo));
        final isToday = daysAgo == 0;
        final hasStudied = _hasStudiedOnDate(date);

        return Padding(
          padding: EdgeInsets.only(
            right: index < StreakConsts.recentDaysCount - 1
                ? StreakConsts.dotSpacing
                : 0,
          ),
          child: _buildDot(isToday: isToday, hasStudied: hasStudied),
        );
      }),
    );
  }

  bool _hasStudiedOnDate(DateTime date) {
    return studyDates.any((studyDate) =>
        studyDate.year == date.year &&
        studyDate.month == date.month &&
        studyDate.day == date.day);
  }

  Widget _buildDot({required bool isToday, required bool hasStudied}) {
    BoxDecoration decoration;

    if (isToday) {
      if (hasStudied) {
        decoration = BoxDecoration(
          color: todayStudiedColor,
          borderRadius: BorderRadius.circular(StreakConsts.dotBorderRadius),
        );
      } else {
        decoration = BoxDecoration(
          color: null,
          border: Border.all(
            color: ColorConsts.primary,
            width: StreakConsts.todayBorderWidth,
          ),
          borderRadius: BorderRadius.circular(StreakConsts.dotBorderRadius),
        );
      }
    } else {
      if (hasStudied) {
        decoration = BoxDecoration(
          color: ColorConsts.success,
          borderRadius: BorderRadius.circular(StreakConsts.dotBorderRadius),
        );
      } else {
        decoration = BoxDecoration(
          color: ColorConsts.disabled,
          borderRadius: BorderRadius.circular(StreakConsts.dotBorderRadius),
        );
      }
    }

    return Container(
      width: StreakConsts.dotSize,
      height: StreakConsts.dotSize,
      decoration: decoration,
    );
  }
}
