import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io'
    if (dart.library.html) 'package:goal_timer/core/utils/platform_stub.dart';

Route<dynamic> platformPageRoute({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  if (kIsWeb) {
    return MaterialPageRoute(builder: builder, settings: settings);
  } else if (Platform.isIOS) {
    return CupertinoPageRoute(builder: builder, settings: settings);
  } else {
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
