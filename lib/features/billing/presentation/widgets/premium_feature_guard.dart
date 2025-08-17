import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/premium_restriction_provider.dart';
import '../view_models/billing_view_model.dart';
import 'premium_upgrade_dialog.dart';

/// プレミアム機能の制限をチェックするウィジェット
class PremiumFeatureGuard extends ConsumerWidget {
  final Widget child;
  final PremiumFeatureType featureType;
  final int? currentGoalCount;
  final VoidCallback? onFeatureBlocked;
  final bool showDialogOnBlock;

  const PremiumFeatureGuard({
    super.key,
    required this.child,
    required this.featureType,
    this.currentGoalCount,
    this.onFeatureBlocked,
    this.showDialogOnBlock = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, _) {
        // プレミアム状態を監視
        final isPremiumAsync = ref.watch(isPremiumProvider);
        
        return isPremiumAsync.when(
          data: (isPremium) {
            if (isPremium) {
              // プレミアムユーザーは制限なし
              return child;
            }

            // 無料ユーザーの場合、機能タイプに応じて制限をチェック
            switch (featureType) {
              case PremiumFeatureType.goalCreation:
                return _buildGoalCreationGuard(context, ref);
              case PremiumFeatureType.pomodoroTimer:
                return _buildBlockedFeature(
                  context,
                  () => _showPomodoroDialog(context),
                );
              case PremiumFeatureType.csvExport:
                return _buildBlockedFeature(
                  context,
                  () => _showCsvExportDialog(context),
                );
            }
          },
          loading: () => child, // ローディング中はそのまま表示
          error: (_, __) => child, // エラー時も制限なしとして扱う
        );
      },
    );
  }

  Widget _buildGoalCreationGuard(BuildContext context, WidgetRef ref) {
    if (currentGoalCount == null) {
      return child;
    }

    final canCreateAsync = ref.watch(canCreateGoalProvider(currentGoalCount!));
    
    return canCreateAsync.when(
      data: (canCreate) {
        if (canCreate) {
          return child;
        } else {
          return _buildBlockedFeature(
            context,
            () => _showGoalLimitDialog(context),
          );
        }
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }

  Widget _buildBlockedFeature(BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        if (onFeatureBlocked != null) {
          onFeatureBlocked!();
        }
        if (showDialogOnBlock) {
          onTap();
        }
      },
      child: Opacity(
        opacity: 0.6,
        child: child,
      ),
    );
  }

  void _showGoalLimitDialog(BuildContext context) {
    PremiumUpgradeDialog.show(
      context,
      PremiumUpgradeDialog.goalLimit(
        currentGoalCount: currentGoalCount,
      ),
    );
  }

  void _showPomodoroDialog(BuildContext context) {
    PremiumUpgradeDialog.show(
      context,
      PremiumUpgradeDialog.pomodoroLimit(),
    );
  }

  void _showCsvExportDialog(BuildContext context) {
    PremiumUpgradeDialog.show(
      context,
      PremiumUpgradeDialog.csvExportLimit(),
    );
  }
}

/// プレミアム機能の種類
enum PremiumFeatureType {
  goalCreation,
  pomodoroTimer,
  csvExport,
}