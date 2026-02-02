import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/color_consts.dart';
import '../utils/spacing_consts.dart';
import '../utils/streak_consts.dart';
import '../utils/text_consts.dart';
import 'mini_heatmap.dart';

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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakMessage(context),
            const SizedBox(height: SpacingConsts.m),
            MiniHeatmap(studyDates: studyDates),
            const SizedBox(height: SpacingConsts.m),
            _buildDetailLink(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakMessage(BuildContext context) {
    final message = _getStreakMessage(context);
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

  String _getStreakMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (streakDays == 0) {
      return l10n?.streakMessageZero ?? "Let's start today!";
    }
    if (streakDays >= StreakConsts.monthMilestone) {
      return '🏆 ${l10n?.streakMessageMonth ?? '1 month achieved!'}';
    }
    if (streakDays >= StreakConsts.weekMilestone) {
      return '🎉 ${l10n?.streakMessageWeek ?? '1 week achieved!'}';
    }
    return l10n?.streakMessageDays(streakDays) ?? '$streakDays day streak!';
  }

  String _getStreakIcon() {
    if (streakDays == 0) return '✨';
    if (streakDays >= StreakConsts.monthMilestone) return '';
    if (streakDays >= StreakConsts.weekMilestone) return '';
    return '🔥';
  }

  Widget _buildDetailLink(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          l10n?.viewDetails ?? 'View details',
          style: TextConsts.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: ColorConsts.textSecondary,
          ),
        ),
        const SizedBox(width: SpacingConsts.xs),
        const Icon(Icons.chevron_right, size: 16, color: ColorConsts.textSecondary),
      ],
    );
  }
}
