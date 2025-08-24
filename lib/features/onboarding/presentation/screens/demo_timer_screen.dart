import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/widgets/common_button.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/demo_timer_widget.dart';
import '../view_models/onboarding_view_model.dart';

/// デモタイマー画面（オンボーディング ステップ2）
class DemoTimerScreen extends ConsumerStatefulWidget {
  const DemoTimerScreen({super.key});

  @override
  ConsumerState<DemoTimerScreen> createState() => _DemoTimerScreenState();
}

class _DemoTimerScreenState extends ConsumerState<DemoTimerScreen> {
  bool _isTimerCompleted = false;

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingViewModelProvider);

    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'タイマー機能を体験',
          style: TextConsts.h4.copyWith(color: ColorConsts.textPrimary),
        ),
        backgroundColor: ColorConsts.backgroundPrimary,
        elevation: 0,
        automaticallyImplyLeading: false, // 戻るボタンなし
      ),
      body: Column(
        children: [
          // プログレスバー
          const OnboardingProgressBar(
            progress: 0.66,
            currentStep: 2,
            totalSteps: 3,
          ),

          // タイマーデモ部分
          Expanded(
            child:
                _isTimerCompleted
                    ? _buildCompletionContent()
                    : _buildTimerContent(),
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

          // 次へボタン（タイマー完了後に表示）
          if (_isTimerCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingConsts.md),
              child: CommonButton(
                key: const Key('next_button'),
                text: '次へ',
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                isExpanded: true,
                isLoading: onboardingState.isLoading,
                onPressed: _onNextPressed,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimerContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: SpacingConsts.xl),

          // 説明テキスト
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SpacingConsts.md),
            child: Column(
              children: [
                Text(
                  'Goal Timerの核となる機能です',
                  style: TextConsts.h3.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SpacingConsts.md),
                Text(
                  '学習時間を正確に記録し、\n目標達成をサポートします',
                  style: TextConsts.bodyLarge.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: SpacingConsts.xl),

          // デモタイマーウィジェット
          DemoTimerWidget(onTimerComplete: _onTimerComplete),
        ],
      ),
    );
  }

  Widget _buildCompletionContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(SpacingConsts.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 完了アイコン
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ColorConsts.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer,
                size: 60,
                color: ColorConsts.success,
              ),
            ),

            const SizedBox(height: SpacingConsts.xl),

            // 完了メッセージ
            Text(
              'タイマー体験完了！',
              style: TextConsts.h2.copyWith(
                color: ColorConsts.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: SpacingConsts.md),

            Text(
              'お疲れさまでした！\nタイマー機能の動作を確認できましたね。',
              style: TextConsts.bodyLarge.copyWith(
                color: ColorConsts.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: SpacingConsts.xl),

            // 機能説明カード
            Container(
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
                    '実際のアプリでは...',
                    style: TextConsts.labelLarge.copyWith(
                      color: ColorConsts.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: SpacingConsts.md),
                  _buildFeaturePoint('⏱️ 自由時間設定でじっくり学習'),
                  _buildFeaturePoint('📊 学習記録の自動保存'),
                  _buildFeaturePoint('🎯 目標達成率の可視化'),
                  _buildFeaturePoint('📈 継続日数の管理'),
                ],
              ),
            ),

            const SizedBox(height: SpacingConsts.xl),

            // 次のステップ案内
            Container(
              padding: const EdgeInsets.all(SpacingConsts.md),
              decoration: BoxDecoration(
                color: ColorConsts.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: ColorConsts.primary,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingConsts.sm),
                  Expanded(
                    child: Text(
                      '次は、より便利に使うためのアカウント設定について説明します',
                      style: TextConsts.bodySmall.copyWith(
                        color: ColorConsts.primary,
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

  Widget _buildFeaturePoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingConsts.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextConsts.bodyMedium.copyWith(
              color: ColorConsts.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: SpacingConsts.sm),
          Expanded(
            child: Text(
              text,
              style: TextConsts.bodyMedium.copyWith(
                color: ColorConsts.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTimerComplete() {
    setState(() {
      _isTimerCompleted = true;
    });

    // 完了ダイアログを少し遅らせて表示
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _showCompletionDialogMethod();
      }
    });
  }

  void _showCompletionDialogMethod() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.celebration,
                  color: ColorConsts.success,
                  size: 28,
                ),
                const SizedBox(width: SpacingConsts.sm),
                Text(
                  'デモ完了！',
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'タイマー機能の体験が完了しました。\n実際の学習では、もっと長い時間を設定して使用できます。',
              style: TextConsts.bodyMedium.copyWith(
                color: ColorConsts.textSecondary,
              ),
            ),
            actions: [
              CommonButton(
                text: 'OK',
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _onNextPressed() async {
    final onboardingViewModel = ref.read(onboardingViewModelProvider.notifier);

    try {
      // ステップ2完了
      await onboardingViewModel.completeDemoTimer();

      // 次の画面に遷移
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/onboarding/account-promotion',
        );
      }
    } catch (e) {
      // エラーは onboardingViewModel 内で処理される
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('デモタイマー完了処理に失敗しました: $e'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }
}
