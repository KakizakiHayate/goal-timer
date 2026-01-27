import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../models/goals/goals_model.dart';
import '../models/study_daily_logs/study_daily_logs_model.dart';
import '../models/users/users_model.dart';
import '../utils/app_logger.dart';

/// Crashlytics送信サービス
/// データ保存/削除失敗時にCrashlyticsへエラーとデータを送信する
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  /// デバッグモードかどうか（デバッグモードでは送信をスキップ）
  bool get _shouldSend => !kDebugMode;

  /// 目標データの保存失敗を記録
  ///
  /// [goal] 保存に失敗した目標データ
  /// [error] 発生したエラー
  /// [stackTrace] スタックトレース
  Future<void> sendFailedGoalData(
    GoalsModel goal,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (!_shouldSend) {
      AppLogger.instance.d('Crashlytics: デバッグモードのため送信をスキップ（Goal保存失敗）');
      return;
    }

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Goal save failed',
        information: [
          'goalId: ${goal.id}',
          'title: ${goal.title}',
          'userId: ${goal.userId}',
          'goalData: ${jsonEncode(goal.toJson())}',
        ],
      );
      AppLogger.instance.i('Crashlytics: 目標保存失敗データを送信しました');
    } catch (e, st) {
      AppLogger.instance.e('Crashlytics: 送信に失敗しました', e, st);
    }
  }

  /// 目標削除の失敗を記録
  ///
  /// [goalId] 削除に失敗した目標ID
  /// [error] 発生したエラー
  /// [stackTrace] スタックトレース
  Future<void> sendFailedGoalDelete(
    String goalId,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (!_shouldSend) {
      AppLogger.instance.d('Crashlytics: デバッグモードのため送信をスキップ（Goal削除失敗）');
      return;
    }

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Goal delete failed',
        information: ['goalId: $goalId'],
      );
      AppLogger.instance.i('Crashlytics: 目標削除失敗データを送信しました');
    } catch (e, st) {
      AppLogger.instance.e('Crashlytics: 送信に失敗しました', e, st);
    }
  }

  /// 学習ログの保存失敗を記録
  ///
  /// [log] 保存に失敗した学習ログデータ
  /// [error] 発生したエラー
  /// [stackTrace] スタックトレース
  Future<void> sendFailedStudyLogData(
    StudyDailyLogsModel log,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (!_shouldSend) {
      AppLogger.instance.d('Crashlytics: デバッグモードのため送信をスキップ（StudyLog保存失敗）');
      return;
    }

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Study log save failed',
        information: [
          'logId: ${log.id}',
          'goalId: ${log.goalId}',
          'studyDate: ${log.studyDate.toIso8601String()}',
          'totalSeconds: ${log.totalSeconds}',
          'userId: ${log.userId}',
          'logData: ${jsonEncode(log.toJson())}',
        ],
      );
      AppLogger.instance.i('Crashlytics: 学習ログ保存失敗データを送信しました');
    } catch (e, st) {
      AppLogger.instance.e('Crashlytics: 送信に失敗しました', e, st);
    }
  }

  /// ユーザーデータの保存失敗を記録
  ///
  /// [user] 保存に失敗したユーザーデータ
  /// [error] 発生したエラー
  /// [stackTrace] スタックトレース
  Future<void> sendFailedUserData(
    UsersModel user,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (!_shouldSend) {
      AppLogger.instance.d('Crashlytics: デバッグモードのため送信をスキップ（User保存失敗）');
      return;
    }

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'User save failed',
        information: [
          'userId: ${user.id}',
          'displayName: ${user.displayName}',
          'userData: ${jsonEncode(user.toJson())}',
        ],
      );
      AppLogger.instance.i('Crashlytics: ユーザー保存失敗データを送信しました');
    } catch (e, st) {
      AppLogger.instance.e('Crashlytics: 送信に失敗しました', e, st);
    }
  }

  /// displayName更新の失敗を記録
  ///
  /// [userId] ユーザーID
  /// [displayName] 更新しようとしたdisplayName
  /// [error] 発生したエラー
  /// [stackTrace] スタックトレース
  Future<void> sendFailedDisplayNameUpdate(
    String userId,
    String displayName,
    Object error,
    StackTrace stackTrace,
  ) async {
    if (!_shouldSend) {
      AppLogger.instance.d('Crashlytics: デバッグモードのため送信をスキップ（displayName更新失敗）');
      return;
    }

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'DisplayName update failed',
        information: [
          'userId: $userId',
          'displayName: $displayName',
        ],
      );
      AppLogger.instance.i('Crashlytics: displayName更新失敗データを送信しました');
    } catch (e, st) {
      AppLogger.instance.e('Crashlytics: 送信に失敗しました', e, st);
    }
  }
}
