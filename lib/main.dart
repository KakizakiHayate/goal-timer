import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uuid/uuid.dart';

import 'core/data/local/app_database.dart';
import 'core/data/supabase/supabase_user_devices_datasource.dart';
import 'core/models/user_devices/user_devices_model.dart';
import 'core/services/fcm_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/color_consts.dart';
import 'features/settings/view_model/settings_view_model.dart';
import 'features/splash/view/splash_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数を読み込み
  await dotenv.load(fileName: '.env');

  // Firebaseを初期化（Analytics & Crashlytics）
  try {
    await FirebaseService().init();
  } catch (error, stackTrace) {
    AppLogger.instance.e('Firebase初期化に失敗しました', error, stackTrace);
  }

  // Supabaseを初期化
  await _initializeSupabase();

  // DIコンテナに登録（シングルトンとして）
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

  // FCMサービスを初期化（プッシュ通知の許可リクエスト・トークン更新監視）
  try {
    await FcmService().init();
  } catch (error, stackTrace) {
    AppLogger.instance.e('FcmService初期化に失敗しました', error, stackTrace);
  }

  // 起動時に既ログインの場合はFCMトークンをuser_devicesに登録
  // 既存ユーザーがアプリ更新後の初回起動でも user_devices にレコードが
  // 作成されるよう、ログイン状態を確認して登録する。
  await _registerCurrentDeviceIfLoggedIn();

  runApp(const MyApp());
}

/// 起動時に既ログインなら現在のFCMトークンを user_devices に登録する
///
/// 失敗してもアプリ起動は継続する。
Future<void> _registerCurrentDeviceIfLoggedIn() async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.instance.i('起動時: 未ログインのためデバイス登録をスキップ');
      return;
    }

    final fcmService = FcmService();
    final fcmToken = await fcmService.getToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      AppLogger.instance.w('起動時: FCMトークンが取得できないためデバイス登録をスキップ');
      return;
    }

    final deviceName = await fcmService.getDeviceName();

    final datasource = SupabaseUserDevicesDatasource(
      supabase: Supabase.instance.client,
    );
    await datasource.upsertDevice(
      UserDevicesModel(
        id: const Uuid().v4(),
        userId: userId,
        fcmToken: fcmToken,
        platform: fcmService.currentPlatform,
        deviceName: deviceName,
      ),
    );
    AppLogger.instance.i('起動時: デバイス登録が完了しました');
  } catch (error, stackTrace) {
    AppLogger.instance.e('起動時のデバイス登録に失敗しました', error, stackTrace);
  }
}

/// Supabaseを初期化
Future<void> _initializeSupabase() async {
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Supabase環境変数が設定されていません');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    AppLogger.instance.i('Supabase初期化完了');
  } catch (error, stackTrace) {
    AppLogger.instance.e('Supabase初期化に失敗しました', error, stackTrace);
    rethrow;
  }
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
      // 国際化設定
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        // 日本語の場合は日本語、それ以外は英語にフォールバック
        if (locale?.languageCode == 'ja') {
          return const Locale('ja');
        }
        return const Locale('en');
      },
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
