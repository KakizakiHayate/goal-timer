/// フォーム検証用の定数定義
class ValidationConsts {
  ValidationConsts._();

  // 目標タイトルの最小文字数
  static const int minTitleLength = 2;

  // 回避メッセージの最小文字数
  static const int minAvoidMessageLength = 5;

  // デフォルトの目標時間（分）
  static const int defaultTargetMinutes = 30;

  // デフォルトの期限（日数）
  static const int defaultDeadlineDays = 30;
}
