import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/config/env_config.dart';
import 'package:goal_timer/core/utils/app_logger.dart';
import 'package:goal_timer/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:goal_timer/routes.dart';
import 'package:goal_timer/core/utils/route_names.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/timer_screen.dart';
import 'package:goal_timer/features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  AppLogger.instance.i('環境変数: SUPABASE_URL = ${EnvConfig.supabaseUrl}');
  AppLogger.instance.i('環境変数: APP_ENV = ${EnvConfig.appEnv}');
  AppLogger.instance.i('環境変数: DEBUG_MODE = ${EnvConfig.isDebugMode}');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MyApp()));
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
      home: const SplashScreen(),
      routes: {
        RouteNames.timer: (context) => const TimerScreen(),
        // その他の引数不要なルートをここに追加
      },
      onGenerateRoute: generateRoute,
      initialRoute: null,
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
