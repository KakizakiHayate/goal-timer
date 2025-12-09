import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/home/view/home_screen.dart';
import 'features/settings/view_model/settings_view_model.dart';
import 'core/utils/color_consts.dart';
import 'core/data/local/app_database.dart';
import 'core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Goal Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorConsts.primary),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
