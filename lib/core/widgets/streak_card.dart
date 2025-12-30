import 'package:flutter/material.dart';
import 'package:goal_timer/core/utils/color_consts.dart';
import 'package:goal_timer/core/utils/spacing_consts.dart';
import 'package:goal_timer/core/utils/text_consts.dart';
import 'package:goal_timer/core/utils/streak_consts.dart';
import 'package:goal_timer/core/widgets/mini_heatmap.dart';

/// ストリークカードウィジェット
/// 連続学習日数とミニヒートマップを表示する
class StreakCard extends StatelessWidget {
  final int streakDays;
  final List<DateTime> studyDates;
  final VoidCallback? onTap;

  const StreakCard({
    super.key,
    required this.streakDays,
    required this.studyDates,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: SpacingConsts.l,
          vertical: SpacingConsts.s,
        ),
        padding: const EdgeInsets.all(SpacingConsts.l),
        decoration: BoxDecoration(
          color: ColorConsts.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakMessage(),
            const SizedBox(height: SpacingConsts.m),
            MiniHeatmap(studyDates: studyDates),
            const SizedBox(height: SpacingConsts.m),
            _buildDetailLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakMessage() {
    final message = _getStreakMessage();
    final icon = _getStreakIcon();

    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: SpacingConsts.s),
        Expanded(
          child: Text(
            message,
            style: TextConsts.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: ColorConsts.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _getStreakMessage() {
    if (streakDays == 0) return StreakConsts.messageZeroStreak;
    if (streakDays >= StreakConsts.monthMilestone) {
      return '🏆 ${StreakConsts.messageMonthMilestone}';
    }
    if (streakDays >= StreakConsts.weekMilestone) {
      return '🎉 ${StreakConsts.messageWeekMilestone}';
    }
    return StreakConsts.messageStreakDays(streakDays);
  }

  String _getStreakIcon() {
    if (streakDays == 0) return '✨';
    if (streakDays >= StreakConsts.monthMilestone) return '';
    if (streakDays >= StreakConsts.weekMilestone) return '';
    return '🔥';
  }

  Widget _buildDetailLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '詳細を見る',
          style: TextConsts.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: ColorConsts.textSecondary,
          ),
        ),
        const SizedBox(width: SpacingConsts.xs),
        Icon(Icons.chevron_right, size: 16, color: ColorConsts.textSecondary),
      ],
    );
  }
}
