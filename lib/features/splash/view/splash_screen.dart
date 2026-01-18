import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/color_consts.dart';
import '../../../core/utils/spacing_consts.dart';
import '../../../core/utils/text_consts.dart';
import '../../home/view/home_screen.dart';
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
          if (viewModel.status == SplashStatus.completed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToHome();
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
            child: Icon(
              Icons.timer,
              size: 64,
              color: ColorConsts.primary,
            ),
          ),

          const SizedBox(height: SpacingConsts.xl),

          // アプリ名
          Text(
            '目標達成タイマー',
            style: TextConsts.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
            Text(
              _getStatusMessage(viewModel.status),
              style: TextConsts.body.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusMessage(SplashStatus status) {
    switch (status) {
      case SplashStatus.initial:
      case SplashStatus.checkingNetwork:
        return 'ネットワークを確認しています...';
      case SplashStatus.authenticating:
        return '認証しています...';
      case SplashStatus.migrating:
        return 'データを準備しています...';
      case SplashStatus.completed:
        return '完了';
      case SplashStatus.offline:
        return 'オフライン';
      case SplashStatus.error:
        return 'エラーが発生しました';
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showOfflineDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ネットワークエラー'),
        content: const Text('ネットワークに接続してください。\nこのアプリはオンラインで動作します。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _viewModel.retryFromOffline();
            },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _viewModel.retryFromOffline();
            },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }
}
