import 'package:flutter/material.dart';
import '../../../../../core/utils/color_consts.dart';
import '../../../../../core/utils/spacing_consts.dart';
import '../../../../../core/utils/text_consts.dart';
import '../../../../../core/widgets/common_button.dart';

/// チュートリアル完了を知らせるダイアログ
class TutorialCompletionDialog extends StatefulWidget {
  final Future<void> Function() onContinue;
  final String goalTitle;

  const TutorialCompletionDialog({
    super.key,
    required this.onContinue,
    required this.goalTitle,
  });

  @override
  State<TutorialCompletionDialog> createState() => _TutorialCompletionDialogState();

  static void show(
    BuildContext context, {
    required Future<void> Function() onContinue,
    required String goalTitle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialCompletionDialog(
        onContinue: onContinue,
        goalTitle: goalTitle,
      ),
    );
  }
}

class _TutorialCompletionDialogState extends State<TutorialCompletionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
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
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.all(SpacingConsts.lg),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                    maxWidth: MediaQuery.of(context).size.width - (SpacingConsts.lg * 2),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(SpacingConsts.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 成功アイコン
                        _buildSuccessIcon(),

                        const SizedBox(height: SpacingConsts.lg),

                        // タイトル
                        Text(
                          'チュートリアル完了！',
                          style: TextConsts.h2.copyWith(
                            color: ColorConsts.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: SpacingConsts.md),

                        // メッセージ
                        Text(
                          'お疲れ様でした！\n「${widget.goalTitle}」のタイマーを体験していただきました。',
                          style: TextConsts.bodyLarge.copyWith(
                            color: ColorConsts.textSecondary,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: SpacingConsts.lg),

                        // 機能説明
                        _buildFeatureExplanation(),

                        const SizedBox(height: SpacingConsts.xl),

                        // アカウント作成のメリット
                        _buildAccountBenefits(),

                        const SizedBox(height: SpacingConsts.xl),

                        // 続行ボタン
                        CommonButton(
                          text: 'アカウント作成へ進む',
                          variant: ButtonVariant.primary,
                          size: ButtonSize.large,
                          isExpanded: true,
                          onPressed: () {
                            widget.onContinue();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildFeatureExplanation() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.lg),
      decoration: BoxDecoration(
        color: ColorConsts.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: ColorConsts.primary,
                size: 20,
              ),
              const SizedBox(width: SpacingConsts.sm),
              Expanded(
                child: Text(
                  'タイマー機能の使い方',
                  style: TextConsts.labelLarge.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingConsts.sm),
          Text(
            '• 目標カードの「タイマー開始」ボタンで学習を開始\n'
            '• フォーカス・フリー・ポモドーロの3つのモードを選択可能\n'
            '• 学習時間は自動的に記録・蓄積されます',
            style: TextConsts.bodySmall.copyWith(
              color: ColorConsts.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountBenefits() {
    return Container(
      padding: const EdgeInsets.all(SpacingConsts.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConsts.primary.withValues(alpha: 0.05),
            ColorConsts.primaryLight.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConsts.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars,
                color: ColorConsts.primary,
                size: 20,
              ),
              const SizedBox(width: SpacingConsts.sm),
              Expanded(
                child: Text(
                  'アカウント作成で更に便利に',
                  style: TextConsts.labelLarge.copyWith(
                    color: ColorConsts.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingConsts.sm),
          Text(
            '• データの自動バックアップとデバイス間同期\n'
            '• 複数の目標設定（最大3つまで）\n'
            '• 詳細な学習統計とレポート機能',
            style: TextConsts.bodySmall.copyWith(
              color: ColorConsts.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}