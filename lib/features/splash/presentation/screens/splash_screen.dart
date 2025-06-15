import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/config/env_config.dart';
import 'package:goal_timer/features/home/presentation/screens/home_screen.dart';
import 'package:goal_timer/features/splash/provider/splash_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splashState = ref.watch(splashViewModelProvider);

    // 接続に成功した場合、ホーム画面に移動
    if (!splashState.isLoading && splashState.isConnectionOk) {
      // 画面遷移を遅延実行（すぐに遷移するとスプラッシュが見えない）
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      });
    }

    // エラーがある場合はダイアログを表示
    if (splashState.errorMessage != null) {
      // ダイアログを遅延表示（ビルド完了後に表示）
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          showNetworkErrorDialog(
            context,
            message: splashState.errorMessage!,
            details: splashState.errorDetails,
            onRetry: () {
              ref.read(splashViewModelProvider.notifier).retryConnection();
            },
          );
        }
      });
    }

    // ローディング中はスプラッシュ画面を表示
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16), // 角丸の半径
              child: Image.asset(
                'assets/icons/goal_timer_app_icon.png',
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.width * 0.5,
              ),
            ),
            const SizedBox(height: 32),
            if (splashState.isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  // ネットワークエラーダイアログを表示
  void showNetworkErrorDialog(
    BuildContext context, {
    required String message,
    String? details,
    required VoidCallback onRetry,
  }) {
    // すでにダイアログが表示されている場合は表示しない
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // ダイアログ外をタップしても閉じない
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (details != null) ...[
                  const Text('エラー詳細:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(details, style: const TextStyle(fontSize: 14)),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('ネットワーク接続を確認して再試行してください。'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('開発者向け情報'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Supabaseの接続情報:'),
                            const SizedBox(height: 8),
                            Text('URL: ${EnvConfig.supabaseUrl}'),
                            Text('APP_ENV: ${EnvConfig.appEnv}'),
                            Text('デバイスID: ${EnvConfig.deviceId}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                );
              },
              child: const Text('詳細'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onRetry();
              },
              child: const Text('再試行'),
            ),
          ],
        );
      },
    );
  }
}
