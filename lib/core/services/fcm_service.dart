import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/app_logger.dart';

/// FCM（Firebase Cloud Messaging）を管理するサービス
///
/// 役割:
/// - 通知許可リクエスト
/// - FCMトークンの取得
/// - トークン更新（onTokenRefresh）の購読
/// - トークン削除
///
/// 設計方針:
/// - このサービスはFirebase関連の処理のみを担当する
/// - Supabaseへのトークン保存はAuthViewModelなどの呼び出し側で行う
/// - onTokenRefreshのコールバックは [setOnTokenRefresh] で外部から注入する
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<void> Function(String token)? _onTokenRefreshCallback;

  bool _isInitialized = false;

  /// 初期化
  ///
  /// 通知許可リクエストとトークン更新監視を開始する。
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await requestPermission();

      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
        (newToken) async {
          AppLogger.instance.i('FCMトークンが更新されました');
          final callback = _onTokenRefreshCallback;
          if (callback != null) {
            try {
              await callback(newToken);
            } catch (error, stackTrace) {
              AppLogger.instance.e(
                'FCMトークン更新コールバックでエラーが発生しました',
                error,
                stackTrace,
              );
            }
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          AppLogger.instance.e(
            'FCMトークン更新ストリームでエラーが発生しました',
            error,
            stackTrace,
          );
        },
      );

      _isInitialized = true;
      AppLogger.instance.i('FcmService初期化が完了しました');
    } catch (error, stackTrace) {
      AppLogger.instance.e('FcmService初期化に失敗しました', error, stackTrace);
    }
  }

  /// トークン更新時のコールバックを設定
  ///
  /// AuthViewModelなどから呼び出して、トークン更新時にSupabaseへ
  /// 反映する処理を注入する。
  void setOnTokenRefresh(Future<void> Function(String token)? callback) {
    _onTokenRefreshCallback = callback;
  }

  /// 通知許可をリクエスト
  Future<NotificationSettings> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      AppLogger.instance.i(
        '通知許可ステータス: ${settings.authorizationStatus}',
      );
      return settings;
    } catch (error, stackTrace) {
      AppLogger.instance.e('通知許可リクエストに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 現在のFCMトークンを取得
  ///
  /// iOSシミュレータではAPNsトークンが取得できないため、nullが返る場合がある。
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        AppLogger.instance.w('FCMトークンが取得できませんでした');
      } else {
        AppLogger.instance.i('FCMトークンを取得しました');
      }
      return token;
    } catch (error, stackTrace) {
      AppLogger.instance.e('FCMトークン取得に失敗しました', error, stackTrace);
      return null;
    }
  }

  /// 現在のFCMトークンを無効化
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      AppLogger.instance.i('FCMトークンを削除しました');
    } catch (error, stackTrace) {
      AppLogger.instance.e('FCMトークン削除に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 現在のプラットフォーム名を返す
  ///
  /// 'ios' または 'android' を返す。
  String get currentPlatform => Platform.isIOS ? 'ios' : 'android';

  /// 端末名を取得
  ///
  /// 取得失敗時はnullを返す。
  Future<String?> getDeviceName() async {
    try {
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name;
      }
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.model;
      }
      return null;
    } catch (error, stackTrace) {
      AppLogger.instance.e('端末名取得に失敗しました', error, stackTrace);
      return null;
    }
  }

  /// 後始末
  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _onTokenRefreshCallback = null;
    _isInitialized = false;
  }
}
