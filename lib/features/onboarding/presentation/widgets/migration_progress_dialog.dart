import 'package:flutter/material.dart';
import '../../../../core/utils/color_consts.dart';
import '../../../../core/utils/spacing_consts.dart';
import '../../../../core/utils/text_consts.dart';
import '../../../../core/utils/animation_consts.dart';

/// データ移行中のプログレスダイアログ
class MigrationProgressDialog extends StatefulWidget {
  const MigrationProgressDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => const MigrationProgressDialog(),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  State<MigrationProgressDialog> createState() =>
      _MigrationProgressDialogState();
}

class _MigrationProgressDialogState extends State<MigrationProgressDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0 * 3.14159).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(SpacingConsts.xl),
            decoration: BoxDecoration(
              color: ColorConsts.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ColorConsts.primary.withValues(alpha: 0.2),
                  offset: const Offset(0, 10),
                  blurRadius: 30,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // アニメーションアイコン
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                ColorConsts.primary,
                                ColorConsts.primaryLight,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.sync,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: SpacingConsts.lg),

                // タイトル
                Text(
                  'データを移行中',
                  style: TextConsts.h4.copyWith(
                    color: ColorConsts.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: SpacingConsts.sm),

                // サブタイトル
                Text(
                  'あなたの学習データを\nアカウントに移行しています',
                  style: TextConsts.bodyMedium.copyWith(
                    color: ColorConsts.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: SpacingConsts.lg),

                // プログレスインジケーター
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: ColorConsts.backgroundSecondary,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ColorConsts.primary,
                    ),
                    minHeight: 4,
                  ),
                ),

                const SizedBox(height: SpacingConsts.lg),

                // 移行項目
                _buildMigrationItem('目標データ', true),
                _buildMigrationItem('学習記録', true),
                _buildMigrationItem('統計データ', false),

                const SizedBox(height: SpacingConsts.md),

                // 注意書き
                Container(
                  padding: const EdgeInsets.all(SpacingConsts.md),
                  decoration: BoxDecoration(
                    color: ColorConsts.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: ColorConsts.primary,
                      ),
                      const SizedBox(width: SpacingConsts.sm),
                      Expanded(
                        child: Text(
                          'この処理には数秒かかります',
                          style: TextConsts.caption.copyWith(
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
        ),
      ),
    );
  }

  Widget _buildMigrationItem(String label, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingConsts.xs),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isCompleted
                      ? ColorConsts.success.withValues(alpha: 0.2)
                      : ColorConsts.backgroundSecondary,
            ),
            child:
                isCompleted
                    ? Icon(Icons.check, size: 12, color: ColorConsts.success)
                    : SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorConsts.textTertiary,
                        ),
                      ),
                    ),
          ),
          const SizedBox(width: SpacingConsts.sm),
          Text(
            label,
            style: TextConsts.bodySmall.copyWith(
              color:
                  isCompleted
                      ? ColorConsts.textPrimary
                      : ColorConsts.textTertiary,
            ),
          ),
          if (isCompleted) ...[
            const Spacer(),
            Text(
              '完了',
              style: TextConsts.caption.copyWith(
                color: ColorConsts.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
