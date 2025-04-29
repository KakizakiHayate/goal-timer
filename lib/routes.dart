import 'package:flutter/material.dart';
import 'package:goal_timer/core/utils/platform_route.dart';
import 'package:goal_timer/features/home/presentation/screens/home_screen.dart';
import 'package:goal_timer/features/goal_detail_setting/presentation/screens/goal_detail_setting_screen.dart';
// TODO: 中規模・大規模になってきたら疎結合にすることを考える

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return platformPageRoute(builder: (context) => const HomeScreen());
    case '/goal_detail_setting':
      return platformPageRoute(builder: (context) => const GoalDetailSettingScreen());
    default:
      return platformPageRoute(
        builder: (context) => const Scaffold(
          body: Center(
            child: Text('ページが見つかりません'),
          ),
        ),
      );
  }
}
