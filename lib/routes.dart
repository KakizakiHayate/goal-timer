import 'package:flutter/material.dart';
import 'package:goal_timer/core/utils/platform_route.dart';
import 'package:goal_timer/core/utils/route_names.dart';
import 'package:goal_timer/features/debug/sync_debug_view.dart';
import 'package:goal_timer/features/debug/sqlite_viewer.dart';
import 'package:goal_timer/features/goal_detail/presentation/screens/goal_detail_setting_screen.dart';
import 'package:goal_timer/features/goal_detail/presentation/screens/goal_detail_screen.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/timer_screen.dart';

import 'package:goal_timer/features/memo_record/presentation/screens/memo_record_screen.dart';
import 'package:goal_timer/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:goal_timer/features/settings/presentation/screens/settings_screen.dart';
import 'package:goal_timer/features/splash/presentation/screens/splash_screen.dart';
import 'package:goal_timer/features/auth/presentation/screens/login_screen_v2.dart';
import 'package:goal_timer/features/auth/presentation/screens/signup_screen_v2.dart';
import 'package:goal_timer/features/home/presentation/screens/home_screen.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

// TODO: 中規模・大規模になってきたら疎結合にすることを考える

// アプリのルーティング設定
Route<dynamic> generateRoute(RouteSettings settings) {
  AppLogger.instance.i('ルート要求: ${settings.name}, 引数: ${settings.arguments}');

  switch (settings.name) {
    case RouteNames.splash:
      // スプラッシュ画面（初期ルート）
      return platformPageRoute(builder: (context) => const SplashScreen());
    case RouteNames.home:
      // ホーム画面
      return platformPageRoute(builder: (context) => const HomeScreen());
    case RouteNames.goalDetailSetting:
      return platformPageRoute(
        builder: (context) => const GoalDetailSettingScreen(),
      );
    // 特定の目標IDを指定したタイマー画面
    case RouteNames.timerWithGoal:
      final goalId = settings.arguments as String;
      AppLogger.instance.i('目標付きタイマー画面に遷移します: goalId=$goalId');
      return platformPageRoute(
        builder: (context) => TimerScreen(goalId: goalId),
      );
    // 目標詳細画面
    case RouteNames.goalDetail:
      final goalId = settings.arguments as String;
      return platformPageRoute(
        builder: (context) => GoalDetailScreen(goalId: goalId),
      );
    // メモ記録画面
    case RouteNames.memoRecord:
      return platformPageRoute(builder: (context) => const MemoRecordScreen());
    // 特定の目標IDを指定したメモ記録画面
    case RouteNames.memoRecordWithGoal:
      final goalId = settings.arguments as String;
      return platformPageRoute(
        builder: (context) => MemoRecordScreen(goalId: goalId),
      );
    case RouteNames.statistics:
      return platformPageRoute(builder: (context) => const StatisticsScreen());
    // 設定画面
    case RouteNames.settings:
      return platformPageRoute(builder: (context) => const SettingsScreen());
    // 認証画面
    case RouteNames.login:
      return platformPageRoute(builder: (context) => const LoginScreenV2());
    case RouteNames.signup:
      return platformPageRoute(builder: (context) => const SignupScreenV2());
    // デバッグ画面
    case RouteNames.syncDebug:
      return platformPageRoute(builder: (context) => const SyncDebugView());
    // SQLiteビューア画面
    case RouteNames.sqliteViewer:
      return platformPageRoute(
        builder: (context) => const SQLiteViewerScreen(),
      );
    // 不明なルート
    default:
      AppLogger.instance.e('不明なルートが要求されました: ${settings.name}');
      return platformPageRoute(
        builder:
            (context) => Scaffold(
              body: Center(child: Text('ページが見つかりません: ${settings.name}')),
            ),
      );
  }
}
