import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../view_models/billing_view_model.dart';

/// プレミアム状態表示バッジ
class PremiumBadge extends ConsumerWidget {
  final PremiumBadgeSize size;
  final bool showIcon;
  final Color? backgroundColor;
  final Color? textColor;

  const PremiumBadge({
    super.key,
    this.size = PremiumBadgeSize.medium,
    this.showIcon = true,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumAsync = ref.watch(isPremiumProvider);
    
    return isPremiumAsync.when(
      data: (isPremium) {
        if (!isPremium) {
          return const SizedBox.shrink(); // プレミアムでない場合は非表示
        }
        
        return _buildBadge();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBadge() {
    final badgeColor = backgroundColor ?? const Color(0xFFFFD700); // ゴールド
    final foregroundColor = textColor ?? Colors.white;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getPadding().horizontal,
        vertical: _getPadding().vertical,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.star,
              color: foregroundColor,
              size: _getIconSize(),
            ),
            SizedBox(width: _getSpacing()),
          ],
          Text(
            'Premium',
            style: _getTextStyle().copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case PremiumBadgeSize.small:
        return const EdgeInsets.symmetric(
          horizontal: SpacingConsts.xs,
          vertical: SpacingConsts.xxs,
        );
      case PremiumBadgeSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: SpacingConsts.sm,
          vertical: SpacingConsts.xs,
        );
      case PremiumBadgeSize.large:
        return const EdgeInsets.symmetric(
          horizontal: SpacingConsts.md,
          vertical: SpacingConsts.sm,
        );
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case PremiumBadgeSize.small:
        return 8;
      case PremiumBadgeSize.medium:
        return 10;
      case PremiumBadgeSize.large:
        return 12;
    }
  }

  double _getIconSize() {
    switch (size) {
      case PremiumBadgeSize.small:
        return 12;
      case PremiumBadgeSize.medium:
        return 14;
      case PremiumBadgeSize.large:
        return 16;
    }
  }

  double _getSpacing() {
    switch (size) {
      case PremiumBadgeSize.small:
        return SpacingConsts.xxs;
      case PremiumBadgeSize.medium:
        return SpacingConsts.xs;
      case PremiumBadgeSize.large:
        return SpacingConsts.sm;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case PremiumBadgeSize.small:
        return TextConsts.caption.copyWith(fontWeight: FontWeight.w600);
      case PremiumBadgeSize.medium:
        return TextConsts.labelSmall.copyWith(fontWeight: FontWeight.w600);
      case PremiumBadgeSize.large:
        return TextConsts.labelMedium.copyWith(fontWeight: FontWeight.w600);
    }
  }
}

/// プレミアムバッジのサイズ
enum PremiumBadgeSize {
  small,
  medium,
  large,
}

/// サブスクリプション状態表示ウィジェット
class SubscriptionStatusWidget extends ConsumerWidget {
  const SubscriptionStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionStatusAsync = ref.watch(subscriptionStatusStreamProvider);
    
    return subscriptionStatusAsync.when(
      data: (status) {
        if (!status.isPremium) {
          return const SizedBox.shrink();
        }
        
        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFFD700),
                    size: 16,
                  ),
                  const SizedBox(width: SpacingConsts.xs),
                  Text(
                    'Premium',
                    style: TextConsts.labelMedium.copyWith(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (status.isInTrialPeriod)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingConsts.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'トライアル',
                        style: TextConsts.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              if (status.expirationDate != null) ...[
                const SizedBox(height: SpacingConsts.xs),
                Text(
                  status.isInTrialPeriod
                      ? 'トライアル期間: ${status.trialDaysRemaining ?? 0}日残り'
                      : '次回更新: ${status.daysRemaining ?? 0}日後',
                  style: TextConsts.caption.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}