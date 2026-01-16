import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../utils/app_logger.dart';

/// Firebaseサービス
/// Firebase Analytics と Crashlytics を管理するサービス
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAnalytics? _analytics;

  /// Firebase Analyticsインスタンスを取得する
  FirebaseAnalytics? get analytics => _analytics;

  bool _isInitialized = false;

  /// Firebaseサービスを初期化する
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Firebase初期化
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.instance.i('FirebaseService: Firebase初期化が完了しました');

      // Analytics初期化
      _analytics = FirebaseAnalytics.instance;
      AppLogger.instance.i('FirebaseService: Analytics初期化が完了しました');

      // Crashlytics設定
      if (kDebugMode) {
        // デバッグモードではCrashlyticsを無効化
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false);
        AppLogger.instance
            .i('FirebaseService: Crashlyticsはデバッグモードのため無効化されています');
      } else {
        // リリースモードではFlutterエラーをCrashlyticsに送信
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        AppLogger.instance.i('FirebaseService: Crashlytics初期化が完了しました');
      }

      _isInitialized = true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('FirebaseService: 初期化に失敗しました', error, stackTrace);
      rethrow;
    }
  }
}
