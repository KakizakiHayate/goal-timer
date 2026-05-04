/// GA4 に送信するカスタムイベントの一覧。
///
/// 文字列を直接書かせないことで snake_case 違反・タイポを防ぐ。
/// 新イベント追加時はこの enum に値を追加し、`AnalyticsService` に
/// 対応する型付きメソッドを追加する。
enum AnalyticsEvent {
  // タイマー
  timerStart,
  timerPause,
  timerResume,
  timerCancel,
  timerComplete,

  // 目標管理
  goalCreate,
  goalEdit,
  goalDelete,

  // レビュー誘導
  reviewPromptEligible,
  reviewPromptShown;

  /// GA4 に送信するイベント名（snake_case）を返す。
  String get eventName {
    switch (this) {
      case AnalyticsEvent.timerStart:
        return 'timer_start';
      case AnalyticsEvent.timerPause:
        return 'timer_pause';
      case AnalyticsEvent.timerResume:
        return 'timer_resume';
      case AnalyticsEvent.timerCancel:
        return 'timer_cancel';
      case AnalyticsEvent.timerComplete:
        return 'timer_complete';
      case AnalyticsEvent.goalCreate:
        return 'goal_create';
      case AnalyticsEvent.goalEdit:
        return 'goal_edit';
      case AnalyticsEvent.goalDelete:
        return 'goal_delete';
      case AnalyticsEvent.reviewPromptEligible:
        return 'review_prompt_eligible';
      case AnalyticsEvent.reviewPromptShown:
        return 'review_prompt_shown';
    }
  }
}
