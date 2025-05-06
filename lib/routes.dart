import 'package:flutter/material.dart';
import 'package:goal_timer/core/utils/platform_route.dart';
import 'package:goal_timer/core/utils/route_names.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/screens/goal_detail_setting_screen.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/screens/goal_detail_screen.dart';
import 'package:goal_timer/features/goal_timer/presentation/screens/timer_screen.dart';
import 'package:goal_timer/features/home/presentation/screens/home_screen.dart';

// TODO: 中規模・大規模になってきたら疎結合にすることを考える

// アプリのルーティング設定
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case RouteNames.home:
      return platformPageRoute(builder: (context) => const HomeScreen());
    case RouteNames.goalDetailSetting:
      return platformPageRoute(
        builder: (context) => const GoalDetailSettingScreen(),
      );
    case RouteNames.timer:
      return platformPageRoute(builder: (context) => const TimerScreen());
    // 目標詳細画面
    case RouteNames.goalDetail:
      final goalId = settings.arguments as String;
      return platformPageRoute(
        builder: (context) => GoalDetailScreen(goalId: goalId),
      );
    // 不明なルート
    default:
      return platformPageRoute(
        builder:
            (context) =>
                const Scaffold(body: Center(child: Text('ページが見つかりません'))),
      );
  }
}
