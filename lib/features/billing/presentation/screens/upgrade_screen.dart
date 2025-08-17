import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/animation_consts.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/pressable_card.dart';
import '../../constants/billing_text_consts.dart';
import '../../domain/entities/entities.dart';
import '../view_models/billing_view_model.dart';

/// アップグレード画面
class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  bool _isYearlyPlan = false; // false: 月額, true: 年額

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AnimationConsts.medium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingViewModelProvider);
    final isProcessing = billingState.isPurchasing || billingState.isLoading;
    
    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          BillingTextConsts.upgradeTitle,
          style: TextConsts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorConsts.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ヘッダー部分
                    _buildHeader(),
                    
                    const SizedBox(height: SpacingConsts.xl),
                    
                    // 機能比較
                    _buildFeatureComparison(),
                    
                    const SizedBox(height: SpacingConsts.xl),
                    
                    // プラン選択
                    _buildPlanSelector(),
                    
                    const SizedBox(height: SpacingConsts.xl),
                    
                    // 価格表示
                    _buildPricing(),
                    
                    const SizedBox(height: SpacingConsts.xl),
                    
                    // アクションボタン
                    _buildActionButtons(),
                    
                    const SizedBox(height: SpacingConsts.lg),
                    
                    // 注意事項
                    _buildTermsAndNotes(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
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
            size: 40,
          ),
        ),
        
        const SizedBox(height: SpacingConsts.lg),
        
        Text(
          BillingTextConsts.upgradeHeader,
          style: TextConsts.h2.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: SpacingConsts.md),
        
        Text(
          BillingTextConsts.upgradeSubtitle,
          style: TextConsts.bodyMedium.copyWith(
            color: ColorConsts.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureComparison() {
    return PressableCard(
      margin: EdgeInsets.zero,
      backgroundColor: ColorConsts.cardBackground,
      borderRadius: 20.0,
      elevation: 2.0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(SpacingConsts.lg),
            child: Text(
              BillingTextConsts.premiumFeaturesTitle,
              style: TextConsts.h4.copyWith(
                color: ColorConsts.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          _buildFeatureItem(
            icon: Icons.flag_outlined,
            title: BillingTextConsts.unlimitedGoalsTitle,
            description: BillingTextConsts.unlimitedGoalsDescription,
            isPremium: true,
          ),
          
          _buildFeatureItem(
            icon: Icons.timer_outlined,
            title: BillingTextConsts.pomodoroTimerTitle,
            description: BillingTextConsts.pomodoroTimerDescription,
            isPremium: true,
          ),
          
          _buildFeatureItem(
            icon: Icons.file_download_outlined,
            title: BillingTextConsts.csvExportTitle,
            description: BillingTextConsts.csvExportDescription,
            isPremium: true,
          ),
          
          const SizedBox(height: SpacingConsts.md),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isPremium,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConsts.lg,
        vertical: SpacingConsts.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPremium 
                  ? ColorConsts.primary.withOpacity(0.1)
                  : ColorConsts.textTertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isPremium ? ColorConsts.primary : ColorConsts.textTertiary,
              size: 24,
            ),
          ),
          
          const SizedBox(width: SpacingConsts.md),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextConsts.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorConsts.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingConsts.xs),
                Text(
                  description,
                  style: TextConsts.bodySmall.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingConsts.sm,
                vertical: SpacingConsts.xs,
              ),
              decoration: BoxDecoration(
                color: ColorConsts.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                BillingTextConsts.premiumBadge,
                style: TextConsts.caption.copyWith(
                  color: ColorConsts.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          BillingTextConsts.planSelectionTitle,
          style: TextConsts.h4.copyWith(
            color: ColorConsts.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: SpacingConsts.md),
        
        // 月額プラン
        Container(
          decoration: BoxDecoration(
            color: !_isYearlyPlan ? ColorConsts.primary.withOpacity(0.1) : ColorConsts.cardBackground,
            border: !_isYearlyPlan ? Border.all(color: ColorConsts.primary, width: 2.0) : null,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PressableCard(
            margin: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            borderRadius: 16.0,
            elevation: 0.0,
            onTap: () {
              setState(() {
                _isYearlyPlan = false;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(SpacingConsts.lg),
              child: Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: _isYearlyPlan,
                    onChanged: (value) {
                      setState(() {
                        _isYearlyPlan = value!;
                      });
                    },
                    activeColor: ColorConsts.primary,
                  ),
                  
                  const SizedBox(width: SpacingConsts.sm),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BillingTextConsts.monthlyPlanTitle,
                          style: TextConsts.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ColorConsts.textPrimary,
                          ),
                        ),
                        const SizedBox(height: SpacingConsts.xs),
                        Text(
                          BillingTextConsts.monthlyPrice,
                          style: TextConsts.h4.copyWith(
                            color: ColorConsts.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingConsts.sm,
                      vertical: SpacingConsts.xs,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      BillingTextConsts.freeTrialBadge,
                      style: TextConsts.caption.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: SpacingConsts.md),
        
        // 年額プラン
        Container(
          decoration: BoxDecoration(
            color: _isYearlyPlan ? ColorConsts.primary.withOpacity(0.1) : ColorConsts.cardBackground,
            border: _isYearlyPlan ? Border.all(color: ColorConsts.primary, width: 2.0) : null,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PressableCard(
            margin: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            borderRadius: 16.0,
            elevation: 0.0,
            onTap: () {
              setState(() {
                _isYearlyPlan = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(SpacingConsts.lg),
              child: Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _isYearlyPlan,
                    onChanged: (value) {
                      setState(() {
                        _isYearlyPlan = value!;
                      });
                    },
                    activeColor: ColorConsts.primary,
                  ),
                  
                  const SizedBox(width: SpacingConsts.sm),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BillingTextConsts.yearlyPlanTitle,
                          style: TextConsts.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ColorConsts.textPrimary,
                          ),
                        ),
                        const SizedBox(height: SpacingConsts.xs),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              BillingTextConsts.yearlyPrice,
                              style: TextConsts.h4.copyWith(
                                color: ColorConsts.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              BillingTextConsts.yearlyPricePerMonth,
                              style: TextConsts.bodySmall.copyWith(
                                color: ColorConsts.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingConsts.sm,
                      vertical: SpacingConsts.xs,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      BillingTextConsts.yearlyDiscount,
                      style: TextConsts.caption.copyWith(
                        color: const Color(0xFFFF6B35),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricing() {
    return PressableCard(
      margin: EdgeInsets.zero,
      backgroundColor: ColorConsts.cardBackground,
      borderRadius: 16.0,
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(SpacingConsts.lg),
        child: Column(
          children: [
            if (!_isYearlyPlan) ...[
              // 月額プランの価格表示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    BillingTextConsts.introPrice,
                    style: TextConsts.h2.copyWith(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: SpacingConsts.xs),
                  Text(
                    BillingTextConsts.introPriceLabel,
                    style: TextConsts.bodyMedium.copyWith(
                      color: ColorConsts.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: SpacingConsts.xs),
              
              Text(
                BillingTextConsts.introDiscount,
                style: TextConsts.bodySmall.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: SpacingConsts.sm),
              
              Text(
                BillingTextConsts.afterIntroPrice,
                style: TextConsts.bodyMedium.copyWith(
                  color: ColorConsts.textSecondary,
                ),
              ),
            ] else ...[
              // 年額プランの価格表示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    BillingTextConsts.yearlyPrice,
                    style: TextConsts.h2.copyWith(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: SpacingConsts.xs),
              
              Text(
                BillingTextConsts.yearlySavings,
                style: TextConsts.bodySmall.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: SpacingConsts.sm),
              
              Text(
                BillingTextConsts.yearlyTotalSavings,
                style: TextConsts.bodyMedium.copyWith(
                  color: ColorConsts.textSecondary,
                ),
              ),
            ],
            
            const SizedBox(height: SpacingConsts.md),
            
            Container(
              padding: const EdgeInsets.all(SpacingConsts.md),
              decoration: BoxDecoration(
                color: ColorConsts.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ColorConsts.primary,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingConsts.sm),
                  Expanded(
                    child: Text(
                      BillingTextConsts.trialInfo,
                      style: TextConsts.bodySmall.copyWith(
                        color: ColorConsts.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final billingState = ref.watch(billingViewModelProvider);
    final isProcessing = billingState.isPurchasing || billingState.isLoading;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CommonButton(
            text: isProcessing 
                ? BillingTextConsts.loading
                : (_isYearlyPlan 
                    ? BillingTextConsts.startYearlyButton 
                    : BillingTextConsts.startTrialButton),
            variant: ButtonVariant.primary,
            size: ButtonSize.large,
            onPressed: isProcessing ? null : _handlePurchase,
            isExpanded: true,
          ),
        ),
        
        const SizedBox(height: SpacingConsts.md),
        
        SizedBox(
          width: double.infinity,
          child: CommonButton(
            text: BillingTextConsts.restorePurchaseButton,
            variant: ButtonVariant.ghost,
            size: ButtonSize.medium,
            onPressed: isProcessing ? null : _handleRestorePurchase,
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndNotes() {
    return Column(
      children: [
        Text(
          BillingTextConsts.autoRenewalNote,
          style: TextConsts.bodySmall.copyWith(
            color: ColorConsts.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: SpacingConsts.sm),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _showTermsOfService,
              child: Text(
                BillingTextConsts.termsOfService,
                style: TextConsts.bodySmall.copyWith(
                  color: ColorConsts.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            
            Text(
              ' • ',
              style: TextConsts.bodySmall.copyWith(
                color: ColorConsts.textTertiary,
              ),
            ),
            
            TextButton(
              onPressed: _showPrivacyPolicy,
              child: Text(
                BillingTextConsts.privacyPolicy,
                style: TextConsts.bodySmall.copyWith(
                  color: ColorConsts.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handlePurchase() async {
    final billingViewModel = ref.read(billingViewModelProvider.notifier);
    
    // 商品IDを決定（月額 or 年額）
    final productId = _isYearlyPlan 
        ? 'goal_timer_premium_1_year' 
        : 'goal_timer_premium_1_month';
    
    // 購入処理を実行
    await billingViewModel.purchaseProduct(productId);
    
    // 購入結果を確認
    final state = ref.read(billingViewModelProvider);
    
    if (state.lastPurchaseResult != null) {
      switch (state.lastPurchaseResult!.type) {
        case PurchaseResultType.success:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(BillingTextConsts.purchaseSuccess),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
          break;
        case PurchaseResultType.cancelled:
          // キャンセルされた場合は何もしない
          break;
        case PurchaseResultType.error:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? BillingTextConsts.purchaseError),
                backgroundColor: Colors.red,
              ),
            );
          }
          break;
        default:
          break;
      }
    }
  }

  void _handleRestorePurchase() async {
    final billingViewModel = ref.read(billingViewModelProvider.notifier);
    
    // 購入復元処理を実行
    await billingViewModel.restorePurchases();
    
    // 復元結果を確認
    final state = ref.read(billingViewModelProvider);
    
    if (state.lastRestoreResult != null) {
      if (state.lastRestoreResult!.success) {
        if (state.lastRestoreResult!.restoredCount > 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(BillingTextConsts.restoreSuccess),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('復元可能な購入が見つかりませんでした'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? BillingTextConsts.restoreError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(BillingTextConsts.termsOfService),
        content: Text(BillingTextConsts.termsContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(BillingTextConsts.closeButton),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(BillingTextConsts.privacyPolicy),
        content: Text(BillingTextConsts.privacyContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(BillingTextConsts.closeButton),
          ),
        ],
      ),
    );
  }
}