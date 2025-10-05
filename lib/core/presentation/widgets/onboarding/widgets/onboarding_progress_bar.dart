import 'package:flutter/material.dart';
import '../../../../../core/utils/color_consts.dart';
import '../../../../../core/utils/spacing_consts.dart';
import '../../../../../core/utils/text_consts.dart';

/// オンボーディング進捗表示バー
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
  });

  final double progress; // 0.0 - 1.0
  final int currentStep; // 1, 2, 3
  final int totalSteps; // 3

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConsts.md,
        vertical: SpacingConsts.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ステップ表示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ステップ $currentStep / $totalSteps',
                style: TextConsts.labelMedium.copyWith(
                  color: ColorConsts.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextConsts.labelMedium.copyWith(
                  color: ColorConsts.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingConsts.sm),

          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: ColorConsts.backgroundSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(ColorConsts.primary),
              minHeight: 8.0,
            ),
          ),

          const SizedBox(height: SpacingConsts.xs),

          // ステップ説明
          Text(
            _getStepDescription(currentStep),
            style: TextConsts.bodySmall.copyWith(
              color: ColorConsts.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 1:
        return '目標を設定してモチベーションを明確にしましょう';
      case 2:
        return 'タイマー機能を体験してみましょう';
      case 3:
        return 'アカウントを作成してデータを保護しましょう';
      default:
        return '';
    }
  }
}
