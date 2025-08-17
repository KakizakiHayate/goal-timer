import 'package:flutter/material.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/widgets/common_button.dart';
import '../../constants/billing_text_consts.dart';
import '../screens/upgrade_screen.dart';

/// プレミアムアップグレード誘導ダイアログ
class PremiumUpgradeDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? featureName;
  final VoidCallback? onUpgrade;

  const PremiumUpgradeDialog({
    super.key,
    required this.title,
    required this.message,
    this.featureName,
    this.onUpgrade,
  });

  /// 目標制限用ダイアログ
  factory PremiumUpgradeDialog.goalLimit({
    int? currentGoalCount,
    VoidCallback? onUpgrade,
  }) =>
      PremiumUpgradeDialog(
        title: '目標の作成制限',
        message: currentGoalCount != null
            ? '無料版では目標を3個まで作成できます。\n現在：$currentGoalCount/3個\n\nプレミアムプランにアップグレードして無制限に目標を作成しませんか？'
            : '無料版では目標を3個まで作成できます。\n\nプレミアムプランで無制限に目標を作成できます。',
        featureName: '無制限の目標作成',
        onUpgrade: onUpgrade,
      );

  /// ポモドーロタイマー制限用ダイアログ
  factory PremiumUpgradeDialog.pomodoroLimit({VoidCallback? onUpgrade}) =>
      PremiumUpgradeDialog(
        title: 'ポモドーロタイマー',
        message: 'ポモドーロタイマーはプレミアム限定機能です。\n\n25分の集中と5分の休憩を自動で管理し、効率的な学習をサポートします。',
        featureName: 'ポモドーロタイマー',
        onUpgrade: onUpgrade,
      );

  /// CSVエクスポート制限用ダイアログ
  factory PremiumUpgradeDialog.csvExportLimit({VoidCallback? onUpgrade}) =>
      PremiumUpgradeDialog(
        title: 'CSVエクスポート',
        message: 'CSVエクスポートはプレミアム限定機能です。\n\n学習データをCSVファイルで出力し、詳細な分析や他のツールとの連携が可能になります。',
        featureName: 'CSVデータエクスポート',
        onUpgrade: onUpgrade,
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(SpacingConsts.xl),
        decoration: BoxDecoration(
          color: ColorConsts.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // プレミアムアイコン
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ColorConsts.primary, ColorConsts.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 32,
              ),
            ),

            const SizedBox(height: SpacingConsts.lg),

            // タイトル
            Text(
              title,
              style: TextConsts.h3.copyWith(
                color: ColorConsts.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: SpacingConsts.md),

            // メッセージ
            Text(
              message,
              style: TextConsts.bodyMedium.copyWith(
                color: ColorConsts.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: SpacingConsts.xl),

            // プレミアム機能バッジ（機能名がある場合）
            if (featureName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingConsts.md,
                  vertical: SpacingConsts.sm,
                ),
                decoration: BoxDecoration(
                  color: ColorConsts.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorConsts.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: ColorConsts.primary,
                      size: 16,
                    ),
                    const SizedBox(width: SpacingConsts.xs),
                    Text(
                      featureName!,
                      style: TextConsts.bodySmall.copyWith(
                        color: ColorConsts.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SpacingConsts.xl),
            ],

            // ボタン群
            Row(
              children: [
                // キャンセルボタン
                Expanded(
                  child: CommonButton(
                    text: 'あとで',
                    variant: ButtonVariant.ghost,
                    size: ButtonSize.medium,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                const SizedBox(width: SpacingConsts.md),

                // アップグレードボタン
                Expanded(
                  flex: 2,
                  child: CommonButton(
                    text: 'アップグレード',
                    variant: ButtonVariant.primary,
                    size: ButtonSize.medium,
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onUpgrade != null) {
                        onUpgrade!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UpgradeScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ダイアログを表示するヘルパーメソッド
  static Future<void> show(
    BuildContext context,
    PremiumUpgradeDialog dialog,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => dialog,
    );
  }
}