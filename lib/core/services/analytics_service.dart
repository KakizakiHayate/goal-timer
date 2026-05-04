import 'package:firebase_analytics/firebase_analytics.dart';

import '../utils/analytics_events.dart';
import '../utils/app_logger.dart';
import 'firebase_service.dart';

/// GA4 へのイベント送信を集約するラッパー。
///
/// 設計方針:
/// - 文字列イベント名・パラメータ名を呼び出し側に書かせない（型付きメソッドのみ公開）
/// - 同一 `screen_name` への連続送信は内部でガードする
/// - ユーザープロパティのバケット化はこの中で行う（呼び出し側は生数値を渡すだけ）
/// - 既存サービスと同じシングルトンパターン（`Get.put` 不使用）
/// - 既存 `FirebaseService._logEvent` のように `kDebugMode` で送信をスキップしない。
///   Firebase DebugView での実機検証を行うため、デバッグビルドでもイベントを送る。
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static AnalyticsService get instance => _instance;

  String? _lastLoggedScreenName;

  FirebaseAnalytics? get _analytics => FirebaseService().analytics;

  // ---------- 画面遷移 ----------

  /// 画面遷移を計測する。
  ///
  /// `routingCallback` から呼び出す。直前と同じ `screen_name` の場合はスキップ
  /// （GetX の routingCallback は同一ルートでも発火することがあるため）。
  Future<void> logScreenView(String screenName) async {
    if (screenName == _lastLoggedScreenName) {
      return;
    }
    _lastLoggedScreenName = screenName;
    await _analytics?.logScreenView(screenName: screenName);
    AppLogger.instance.d('AnalyticsService: screen_view $screenName');
  }

  // ---------- タイマー ----------

  Future<void> logTimerStart({
    required String goalId,
    required int targetMinutes,
  }) =>
      _logEvent(AnalyticsEvent.timerStart, {
        'goal_id': goalId,
        'target_minutes': targetMinutes,
      });

  Future<void> logTimerPause({
    required String goalId,
    required int elapsedSeconds,
  }) =>
      _logEvent(AnalyticsEvent.timerPause, {
        'goal_id': goalId,
        'elapsed_seconds': elapsedSeconds,
      });

  Future<void> logTimerResume({required String goalId}) =>
      _logEvent(AnalyticsEvent.timerResume, {'goal_id': goalId});

  Future<void> logTimerCancel({
    required String goalId,
    required int elapsedSeconds,
    required int targetMinutes,
  }) =>
      _logEvent(AnalyticsEvent.timerCancel, {
        'goal_id': goalId,
        'elapsed_seconds': elapsedSeconds,
        'target_minutes': targetMinutes,
      });

  Future<void> logTimerComplete({
    required String goalId,
    required int targetMinutes,
  }) =>
      _logEvent(AnalyticsEvent.timerComplete, {
        'goal_id': goalId,
        'target_minutes': targetMinutes,
      });

  // ---------- 目標管理 ----------

  Future<void> logGoalCreate({required int targetMinutes}) =>
      _logEvent(AnalyticsEvent.goalCreate, {'target_minutes': targetMinutes});

  Future<void> logGoalEdit({required String goalId}) =>
      _logEvent(AnalyticsEvent.goalEdit, {'goal_id': goalId});

  Future<void> logGoalDelete({required String goalId}) =>
      _logEvent(AnalyticsEvent.goalDelete, {'goal_id': goalId});

  // ---------- レビュー誘導 ----------

  /// `trigger_reason` の値: 学習セッション完了が5の倍数に達した時。
  static const String _triggerTimerCompleteMilestone =
      'timer_complete_milestone';

  Future<void> logReviewPromptEligible({required int completionCount}) =>
      _logEvent(AnalyticsEvent.reviewPromptEligible, {
        'trigger_reason': _triggerTimerCompleteMilestone,
        'completion_count': completionCount,
      });

  Future<void> logReviewPromptShown({required int completionCount}) =>
      _logEvent(AnalyticsEvent.reviewPromptShown, {
        'trigger_reason': _triggerTimerCompleteMilestone,
        'completion_count': completionCount,
      });

  // ---------- ユーザープロパティ ----------

  Future<void> setTotalTimerComplete(int rawCount) =>
      _setUserProperty('total_timer_complete', _bucketize(rawCount));

  Future<void> setTotalGoalCount(int rawCount) =>
      _setUserProperty('total_goal_count', _bucketize(rawCount));

  /// 0 / 1-3 / 4-10 / 11-30 / 31+ のバケット文字列を返す。
  ///
  /// public にしているのはユニットテストから境界値を検証するため。
  /// 通常は `setTotalTimerComplete` / `setTotalGoalCount` 経由で使う。
  static String bucketize(int rawCount) => _bucketize(rawCount);

  static String _bucketize(int rawCount) {
    if (rawCount <= 0) return '0';
    if (rawCount <= 3) return '1-3';
    if (rawCount <= 10) return '4-10';
    if (rawCount <= 30) return '11-30';
    return '31+';
  }

  // ---------- 内部ヘルパー ----------

  Future<void> _logEvent(
    AnalyticsEvent event,
    Map<String, Object> parameters,
  ) async {
    final analytics = _analytics;
    if (analytics == null) {
      AppLogger.instance.w(
        'AnalyticsService: analytics 未初期化のため ${event.eventName} をスキップ',
      );
      return;
    }
    try {
      await analytics.logEvent(name: event.eventName, parameters: parameters);
      AppLogger.instance.d('AnalyticsService: ${event.eventName} 送信');
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'AnalyticsService: ${event.eventName} 送信に失敗',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _setUserProperty(String name, String value) async {
    final analytics = _analytics;
    if (analytics == null) {
      AppLogger.instance.w(
        'AnalyticsService: analytics 未初期化のためユーザープロパティ $name をスキップ',
      );
      return;
    }
    try {
      await analytics.setUserProperty(name: name, value: value);
      AppLogger.instance.d('AnalyticsService: setUserProperty $name=$value');
    } catch (error, stackTrace) {
      AppLogger.instance.e(
        'AnalyticsService: setUserProperty $name に失敗',
        error,
        stackTrace,
      );
    }
  }
}
