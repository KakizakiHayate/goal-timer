/// ストリーク機能に関連する定数
class StreakConsts {
  // ビジネスロジック定数
  /// 学習日としてカウントする最小秒数（1分 = 60秒）
  static const int minStudySeconds = 60;

  /// ミニヒートマップに表示する日数
  static const int recentDaysCount = 7;

  /// ストリーク計算時のクエリ上限（パフォーマンス最適化）
  /// 400日以上の連続ストリークにも対応可能
  static const int maxStreakQueryLimit = 400;

  /// 最後のドットのインデックスオフセット（ドット間隔計算用）
  static const int lastDotIndexOffset = 1;

  /// 1週間達成のマイルストーン
  static const int weekMilestone = 7;

  /// 1ヶ月達成のマイルストーン
  static const int monthMilestone = 30;

  // UI定数
  /// ドットサイズ
  static const double dotSize = 28.0;

  /// ドット間隔
  static const double dotSpacing = 8.0;

  /// ドット角丸
  static const double dotBorderRadius = 6.0;

  /// 今日の未学習ドットの枠線幅
  static const double todayBorderWidth = 2.0;

  // メッセージ
  /// ストリーク0日のメッセージ
  static const String messageZeroStreak = '今日から始めよう！';

  /// 1週間達成のメッセージ
  static const String messageWeekMilestone = '1週間達成！';

  /// 1ヶ月達成のメッセージ
  static const String messageMonthMilestone = '1ヶ月達成！';

  /// 連続学習中のメッセージテンプレート
  static String messageStreakDays(int days) => '$days日連続学習中！';
}
