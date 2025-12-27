/// データベース定数
class DatabaseConsts {
  // データベース名
  static const String databaseName = 'goal_timer.db';
  static const int databaseVersion = 3;

  // テーブル名
  static const String tableStudyDailyLogs = 'study_daily_logs';
  static const String tableGoals = 'goals';
  static const String tableUsers = 'users';

  // study_daily_logs カラム
  static const String columnId = 'id';
  static const String columnGoalId = 'goal_id';
  static const String columnStudyDate = 'study_date';
  static const String columnTotalSeconds = 'total_seconds';
  static const String columnUserId = 'user_id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnSyncUpdatedAt = 'sync_updated_at';

  // goals カラム
  static const String columnTitle = 'title';
  static const String columnDescription = 'description';
  static const String columnTargetMinutes = 'target_minutes';
  static const String columnAvoidMessage = 'avoid_message';
  static const String columnDeadline = 'deadline';
  static const String columnCompletedAt = 'completed_at';

  // goals カラム（論理削除用）
  static const String columnDeletedAt = 'deleted_at';

  // users カラム
  static const String columnEmail = 'email';
  static const String columnDisplayName = 'display_name';
  static const String columnLastLogin = 'last_login';
  static const String columnLongestStreak = 'longest_streak';
}
