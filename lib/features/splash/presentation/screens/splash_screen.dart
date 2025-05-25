import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/config/env_config.dart';
import 'package:goal_timer/features/home/presentation/screens/home_screen.dart';
import 'package:goal_timer/features/splash/presentation/viewmodels/splash_view_model.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // スプラッシュViewModelの状態を監視
    final splashState = ref.watch(splashViewModelProvider);

    // 接続に成功した場合、ホーム画面に移動
    if (!splashState.isLoading && splashState.isConnectionOk) {
      // 画面遷移を遅延実行（すぐに遷移するとスプラッシュが見えない）
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppRouter()),
        );
      });
    }

    // エラーがある場合はエラー画面を表示
    if (splashState.errorMessage != null) {
      return ErrorScreen(
        message: splashState.errorMessage!,
        details: splashState.errorDetails,
        onRetry: () {
          ref.read(splashViewModelProvider.notifier).retryConnection();
        },
      );
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
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goal Timer',
      theme: Theme.of(context),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (details != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    details!,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed:
                        onRetry ??
                        () {
                          // 再起動処理を簡素化
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SplashScreen(),
                            ),
                          );
                        },
                    child: const Text('再試行'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {
                      // 開発者に問い合わせるボタン、または設定画面へ
                      // 現時点では単にダイアログを表示
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
