import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/config/env_config.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:goal_timer/routes.dart';
// import 'package:goal_timer/core/services/sync_service.dart'; // 削除: 定期同期サービス無効化
import 'package:goal_timer/core/data/local/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // 環境変数のログ出力
  AppLogger.instance.i('環境変数: SUPABASE_URL = ${EnvConfig.supabaseUrl}');
  AppLogger.instance.i('環境変数: APP_ENV = ${EnvConfig.appEnv}');
  AppLogger.instance.i('環境変数: DEBUG_MODE = ${EnvConfig.isDebugMode}');

  // データベースの初期化
  await AppDatabase.instance.initialize();

  // AppDatabaseクラスがパス情報を既に表示しているので、ここでの出力は不要
  // データベースパスのみシンプルに標準出力に表示
  final dbPath = AppDatabase.databasePath;
  AppLogger.instance.i('SQLiteデータベースパス: $dbPath');

  // Supabaseの初期化はSplashScreenとprovidersで行うため、ここでは行わない

  // アプリ起動ログ
  AppLogger.instance.i('アプリケーションを起動します');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        // 同期サービスの初期化を削除: 定期同期を無効化
        // syncServiceInitializerProvider,
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: generateRoute,
      onUnknownRoute: (settings) {
        AppLogger.instance.e('不明なルートが呼ばれました: ${settings.name}');
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('エラー')),
                body: Center(child: Text('ページが見つかりません: ${settings.name}')),
              ),
        );
      },
    );
  }
}
