import 'package:flutter/material.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/widgets/circular_progress_indicator_v2.dart';
import '../../../../core/widgets/streak_indicator.dart';

/// 改善された今日の進捗ウィジェット
/// モチベーション維持のため視覚的インパクトを強化
class TodayProgressWidgetV2 extends StatelessWidget {
  final double todayProgress; // 0.0 - 1.0
  final int totalMinutes;
  final int targetMinutes;
  final int currentStreak;
  final int totalGoals;
  final int completedGoals;

  const TodayProgressWidgetV2({
    super.key,
    required this.todayProgress,
    required this.totalMinutes,
    required this.targetMinutes,
    required this.currentStreak,
    required this.totalGoals,
    required this.completedGoals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(SpacingConsts.l),
      padding: const EdgeInsets.all(SpacingConsts.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConsts.primary.withOpacity(0.1),
            ColorConsts.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ColorConsts.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ヘッダー
          _buildHeader(),
          
          const SizedBox(height: SpacingConsts.xl),
          
          // メインプログレス
          _buildMainProgress(),
          
          const SizedBox(height: SpacingConsts.xl),
          
          // 統計情報
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日の進捗',
              style: TextConsts.h3.copyWith(
                color: ColorConsts.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: SpacingConsts.xs),
            Text(
              _getMotivationalMessage(),
              style: TextConsts.body.copyWith(
                color: ColorConsts.textSecondary,
              ),
            ),
          ],
        ),
        StreakIndicator(
          streakDays: currentStreak,
          showAnimation: true,
          size: 40.0,
        ),
      ],
    );
  }

  Widget _buildMainProgress() {
    return Row(
      children: [
        // プログレスサークル
        CircularProgressIndicatorV2(
          progress: todayProgress,
          size: 120.0,
          strokeWidth: 12.0,
          showAnimation: true,
          centerWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(todayProgress * 100).toInt()}%',
                style: TextConsts.h2.copyWith(
                  color: ColorConsts.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '達成',
                style: TextConsts.caption.copyWith(
                  color: ColorConsts.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: SpacingConsts.xl),
        
        // 時間情報
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeInfo('今日の勉強時間', '${totalMinutes}分'),
              const SizedBox(height: SpacingConsts.m),
              _buildTimeInfo('目標時間', '${targetMinutes}分'),
              const SizedBox(height: SpacingConsts.m),
              _buildTimeInfo(
                '残り時間',
                '${(targetMinutes - totalMinutes).clamp(0, targetMinutes)}分',
                isRemaining: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String label, String value, {bool isRemaining = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextConsts.caption.copyWith(
            color: ColorConsts.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: SpacingConsts.xs),
        Text(
          value,
          style: TextConsts.h4.copyWith(
            color: isRemaining ? ColorConsts.warning : ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.flag_outlined,
            label: '目標達成',
            value: '$completedGoals/$totalGoals',
            color: ColorConsts.success,
          ),
        ),
        Container(
          width: 1,
          height: 40,
          color: ColorConsts.border,
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.schedule_outlined,
            label: '平均集中時間',
            value: totalGoals > 0 ? '${(totalMinutes / totalGoals).toInt()}分' : '0分',
            color: ColorConsts.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: SpacingConsts.xs),
        Text(
          value,
          style: TextConsts.h4.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextConsts.caption.copyWith(
            color: ColorConsts.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getMotivationalMessage() {
    if (todayProgress >= 1.0) {
      return '今日の目標達成！素晴らしいです！';
    } else if (todayProgress >= 0.8) {
      return 'もう少しで達成です！';
    } else if (todayProgress >= 0.5) {
      return '順調に進んでいます';
    } else if (todayProgress >= 0.3) {
      return '良いスタートです';
    } else {
      return '今日も頑張りましょう！';
    }
  }
}