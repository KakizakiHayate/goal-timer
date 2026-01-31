import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_logger.dart';
import 'color_consts.dart';

/// URL起動に関するユーティリティクラス
class UrlLauncherUtils {
  UrlLauncherUtils._();

  /// 内部ブラウザ（アプリ内WebView）でURLを開く
  ///
  /// [context] BuildContext（SnackBar表示用）
  /// [url] 開くURL
  /// [showErrorSnackBar] エラー時にSnackBarを表示するか（デフォルト: true）
  static Future<void> openInAppWebView(
    BuildContext context,
    String url, {
    bool showErrorSnackBar = true,
  }) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } else {
      AppLogger.instance.e('URLを開けませんでした: $url');
      if (showErrorSnackBar && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URLを開けませんでした'),
            backgroundColor: ColorConsts.error,
          ),
        );
      }
    }
  }
}
