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

  // イベント名の定数
  static const String _eventMigrationCompleted = 'migration_completed';
  static const String _eventMigrationFailed = 'migration_failed';
  static const String _eventMigrationSkipped = 'migration_skipped';

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

  /// マイグレーション完了イベントを送信
  ///
  /// [userId] SupabaseユーザーID
  /// [goalCount] 移行した目標の件数
  /// [studyLogCount] 移行した学習ログの件数
  Future<void> logMigrationCompleted({
    required String userId,
    required int goalCount,
    required int studyLogCount,
  }) =>
      _logEvent(
        _eventMigrationCompleted,
        {
          'user_id': userId,
          'goal_count': goalCount,
          'study_log_count': studyLogCount,
        },
      );

  /// マイグレーション失敗イベントを送信
  ///
  /// [userId] SupabaseユーザーID
  /// [errorMessage] エラーメッセージ
  Future<void> logMigrationFailed({
    required String userId,
    required String errorMessage,
  }) =>
      _logEvent(
        _eventMigrationFailed,
        {
          'user_id': userId,
          'error_message': errorMessage,
        },
      );

  /// マイグレーションスキップイベントを送信
  ///
  /// [userId] SupabaseユーザーID
  /// [reason] スキップ理由
  Future<void> logMigrationSkipped({
    required String userId,
    required String reason,
  }) =>
      _logEvent(
        _eventMigrationSkipped,
        {
          'user_id': userId,
          'reason': reason,
        },
      );

  /// イベント送信の共通処理
  Future<void> _logEvent(
    String name,
    Map<String, Object>? parameters,
  ) async {
    try {
      await _analytics?.logEvent(name: name, parameters: parameters);
      AppLogger.instance.i('FirebaseService: イベント「$name」を送信しました');
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'FirebaseService: イベント「$name」の送信に失敗しました',
        error,
        stackTrace,
      );
    }
  }
}
