import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../auth/view/login_screen.dart';
import '../view_model/welcome_view_model.dart';

/// ウェルカム画面（Top画面）
/// ログアウト後またはアカウント削除後に表示される
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(WelcomeViewModel());
  }

  @override
  void dispose() {
    Get.delete<WelcomeViewModel>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConsts.backgroundPrimary,
      body: GetBuilder<WelcomeViewModel>(
        builder: (viewModel) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingConsts.xl,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // アプリロゴ
                  _buildAppLogo(),

                  const SizedBox(height: SpacingConsts.xl),

                  // キャッチコピー
                  _buildCatchCopy(),

                  const Spacer(flex: 2),

                  // ボタン群
                  _buildButtons(viewModel),

                  const SizedBox(height: SpacingConsts.l),

                  // 説明テキスト
                  _buildDescription(),

                  const SizedBox(height: SpacingConsts.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: ColorConsts.shadowMedium,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/icons/goal_timer_app_icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCatchCopy() {
    return Column(
      children: [
        Text(
          '目標達成を、',
          style: TextConsts.h2.copyWith(
            color: ColorConsts.textPrimary,
          ),
        ),
        Text(
          '習慣に変える',
          style: TextConsts.h2.copyWith(
            color: ColorConsts.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(WelcomeViewModel viewModel) {
    return Column(
      children: [
        // すぐに始めるボタン（Primary）
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: viewModel.isLoading ? null : _onStartAsGuestPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConsts.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: viewModel.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'すぐに始める',
                    style: TextConsts.buttonLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: SpacingConsts.m),

        // ログインボタン（Secondary）
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: viewModel.isLoading ? null : _onLoginPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConsts.primary,
              side: const BorderSide(
                color: ColorConsts.primary,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'ログイン',
              style: TextConsts.buttonLarge.copyWith(
                color: ColorConsts.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      'ログインすると、データを\n引き継いで再開できます',
      style: TextConsts.bodySmall.copyWith(
        color: ColorConsts.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _onStartAsGuestPressed() async {
    final viewModel = Get.find<WelcomeViewModel>();
    await viewModel.startAsGuest();
  }

  void _onLoginPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(mode: LoginMode.login),
      ),
    );
  }
}
