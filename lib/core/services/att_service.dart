import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../utils/app_logger.dart';

/// App Tracking Transparency (ATT) サービス
/// iOS 14.5以降でトラッキング許可ダイアログを表示するためのサービス
class AttService {
  /// ATTダイアログを表示し、ユーザーの許可状態を取得する
  /// iOSのみで動作し、Android等では何もしない
  Future<TrackingStatus> requestTrackingAuthorization() async {
    // iOSでない場合は何もしない
    if (!Platform.isIOS) {
      AppLogger.instance.i('ATT: iOS以外のプラットフォームのためスキップ');
      return TrackingStatus.notSupported;
    }

    try {
      // 現在のトラッキング許可状態を取得
      final currentStatus =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      AppLogger.instance.i('ATT: 現在の許可状態: $currentStatus');

      // まだ決定されていない場合のみダイアログを表示
      if (currentStatus == TrackingStatus.notDetermined) {
        // ATTダイアログを表示
        final status =
            await AppTrackingTransparency.requestTrackingAuthorization();
        AppLogger.instance.i('ATT: ユーザーの選択: $status');
        return status;
      }

      return currentStatus;
    } catch (error, stackTrace) {
      AppLogger.instance.e('ATT: 許可リクエストに失敗しました', error, stackTrace);
      return TrackingStatus.notSupported;
    }
  }

  /// 現在のトラッキング許可状態を取得する
  Future<TrackingStatus> getTrackingStatus() async {
    if (!Platform.isIOS) {
      return TrackingStatus.notSupported;
    }

    try {
      return await AppTrackingTransparency.trackingAuthorizationStatus;
    } catch (error, stackTrace) {
      AppLogger.instance.e('ATT: 許可状態の取得に失敗しました', error, stackTrace);
      return TrackingStatus.notSupported;
    }
  }

  /// トラッキングが許可されているかどうかを確認する
  Future<bool> isTrackingAuthorized() async {
    final status = await getTrackingStatus();
    return status == TrackingStatus.authorized;
  }
}
