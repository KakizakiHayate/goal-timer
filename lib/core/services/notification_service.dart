import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../utils/app_logger.dart';

/// 通知サービス
/// タイマー完了時の通知を管理するサービス
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 通知サービスを初期化する
  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    AppLogger.instance.i('NotificationService: 初期化完了');
  }

  /// 通知がタップされた時のコールバック
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.instance.i('NotificationService: 通知がタップされました');
  }

  /// 通知の許可をリクエストする（iOS）
  Future<bool> requestPermission() async {
    if (!Platform.isIOS) return true;

    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    AppLogger.instance.i('NotificationService: 許可リクエスト結果: $result');
    return result ?? false;
  }

  /// タイマー完了通知をスケジュールする
  /// [seconds] 秒後に通知を表示する
  Future<void> scheduleTimerCompletionNotification({
    required int seconds,
    required String goalTitle,
  }) async {
    if (!_isInitialized) {
      AppLogger.instance.w('NotificationService: 未初期化のため通知をスケジュールできません');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'timer_completion',
      'タイマー完了',
      channelDescription: 'タイマーが完了した時の通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledTime = tz.TZDateTime.now(tz.local).add(
      Duration(seconds: seconds),
    );

    await _notifications.zonedSchedule(
      0,
      'タイマー完了',
      '「$goalTitle」の学習時間が終了しました',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );

    AppLogger.instance.i('NotificationService: 通知をスケジュールしました（$seconds秒後）');
  }

  /// 即時通知を表示する（バックグラウンドで完了した場合）
  Future<void> showTimerCompletionNotification({
    required String goalTitle,
  }) async {
    if (!_isInitialized) {
      AppLogger.instance.w('NotificationService: 未初期化のため通知を表示できません');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'timer_completion',
      'タイマー完了',
      channelDescription: 'タイマーが完了した時の通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'タイマー完了',
      '「$goalTitle」の学習時間が終了しました',
      details,
    );

    AppLogger.instance.i('NotificationService: 即時通知を表示しました');
  }

  /// スケジュールされた通知をキャンセルする
  Future<void> cancelScheduledNotification() async {
    await _notifications.cancel(0);
    AppLogger.instance.i('NotificationService: スケジュールされた通知をキャンセルしました');
  }

  /// 全ての通知をキャンセルする
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    AppLogger.instance.i('NotificationService: 全ての通知をキャンセルしました');
  }
}
