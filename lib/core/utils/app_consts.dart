/// アプリケーション全体で使用する定数
class AppConsts {
  AppConsts._();

  // === 外部リンク ===
  /// プライバシーポリシーURL
  static const String privacyPolicyUrl =
      'https://docs.google.com/document/d/1xagtbSDKcWep7K_FUii8l2LTCZL_BUXbCRm4hxxNCww/edit?usp=sharing';

  /// 不具合報告フォームURL
  /// TODO: 実際のGoogleフォームURLに差し替えてください
  static const String bugReportFormUrl = 'https://forms.gle/PLACEHOLDER_BUG';

  /// 機能追加要望フォームURL
  /// TODO: 実際のGoogleフォームURLに差し替えてください
  static const String featureRequestFormUrl =
      'https://forms.gle/PLACEHOLDER_FEATURE';

  // === アプリ情報 ===
  /// アプリ名
  static const String appName = '目標達成タイマー';

  /// アプリバージョン
  static const String appVersion = '1.0.0';

  // === フィードバック設定 ===
  /// フィードバックポップアップの表示間隔（カウントダウン完了回数）
  static const int feedbackPopupInterval = 3;

  /// フィードバックポップアップの非表示期間（日数）
  static const int feedbackPopupCooldownDays = 7;
}
