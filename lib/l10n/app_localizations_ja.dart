// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Goal Timer';

  @override
  String get commonBtnCancel => 'キャンセル';

  @override
  String get commonBtnOk => 'OK';

  @override
  String get commonBtnSave => '保存';

  @override
  String get commonBtnDelete => '削除';

  @override
  String get defaultGuestName => 'ゲスト';

  @override
  String timeFormatHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String timeFormatMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String daysSuffix(int count) {
    return '$count日';
  }

  @override
  String get progress => '進捗';

  @override
  String get btnStartTimer => 'タイマー開始';

  @override
  String get btnEdit => '編集';

  @override
  String deadlineInfo(int month, int day, int days) {
    return '$month月$day日まで（あと$days日）';
  }

  @override
  String get timerCompleteTitle => 'タイマー完了';

  @override
  String timerCompleteMessage(String goal) {
    return '「$goal」の学習時間が終了しました';
  }

  @override
  String get timerChannelName => 'タイマー完了';

  @override
  String get timerChannelDescription => 'タイマーが完了した時の通知';

  @override
  String get streakReminderChannelName => 'ストリークリマインダー';

  @override
  String get streakReminderChannelDescription => '連続学習日数を維持するためのリマインダー通知';

  @override
  String get reminderTitle => '今日も学習しましょう！';

  @override
  String get warningTitle => 'ストリークが途切れそう！';

  @override
  String get finalWarningTitle => '最後のチャンス！';

  @override
  String reminderMessage(int days) {
    return '現在$days日連続で学習中です。今日も続けましょう！';
  }

  @override
  String warningMessage(int days) {
    return '$days日間の連続学習が途切れてしまいます！あと少しで1日終了です。';
  }

  @override
  String finalWarningMessage(int days) {
    return '$days日連続の記録を守りましょう！今日中に1分以上学習してください。';
  }

  @override
  String get reminderNoStreak => '今日から学習を始めましょう！';

  @override
  String get warningNoStreak => '今日も学習しませんか？まだ間に合います！';

  @override
  String get finalWarningNoStreak => '今日中に学習して、連続学習を始めましょう！';

  @override
  String get navHome => 'ホーム';

  @override
  String get navTimer => 'タイマー';

  @override
  String get navSettings => '設定';

  @override
  String greetingMorning(String name) {
    return 'おはよう、$name さん';
  }

  @override
  String greetingAfternoon(String name) {
    return 'こんにちは、$name さん';
  }

  @override
  String greetingEvening(String name) {
    return 'こんばんは、$name さん';
  }

  @override
  String get sectionMyGoals => 'マイ目標';

  @override
  String get emptyGoalsTitle => '目標がありません';

  @override
  String get emptyGoalsMessage => '下の+ボタンから\n新しい目標を追加してください';

  @override
  String get timerTabTitle => 'タイマー';

  @override
  String get timerEmptyMessage => 'タイマーを使用するには\n目標を作成してください';

  @override
  String get timerSelectGoal => 'タイマーを開始する目標を選択してください';

  @override
  String get deleteGoalTitle => '目標を削除しますか？';

  @override
  String get deleteGoalMessage => 'この目標と、紐づいた学習ログがすべて削除されます。この操作は元に戻せません。';

  @override
  String get goalDeletedMessage => '目標を削除しました';

  @override
  String get goalDeleteFailedMessage => '目標の削除に失敗しました';

  @override
  String get timerScreenTitle => 'タイマー';

  @override
  String get modeCountdown => 'カウントダウン';

  @override
  String get modeCountup => 'カウントアップ';

  @override
  String get statusFocusing => '集中中...';

  @override
  String get statusPaused => '一時停止中';

  @override
  String get statusReady => 'スタートを押してください';

  @override
  String get dialogTimerCompleteTitle => 'タイマー完了';

  @override
  String dialogTimerCompleteMessage(String time) {
    return '$timeを学習完了として記録しますか？';
  }

  @override
  String get btnRecord => '記録する';

  @override
  String get btnDontRecord => '記録しない';

  @override
  String get dialogStudyCompleteTitle => '学習完了';

  @override
  String get dialogBackConfirmTitle => '学習を中断しますか？';

  @override
  String get dialogBackConfirmMessage => '記録されていない学習時間は失われます。';

  @override
  String get btnQuit => '中断する';

  @override
  String get dialogModeSwitchTitle => 'モード切り替え';

  @override
  String get dialogModeSwitchMessage => 'タイマーを保存またはリセットしてからモードを切り替えてください';

  @override
  String get btnComplete => '完了';
}
