import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../utils/app_logger.dart';
import '../utils/streak_reminder_consts.dart';

/// 通知タップ時のペイロード
class NotificationPayload {
  static const String home = 'home';
  static const String timer = 'timer';
  static const String streakReminder = 'streak_reminder';
}

/// 通知サービス
/// タイマー完了時の通知とストリークリマインダー通知を管理するサービス
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// タイマー完了通知のID
  static const int _timerCompletionNotificationId = 1;

  /// 通知タップ時のコールバック（外部から設定可能）
  void Function(String? payload)? onNotificationTap;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 通知サービスを初期化する
  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

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
    AppLogger.instance.i(
      'NotificationService: 通知がタップされました payload=${response.payload}',
    );
    onNotificationTap?.call(response.payload);
  }

  /// 通知の許可をリクエストする（iOS）
  Future<bool> requestPermission() async {
    if (!Platform.isIOS) return true;

    final result = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

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

    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: seconds));

    await _notifications.zonedSchedule(
      _timerCompletionNotificationId,
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
      _timerCompletionNotificationId,
      'タイマー完了',
      '「$goalTitle」の学習時間が終了しました',
      details,
    );

    AppLogger.instance.i('NotificationService: 即時通知を表示しました');
  }

  /// スケジュールされた通知をキャンセルする
  Future<void> cancelScheduledNotification() async {
    await _notifications.cancel(_timerCompletionNotificationId);
    AppLogger.instance.i('NotificationService: スケジュールされた通知をキャンセルしました');
  }

  /// 全ての通知をキャンセルする
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    AppLogger.instance.i('NotificationService: 全ての通知をキャンセルしました');
  }

  // ========== ストリークリマインダー通知 ==========

  /// 今日のストリークリマインダー通知をスケジュールする
  /// [streakDays] - 現在の連続学習日数
  /// [hasStudiedToday] - 今日既に学習したかどうか
  Future<void> scheduleTodayStreakReminders({
    required int streakDays,
    required bool hasStudiedToday,
  }) async {
    if (!_isInitialized) {
      AppLogger.instance.w('NotificationService: 未初期化のためリマインダーをスケジュールできません');
      return;
    }

    // 今日既に学習済みの場合は通知不要
    if (hasStudiedToday) {
      AppLogger.instance.i('NotificationService: 今日は学習済みのためリマインダーをスキップ');
      await cancelTodayStreakReminders();
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 20:00 リマインダー
    await _scheduleStreakNotificationIfNeeded(
      scheduledTime: today.add(
        const Duration(hours: StreakReminderConsts.reminderHour),
      ),
      notificationId: StreakReminderConsts.calculateNotificationId(
        StreakReminderConsts.reminderIdBase,
        today,
      ),
      title: StreakReminderConsts.reminderTitle,
      body: StreakReminderConsts.getReminderMessage(streakDays),
    );

    // 21:00 警告
    await _scheduleStreakNotificationIfNeeded(
      scheduledTime: today.add(
        const Duration(hours: StreakReminderConsts.warningHour),
      ),
      notificationId: StreakReminderConsts.calculateNotificationId(
        StreakReminderConsts.warningIdBase,
        today,
      ),
      title: StreakReminderConsts.warningTitle,
      body: StreakReminderConsts.getWarningMessage(streakDays),
    );

    // 23:00 最終警告
    await _scheduleStreakNotificationIfNeeded(
      scheduledTime: today.add(
        const Duration(hours: StreakReminderConsts.finalWarningHour),
      ),
      notificationId: StreakReminderConsts.calculateNotificationId(
        StreakReminderConsts.finalWarningIdBase,
        today,
      ),
      title: StreakReminderConsts.finalWarningTitle,
      body: StreakReminderConsts.getFinalWarningMessage(streakDays),
    );

    AppLogger.instance.i('NotificationService: 今日のストリークリマインダーをスケジュールしました');
  }

  /// 明日のストリークリマインダー通知をスケジュールする
  /// 学習完了後に呼び出す
  /// [streakDays] - 現在の連続学習日数（今日を含む）
  Future<void> scheduleTomorrowStreakReminders({
    required int streakDays,
  }) async {
    if (!_isInitialized) {
      AppLogger.instance.w('NotificationService: 未初期化のためリマインダーをスケジュールできません');
      return;
    }

    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    // 20:00 リマインダー
    await _scheduleStreakNotification(
      scheduledTime: tomorrow.add(
        const Duration(hours: StreakReminderConsts.reminderHour),
      ),
      notificationId: StreakReminderConsts.calculateNotificationId(
        StreakReminderConsts.reminderIdBase,
        tomorrow,
      ),
      title: StreakReminderConsts.reminderTitle,
      body: StreakReminderConsts.getReminderMessage(streakDays),
    );

    // 21:00 警告
    await _scheduleStreakNotification(
      scheduledTime: tomorrow.add(
        const Duration(hours: StreakReminderConsts.warningHour),
      ),
      notificationId: StreakReminderConsts.calculateNotificationId(
        StreakReminderConsts.warningIdBase,
        tomorrow,
      ),
      title: StreakReminderConsts.warningTitle,
      body: StreakReminderConsts.getWarningMessage(streakDays),
    );

    // 23:00 最終警告
    await _scheduleStreakNotification(
      scheduledTime: tomorrow.add(
        const Duration(hours: StreakReminderConsts.finalWarningHour),
      ),
      notificationId: StreakReminderConsts.calculateNotificationId(
        StreakReminderConsts.finalWarningIdBase,
        tomorrow,
      ),
      title: StreakReminderConsts.finalWarningTitle,
      body: StreakReminderConsts.getFinalWarningMessage(streakDays),
    );

    AppLogger.instance.i('NotificationService: 明日のストリークリマインダーをスケジュールしました');
  }

  /// 今日のストリークリマインダー通知をキャンセルする
  Future<void> cancelTodayStreakReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _notifications.cancel(
      StreakReminderConsts.calculateNotificationId(
        StreakReminderConsts.reminderIdBase,
        today,
      ),
    );
    await _notifications.cancel(
      StreakReminderConsts.calculateNotificationId(
        StreakReminderConsts.warningIdBase,
        today,
      ),
    );
    await _notifications.cancel(
      StreakReminderConsts.calculateNotificationId(
        StreakReminderConsts.finalWarningIdBase,
        today,
      ),
    );

    AppLogger.instance.i('NotificationService: 今日のストリークリマインダーをキャンセルしました');
  }

  /// 全てのストリークリマインダー通知をキャンセルする
  Future<void> cancelAllStreakReminders() async {
    // 今日と明日のリマインダーをキャンセル
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (final date in [today, tomorrow]) {
      await _notifications.cancel(
        StreakReminderConsts.calculateNotificationId(
          StreakReminderConsts.reminderIdBase,
          date,
        ),
      );
      await _notifications.cancel(
        StreakReminderConsts.calculateNotificationId(
          StreakReminderConsts.warningIdBase,
          date,
        ),
      );
      await _notifications.cancel(
        StreakReminderConsts.calculateNotificationId(
          StreakReminderConsts.finalWarningIdBase,
          date,
        ),
      );
    }

    AppLogger.instance.i('NotificationService: 全てのストリークリマインダーをキャンセルしました');
  }

  /// ストリーク通知をスケジュールする（現在時刻より未来の場合のみ）
  Future<void> _scheduleStreakNotificationIfNeeded({
    required DateTime scheduledTime,
    required int notificationId,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      final formattedTime =
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
      AppLogger.instance.i(
        'NotificationService: 過去の時刻のためスキップ (id=$notificationId, 予定時刻=$formattedTime)',
      );
      return;
    }
    await _scheduleStreakNotification(
      scheduledTime: scheduledTime,
      notificationId: notificationId,
      title: title,
      body: body,
    );
  }

  /// ストリーク通知をスケジュールする
  Future<void> _scheduleStreakNotification({
    required DateTime scheduledTime,
    required int notificationId,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      StreakReminderConsts.channelId,
      StreakReminderConsts.channelName,
      channelDescription: StreakReminderConsts.channelDescription,
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

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: NotificationPayload.streakReminder,
    );

    // スケジュール時刻を見やすくフォーマット
    final formattedTime =
        '${scheduledTime.year}/${scheduledTime.month}/${scheduledTime.day} '
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

    AppLogger.instance.i(
      'NotificationService: ストリーク通知をスケジュール\n'
      '  - ID: $notificationId\n'
      '  - 時刻: $formattedTime\n'
      '  - タイトル: $title\n'
      '  - 本文: $body',
    );
  }
}
