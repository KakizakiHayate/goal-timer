import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/view/home_screen.dart';
import '../../welcome/view/welcome_screen.dart';
import '../view_model/splash_view_model.dart';

/// Splash画面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Get.put(SplashViewModel());
    _initializeApp();
  }

  @override
  void dispose() {
    Get.delete<SplashViewModel>();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _viewModel.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConsts.primary,
      body: GetBuilder<SplashViewModel>(
        builder: (viewModel) {
          // 完了したらホーム画面へ遷移
          if (viewModel.status == SplashStatus.completedToHome) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToHome();
            });
          }

          // 完了したらウェルカム画面へ遷移
          if (viewModel.status == SplashStatus.completedToWelcome) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToWelcome();
            });
          }

          // オフラインダイアログを表示
          if (viewModel.isOffline) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showOfflineDialog();
            });
          }

          // エラーダイアログを表示
          if (viewModel.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showErrorDialog(viewModel.errorMessage);
            });
          }

          return _buildContent(viewModel);
        },
      ),
    );
  }

  Widget _buildContent(SplashViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アプリアイコン/ロゴ
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.timer,
              size: 64,
              color: ColorConsts.primary,
            ),
          ),

          const SizedBox(height: SpacingConsts.xl),

          // アプリ名
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.appName ?? 'Goal Timer',
                style: TextConsts.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),

          const SizedBox(height: SpacingConsts.xxl),

          // ローディングインジケーター
          if (!viewModel.isOffline && !viewModel.hasError) ...[
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: SpacingConsts.l),
            Builder(
              builder: (context) {
                return Text(
                  _getStatusMessage(context, viewModel.status),
                  style: TextConsts.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusMessage(BuildContext context, SplashStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case SplashStatus.initial:
      case SplashStatus.checkingNetwork:
        return l10n?.splashCheckingNetwork ?? 'Checking network...';
      case SplashStatus.authenticating:
        return l10n?.splashAuthenticating ?? 'Authenticating...';
      case SplashStatus.migrating:
        return l10n?.splashPreparingData ?? 'Preparing data...';
      case SplashStatus.completedToHome:
      case SplashStatus.completedToWelcome:
        return l10n?.splashComplete ?? 'Complete';
      case SplashStatus.offline:
        return l10n?.splashOffline ?? 'Offline';
      case SplashStatus.error:
        return l10n?.splashErrorOccurred ?? 'An error occurred';
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _navigateToWelcome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _showOfflineDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.networkErrorTitle ?? 'Network Error'),
        content: Text(
          l10n?.networkErrorMessage ??
              'Please connect to the network.\nThis app requires an internet connection.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _viewModel.retryFromOffline();
            },
            child: Text(l10n?.btnRetry ?? 'Retry'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.errorTitle ?? 'Error'),
        content: Text(
          l10n?.initializationFailedMessage ??
              'Initialization failed. Please contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _viewModel.retryFromOffline();
            },
            child: Text(l10n?.btnRetry ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}
