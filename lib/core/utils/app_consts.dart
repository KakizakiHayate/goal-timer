/// アプリケーション全体で使用する定数
class AppConsts {
  AppConsts._();

  // === 外部リンク ===
  /// プライバシーポリシーURL
  static const String privacyPolicyUrl =
      'https://docs.google.com/document/d/1xagtbSDKcWep7K_FUii8l2LTCZL_BUXbCRm4hxxNCww/edit?usp=sharing';

  /// 不具合報告フォームURL
  static const String bugReportFormUrl =
      'https://forms.gle/KF3eSCycwH8vdDZf7';

  /// 機能追加要望フォームURL
  static const String featureRequestFormUrl =
      'https://forms.gle/xeyy1G26AEKPxEuW8';

  // === アプリ情報 ===
  /// アプリ名
  static const String appName = '目標達成タイマー';

  // === フィードバック設定 ===
  /// フィードバックポップアップの表示間隔（学習完了回数）
  static const int feedbackPopupInterval = 3;

  /// フィードバックポップアップの非表示期間（日数）
  static const int feedbackPopupCooldownDays = 7;

  /// フィードバックポップアップ対象の最低学習時間（秒）
  /// 1分以上の学習でカウント対象
  static const int minStudySecondsForFeedback = 60;
}
