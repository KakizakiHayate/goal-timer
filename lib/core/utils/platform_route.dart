import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Route<dynamic> platformPageRoute({
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  if (Platform.isIOS) {
    return CupertinoPageRoute(builder: builder, settings: settings);
  } else {
    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
