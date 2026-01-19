import 'package:flutter/material.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/utils/streak_consts.dart';
import 'package:goal_timer/core/utils/time_utils.dart';

/// ミニヒートマップウィジェット
/// 直近7日間の学習状況を7つのドットで表示する
class MiniHeatmap extends StatelessWidget {
  final List<DateTime> studyDates;

  const MiniHeatmap({super.key, required this.studyDates});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(StreakConsts.recentDaysCount, (index) {
        final daysAgo =
            StreakConsts.recentDaysCount -
            StreakConsts.lastDotIndexOffset -
            index;
        final date = today.subtract(Duration(days: daysAgo));
        final isToday = daysAgo == 0;
        final isStudied = _isStudiedOnDate(date);

        final isLastDot =
            index ==
            StreakConsts.recentDaysCount - StreakConsts.lastDotIndexOffset;
        return Padding(
          padding: EdgeInsets.only(
            right: isLastDot ? 0 : StreakConsts.dotSpacing,
          ),
          child: _buildDot(isToday: isToday, isStudied: isStudied),
        );
      }),
    );
  }

  bool _isStudiedOnDate(DateTime date) {
    return studyDates.any((studyDate) => studyDate.isSameDay(date));
  }

  Widget _buildDot({required bool isToday, required bool isStudied}) {
    BoxDecoration decoration;

    if (isToday) {
      if (isStudied) {
        decoration = BoxDecoration(
          color: ColorConsts.success,
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
      if (isStudied) {
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
