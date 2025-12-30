// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:goal_timer/backup/core/config/env_config.dart';
// import 'package:goal_timer/backup/core/utils/app_logger.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:goal_timer/backup/routes.dart';
// // import 'package:goal_timer/core/services/sync_service.dart'; // 削除: 定期同期サービス無効化
// import 'package:goal_timer/backup/core/data/local/database/app_database.dart';
// import 'package:purchases_flutter/purchases_flutter.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await dotenv.load(fileName: '.env');

//   // 環境変数のログ出力
//   AppLogger.instance.i('環境変数: SUPABASE_URL = ${EnvConfig.supabaseUrl}');
//   AppLogger.instance.i('環境変数: APP_ENV = ${EnvConfig.appEnv}');
//   AppLogger.instance.i('環境変数: DEBUG_MODE = ${EnvConfig.isDebugMode}');

//   // データベースの初期化
//   await AppDatabase.instance.initialize();

//   // AppDatabaseクラスがパス情報を既に表示しているので、ここでの出力は不要
//   // データベースパスのみシンプルに標準出力に表示
//   final dbPath = AppDatabase.databasePath;
//   AppLogger.instance.i('SQLiteデータベースパス: $dbPath');

//   // Supabaseの初期化はSplashScreenとprovidersで行うため、ここでは行わない

//   // RevenueCat初期化
//   try {
//     await Purchases.setLogLevel(LogLevel.debug);

//     // Platform別のキー設定
//     String apiKey = '';
//     if (Platform.isIOS) {
//       apiKey = EnvConfig.revenueCatApplePublicApiKey;
//     } else if (Platform.isAndroid) {
//       apiKey = 'your_android_public_sdk_key_here'; // Android用 Public SDK Key
//     }

//     if (apiKey.isNotEmpty && !apiKey.contains('your_')) {
//       final configuration = PurchasesConfiguration(apiKey);
//       await Purchases.configure(configuration);
//       AppLogger.instance.i(
//         'RevenueCat initialized successfully for ${Platform.operatingSystem}',
//       );
//     } else {
//       AppLogger.instance.w(
//         'RevenueCat API key not configured for ${Platform.operatingSystem}',
//       );
//     }
//   } catch (e) {
//     AppLogger.instance.w('RevenueCat initialization failed: $e');
//     // ビルドエラーを避けるため、エラーは無視して継続
//   }

//   // アプリ起動ログ
//   AppLogger.instance.i('アプリケーションを起動します');

//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   runApp(
//     ProviderScope(
//       overrides: [
//         // 同期サービスの初期化を削除: 定期同期を無効化
//         // syncServiceInitializerProvider,
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       // ローカライゼーション設定
//       localizationsDelegates: const [
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       supportedLocales: const [
//         Locale('ja', 'JP'),
//         Locale('en', 'US'),
//       ],
//       locale: const Locale('ja', 'JP'),

//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
//         useMaterial3: true,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/',
//       onGenerateRoute: generateRoute,
//       onUnknownRoute: (settings) {
//         AppLogger.instance.e('不明なルートが呼ばれました: ${settings.name}');
//         return MaterialPageRoute(
//           builder:
//               (context) => Scaffold(
//                 appBar: AppBar(title: const Text('エラー')),
//                 body: Center(child: Text('ページが見つかりません: ${settings.name}')),
//               ),
//         );
//       },
//     );
//   }
// }
