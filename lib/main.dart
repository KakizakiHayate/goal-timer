import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/config/env_config.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/utils/route_names.dart';
import 'package:goal_timer/core/utils/supabase_utils.dart';
import 'package:goal_timer/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:goal_timer/features/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数ファイルの読み込み
  await dotenv.load(fileName: '.env');

  // 環境変数のログ出力（デバッグ用）
  print('環境変数: SUPABASE_URL = ${EnvConfig.supabaseUrl}');
  print('環境変数: APP_ENV = ${EnvConfig.appEnv}');
  print('環境変数: DEBUG_MODE = ${EnvConfig.isDebugMode}');

  // UIのレンダリングを最適化
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Supabaseの初期化を監視
    final supabaseInit = ref.watch(supabaseInitProvider);

    return MaterialApp(
      title: 'Goal Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: supabaseInit.when(
        data:
            (_) => FutureBuilder(
              // 初期化完了後に接続状態を確認
              future: _checkSupabaseConnection(ref),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplashScreen();
                }

                if (snapshot.hasError) {
                  return ErrorScreen(
                    message: '初期化エラー: ${snapshot.error.toString()}',
                    details:
                        '環境変数が正しく設定されているか確認してください。\nSUPABASE_URL: ${EnvConfig.supabaseUrl.substring(0, math.min(20, EnvConfig.supabaseUrl.length))}...',
                  );
                }

                final connectionOk = snapshot.data as bool;
                if (!connectionOk) {
                  return ErrorScreen(
                    message: 'Supabaseサーバーに接続できません',
                    details:
                        '1. .envファイル内のSUPABASE_URLとSUPABASE_ANON_KEYが正しいか確認してください\n'
                        '2. ネットワーク接続状態を確認してください\n'
                        '3. Supabaseプロジェクトが起動しているか確認してください',
                  );
                }

                // 接続確認が取れたのでアプリを表示
                return const AppRouter();
              },
            ),
        loading: () => const SplashScreen(),
        error:
            (error, stack) => ErrorScreen(
              message: 'Supabase初期化エラー',
              details: error.toString(),
            ),
      ),
    );
  }

  // Supabaseの接続状態を確認する
  Future<bool> _checkSupabaseConnection(WidgetRef ref) async {
    // 初期化状態を確認
    final statusError = SupabaseUtils.checkInitializationStatus(ref);
    if (statusError != null) {
      throw Exception(statusError);
    }

    // サーバー接続を確認
    return await SupabaseUtils.checkConnection(ref);
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
      initialRoute: RouteNames.home,
      onGenerateRoute: generateRoute,
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  final String? details;

  const ErrorScreen({super.key, required this.message, this.details});

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
                    onPressed: () {
                      // アプリを再起動する処理
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.home,
                        (route) => false,
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
