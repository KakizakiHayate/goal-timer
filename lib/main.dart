import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/data/local/app_database.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/color_consts.dart';
import 'features/home/view/home_screen.dart';
import 'features/settings/view_model/settings_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseを初期化（Analytics & Crashlytics）
  try {
    await FirebaseService().init();
  } catch (error, stackTrace) {
    AppLogger.instance.e('Firebase初期化に失敗しました', error, stackTrace);
  }

  // ✅ DIコンテナに登録（シングルトンとして）
  Get.put<AppDatabase>(AppDatabase(), permanent: true);

  // 設定ViewModelを登録・初期化
  final settingsViewModel = Get.put(SettingsViewModel(), permanent: true);
  await settingsViewModel.init();

  // データベースを初期化（テーブル作成が実行される）
  try {
    AppLogger.instance.i('データベース初期化を開始します');
    await Get.find<AppDatabase>().database;
    AppLogger.instance.i('データベース初期化が完了しました');
  } catch (error, stackTrace) {
    AppLogger.instance.e('データベース初期化に失敗しました', error, stackTrace);
    // エラーが発生してもアプリは起動する（データベースを使わない機能は動作可能）
  }

  // 通知サービスを初期化
  try {
    await NotificationService().init();
    AppLogger.instance.i('通知サービス初期化が完了しました');
  } catch (error, stackTrace) {
    AppLogger.instance.e('通知サービス初期化に失敗しました', error, stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '目標達成タイマー',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorConsts.primary),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
