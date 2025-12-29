import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/common_button.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/migration_progress_dialog.dart';
import '../view_models/onboarding_view_model.dart';
import '../view_models/tutorial_view_model.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_button.dart';
import '../../../../core/services/data_migration_service.dart';
import '../../../../core/services/temp_user_service.dart';

/// アカウント作成促進画面（オンボーディング ステップ3）
class AccountPromotionScreen extends ConsumerStatefulWidget {
  final bool fromSettings;
  final bool skipOnboardingFlow;

  const AccountPromotionScreen({
    super.key,
    this.fromSettings = false,
    this.skipOnboardingFlow = false,
  });

  @override
  ConsumerState<AccountPromotionScreen> createState() =>
      _AccountPromotionScreenState();
}

class _AccountPromotionScreenState
    extends ConsumerState<AccountPromotionScreen> {
  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingViewModelProvider);

    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          widget.fromSettings ? 'アカウント連携' : 'アカウント設定',
          style: TextConsts.h4.copyWith(color: ColorConsts.textPrimary),
        ),
        backgroundColor: ColorConsts.backgroundPrimary,
        elevation: 0,
        automaticallyImplyLeading: widget.fromSettings, // 設定画面からの場合は戻るボタンを表示
      ),
      body: Column(
        children: [
          // プログレスバー（設定画面からの場合は非表示）
          if (!widget.fromSettings)
            const OnboardingProgressBar(
              progress: 1.0,
              currentStep: 3,
              totalSteps: 3,
            ),

          // メインコンテンツ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SpacingConsts.md),
              child: Column(
                children: [
                  const SizedBox(height: SpacingConsts.xl),

                  // メインアイコン
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ColorConsts.primary, ColorConsts.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: SpacingConsts.xl),

                  // メインメッセージ
                  Text(
                    'アカウントを作成して\nより便利に使いませんか？',
                    style: TextConsts.h2.copyWith(
                      color: ColorConsts.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: SpacingConsts.md),

                  Text(
                    'アカウント作成で、複数デバイスでの\nデータ同期や目標数の制限解除が可能になります',
                    style: TextConsts.bodyLarge.copyWith(
                      color: ColorConsts.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: SpacingConsts.xl),

                  // アカウント作成のメリット
                  _buildBenefitsSection(),

                  const SizedBox(height: SpacingConsts.xl),

                  // プラン比較
                  _buildPlanComparisonSection(),

                  const SizedBox(height: SpacingConsts.xl),

                  // 選択肢説明
                  Container(
                    padding: const EdgeInsets.all(SpacingConsts.md),
                    decoration: BoxDecoration(
                      color: ColorConsts.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: ColorConsts.primary,
                              size: 20,
                            ),
                            const SizedBox(width: SpacingConsts.sm),
                            Text(
                              'どちらでも大丈夫です',
                              style: TextConsts.labelLarge.copyWith(
                                color: ColorConsts.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SpacingConsts.sm),
                        Text(
                          '今すぐアカウントを作成しなくても、ゲストとして目標管理を始められます。後からいつでもアカウント作成できます。',
                          style: TextConsts.bodySmall.copyWith(
                            color: ColorConsts.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // エラー表示
          if (onboardingState.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(SpacingConsts.md),
              padding: const EdgeInsets.all(SpacingConsts.md),
              decoration: BoxDecoration(
                color: ColorConsts.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorConsts.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: ColorConsts.error,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingConsts.sm),
                  Expanded(
                    child: Text(
                      onboardingState.errorMessage!,
                      style: TextConsts.bodySmall.copyWith(
                        color: ColorConsts.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ボタン群
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingConsts.md),
            child: Column(
              children: [
                // ソーシャルログインセクション
                Text(
                  'アカウントを作成',
                  style: TextConsts.labelLarge.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SpacingConsts.md),

                // Googleサインインボタン
                AuthButton(
                  type: AuthButtonType.google,
                  text: 'Googleで続ける',
                  onPressed:
                      onboardingState.isLoading ? null : _onGoogleSignInPressed,
                  isLoading: onboardingState.isLoading,
                ),
                const SizedBox(height: SpacingConsts.sm),

                // Appleサインインボタン (iOSのみ表示)
                if (AuthButton.shouldShowAppleLogin())
                  AuthButton(
                    type: AuthButtonType.apple,
                    text: 'Appleで続ける',
                    onPressed:
                        onboardingState.isLoading
                            ? null
                            : _onAppleSignInPressed,
                    isLoading: onboardingState.isLoading,
                  ),
                if (AuthButton.shouldShowAppleLogin())
                  const SizedBox(height: SpacingConsts.sm),

                // メールサインインボタン
                AuthButton(
                  type: AuthButtonType.email,
                  text: 'メールアドレスで続ける',
                  onPressed:
                      onboardingState.isLoading ? null : _onEmailSignInPressed,
                  isLoading: onboardingState.isLoading,
                ),

                const SizedBox(height: SpacingConsts.lg),

                // または分割線（設定画面からの場合は非表示）
                if (!widget.fromSettings)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: ColorConsts.textTertiary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingConsts.md,
                        ),
                        child: Text(
                          'または',
                          style: TextConsts.bodySmall.copyWith(
                            color: ColorConsts.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: ColorConsts.textTertiary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                if (!widget.fromSettings)
                  const SizedBox(height: SpacingConsts.lg),

                // ゲストとして続行ボタン（設定画面からの場合は非表示）
                if (!widget.fromSettings)
                  CommonButton(
                    key: const Key('continue_as_guest_button'),
                    text: 'ゲストとして続行',
                    variant: ButtonVariant.ghost,
                    size: ButtonSize.large,
                    isExpanded: true,
                    isLoading:
                        onboardingState.isLoading &&
                        onboardingState.isDataMigrationInProgress,
                    onPressed: _onContinueAsGuestPressed,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.lg),
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConsts.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'アカウント作成のメリット',
            style: TextConsts.labelLarge.copyWith(
              color: ColorConsts.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingConsts.md),
          _buildBenefitItem(
            icon: Icons.sync,
            title: 'データ同期',
            description: '複数のデバイスで学習記録を同期',
          ),
          _buildBenefitItem(
            icon: Icons.backup,
            title: 'データバックアップ',
            description: '大切な学習データを安全に保存',
          ),
          _buildBenefitItem(
            icon: Icons.add_circle,
            title: '目標数増加',
            description: '3つまで目標を設定可能（ゲストは1つ）',
          ),
          _buildBenefitItem(
            icon: Icons.trending_up,
            title: '詳細な統計',
            description: '学習の傾向分析と詳細レポート',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingConsts.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ColorConsts.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: ColorConsts.primary),
          ),
          const SizedBox(width: SpacingConsts.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextConsts.labelMedium.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextConsts.bodySmall.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanComparisonSection() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConsts.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConsts.primary.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'プラン比較',
            style: TextConsts.labelLarge.copyWith(
              color: ColorConsts.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingConsts.md),
          Row(
            children: [
              // ゲストプラン
              Expanded(
                child: _buildPlanCard(
                  title: 'ゲスト',
                  price: '無料',
                  features: ['目標: 1つまで', 'ローカル保存のみ', '基本統計'],
                  isRecommended: false,
                ),
              ),
              const SizedBox(width: SpacingConsts.md),
              // 無料プラン
              Expanded(
                child: _buildPlanCard(
                  title: '無料アカウント',
                  price: '無料',
                  features: ['目標: 3つまで', 'クラウド同期', '詳細統計'],
                  isRecommended: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isRecommended,
  }) {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.md),
      decoration: BoxDecoration(
        color:
            isRecommended
                ? ColorConsts.primary.withValues(alpha: 0.05)
                : ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isRecommended
                  ? ColorConsts.primary
                  : ColorConsts.primary.withValues(alpha: 0.2),
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingConsts.sm,
                vertical: SpacingConsts.xs,
              ),
              decoration: BoxDecoration(
                color: ColorConsts.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'おすすめ',
                style: TextConsts.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (isRecommended) const SizedBox(height: SpacingConsts.sm),
          Text(
            title,
            style: TextConsts.labelLarge.copyWith(
              color: ColorConsts.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingConsts.xs),
          Text(
            price,
            style: TextConsts.h4.copyWith(
              color:
                  isRecommended
                      ? ColorConsts.primary
                      : ColorConsts.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SpacingConsts.sm),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingConsts.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 12,
                    color:
                        isRecommended
                            ? ColorConsts.primary
                            : ColorConsts.textSecondary,
                  ),
                  const SizedBox(width: SpacingConsts.xs),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextConsts.caption.copyWith(
                        color: ColorConsts.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGoogleSignInPressed() async {
    final authViewModel = ref.read(authViewModelProvider.notifier);
    final onboardingViewModel = ref.read(onboardingViewModelProvider.notifier);
    final tempUserService = ref.read(tempUserServiceProvider);
    final migrationService = ref.read(dataMigrationServiceProvider);

    try {
      // 一時ユーザーの存在を確認
      final hasTempUser = await tempUserService.getTempUserId() != null;

      // 移行ダイアログを表示（一時ユーザーがいる場合）
      if (hasTempUser && mounted) {
        MigrationProgressDialog.show(context);
      }

      try {
        // 移行をサポートする新しいメソッドを使用
        await authViewModel.signInWithGoogleAndMigrate(
          tempUserService: tempUserService,
          migrationService: migrationService,
        );

        // オンボーディング完了
        await onboardingViewModel.completeAccountCreation();
      } finally {
        // ダイアログを閉じる
        if (hasTempUser && mounted) {
          MigrationProgressDialog.hide(context);
        }
      }

      if (mounted) {
        if (widget.fromSettings) {
          // 設定画面から来た場合は設定画面に戻る
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Googleアカウント連携が完了しました'),
              backgroundColor: ColorConsts.success,
            ),
          );
        } else {
          // 通常のオンボーディングフロー
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Googleサインインに失敗しました: $e'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }

  Future<void> _onAppleSignInPressed() async {
    final authViewModel = ref.read(authViewModelProvider.notifier);
    final onboardingViewModel = ref.read(onboardingViewModelProvider.notifier);
    final tempUserService = ref.read(tempUserServiceProvider);
    final migrationService = ref.read(dataMigrationServiceProvider);

    try {
      // 一時ユーザーの存在を確認
      final hasTempUser = await tempUserService.getTempUserId() != null;

      // 移行ダイアログを表示（一時ユーザーがいる場合）
      if (hasTempUser && mounted) {
        MigrationProgressDialog.show(context);
      }

      try {
        // 移行をサポートする新しいメソッドを使用
        await authViewModel.signInWithAppleAndMigrate(
          tempUserService: tempUserService,
          migrationService: migrationService,
        );

        // オンボーディング完了
        await onboardingViewModel.completeAccountCreation();
      } finally {
        // ダイアログを閉じる
        if (hasTempUser && mounted) {
          MigrationProgressDialog.hide(context);
        }
      }

      if (mounted) {
        if (widget.fromSettings) {
          // 設定画面から来た場合は設定画面に戻る
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appleアカウント連携が完了しました'),
              backgroundColor: ColorConsts.success,
            ),
          );
        } else {
          // 通常のオンボーディングフロー
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appleサインインに失敗しました: $e'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }

  Future<void> _onEmailSignInPressed() async {
    // メール認証は専用画面に遷移
    if (mounted) {
      Navigator.pushNamed(context, '/auth/signin');
    }
  }

  Future<void> _onContinueAsGuestPressed() async {
    final onboardingViewModel = ref.read(onboardingViewModelProvider.notifier);
    final tutorialViewModel = ref.read(tutorialViewModelProvider.notifier);
    final tutorialState = ref.read(tutorialViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    try {
      // 認証状態をゲスト状態にリセット（エラー状態をクリア）
      authViewModel.setGuestState();

      // ゲストとして続行
      await onboardingViewModel.continueAsGuest();

      // チュートリアルが既に開始されているかチェック
      // goal_creation_screen.dartで既にstartTutorialが呼ばれているはず
      if (!tutorialState.isTutorialActive && !tutorialState.isCompleted) {
        AppLogger.instance.w(
          'Tutorial not active after goal creation, restarting tutorial',
        );
        final onboardingState = ref.read(onboardingViewModelProvider);
        await tutorialViewModel.startTutorial(
          tempUserId: onboardingState.tempUserId,
          totalSteps:
              3, // goal_selection -> timer_operation -> timer_completion
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (error, stackTrace) {
      AppLogger.instance.e('ゲストモード開始に失敗しました', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ゲストモード開始に失敗しました: $error'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }
}
