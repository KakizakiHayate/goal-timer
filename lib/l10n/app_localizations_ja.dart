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

  @override
  String get studyRecordsTitle => '学習記録';

  @override
  String monthFormat(int year, int month) {
    return '$year年$month月';
  }

  @override
  String get currentStreakLabel => '現在のストリーク';

  @override
  String get longestStreakLabel => '最長ストリーク';

  @override
  String get addGoalTitle => '目標を追加';

  @override
  String get editGoalTitle => '目標を編集';

  @override
  String get goalAddedMessage => '目標を追加しました';

  @override
  String get goalUpdatedMessage => '目標を更新しました';

  @override
  String get goalAddFailedMessage => '目標の追加に失敗しました';

  @override
  String get goalUpdateFailedMessage => '目標の更新に失敗しました';

  @override
  String get selectDeadlineValidation => '期限を選択してください';

  @override
  String get goalNameLabel => '目標名 *';

  @override
  String get descriptionLabel => '説明';

  @override
  String get targetMinutesLabel => '1日の勉強時間 *';

  @override
  String get deadlineLabel => '期限 *';

  @override
  String get avoidMessageLabel => '達成しないとどうなりますか？ *';

  @override
  String get avoidMessageHint => 'ネガティブな結果を明確にすることで、モチベーションを維持しやすくなります';

  @override
  String get goalNameRequired => '目標名を入力してください';

  @override
  String get avoidMessageRequired => '達成しない場合の結果を入力してください';

  @override
  String get goalNamePlaceholder => '例: TOEIC 800点取得';

  @override
  String get descriptionPlaceholder => '例: 海外転職のために英語力を向上させたい';

  @override
  String get avoidMessagePlaceholder => '例: キャリアアップの機会を逃してしまう';

  @override
  String get selectDeadlinePlaceholder => '期限を選択してください';

  @override
  String get setTargetTimeTitle => '目標時間を設定';

  @override
  String get hoursUnit => '時間';

  @override
  String get minutesUnit => '分';

  @override
  String get btnConfirm => '決定';

  @override
  String get btnUpdate => '更新';

  @override
  String remainingDaysInfo(int days, String time) {
    return '残り$days日 → 総目標時間: $time';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get tapToChangeName => 'タップして名前を変更';

  @override
  String get changeNameDialogTitle => '名前を変更';

  @override
  String get changeNameDialogHint => '名前を入力';

  @override
  String get emptyNameError => '名前を入力してください';

  @override
  String get offlineError => 'オフラインのため変更できません';

  @override
  String get nameChangedSuccess => '名前を変更しました';

  @override
  String get nameChangeFailed => '名前の変更に失敗しました';

  @override
  String get sectionAccountLink => 'アカウント連携';

  @override
  String get linkAccount => 'アカウントを連携する';

  @override
  String get linkAccountSubtitle => 'Google / Apple でデータをバックアップ';

  @override
  String get accountLinked => '連携済み';

  @override
  String get accountLinkedDefault => 'アカウント連携済み';

  @override
  String get sectionAppSettings => 'アプリ設定';

  @override
  String get defaultTimerDuration => 'デフォルトタイマー時間';

  @override
  String defaultTimerDurationSubtitle(String time) {
    return '新しい目標のデフォルト時間：$time';
  }

  @override
  String get sectionNotifications => '通知設定';

  @override
  String get streakReminder => 'ストリークリマインダー';

  @override
  String get streakReminderOnSubtitle => '連続学習を維持するためのリマインダーを受け取ります';

  @override
  String get streakReminderOffSubtitle => 'リマインダー通知はOFFです';

  @override
  String get sectionDataPrivacy => 'データとプライバシー';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get privacyPolicySubtitle => 'データの取り扱いについて';

  @override
  String get sectionSupport => 'サポート';

  @override
  String get bugReport => '不具合報告';

  @override
  String get bugReportSubtitle => 'バグや問題を報告する';

  @override
  String get featureRequest => '機能追加のご要望';

  @override
  String get featureRequestSubtitle => '新機能のアイデアをお聞かせください';

  @override
  String get aboutApp => 'アプリについて';

  @override
  String versionLabel(String version) {
    return 'バージョン $version';
  }

  @override
  String get sectionAccountManagement => 'アカウント管理';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutSubtitle => 'アカウントからログアウトします';

  @override
  String get logoutConfirmMessage => 'ログアウトしますか？';

  @override
  String get logoutFailed => 'ログアウトに失敗しました';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountSubtitle => 'すべてのデータが削除されます';

  @override
  String get deleteAccountConfirmTitle => 'アカウントを削除';

  @override
  String get deleteAccountConfirmMessage =>
      'この操作は取り消せません。\n\nすべてのデータ（目標、学習記録など）が\n完全に削除されます。';

  @override
  String get btnDelete => '削除する';

  @override
  String get deleteAccountFinalTitle => '本当に削除しますか？';

  @override
  String get deleteAccountFinalMessage =>
      'この操作を実行すると、あなたのアカウントと\nすべてのデータが完全に削除されます。';

  @override
  String get btnStop => 'やめる';

  @override
  String get deleteAccountFailed => 'アカウント削除に失敗しました';

  @override
  String get urlOpenFailed => 'URLを開けませんでした';

  @override
  String aboutDialogTitle(String appName) {
    return '$appName について';
  }

  @override
  String get aboutDialogDescription =>
      '目標達成をサポートするタイマーアプリです。毎日の小さな積み重ねが、大きな成果につながります。';

  @override
  String get viewDetails => '詳細を見る';

  @override
  String get streakMessageZero => '今日から始めよう！';

  @override
  String get streakMessageWeek => '1週間達成！';

  @override
  String get streakMessageMonth => '1ヶ月達成！';

  @override
  String streakMessageDays(int days) {
    return '$days日連続学習中！';
  }

  @override
  String get deletedGoal => '削除された目標';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get accountLinkTitle => 'アカウント連携';

  @override
  String get loginDescription => '以前のデータを引き継いで\n再開できます';

  @override
  String get linkDescription => 'アカウントを連携すると、データを\n安全にバックアップできます';

  @override
  String get loginWithGoogle => 'Google でログイン';

  @override
  String get linkWithGoogle => 'Google で連携';

  @override
  String get loginWithApple => 'Apple でログイン';

  @override
  String get linkWithApple => 'Apple で連携';

  @override
  String get loginNotice => 'アカウントをお持ちでない場合は「すぐに始める」をご利用ください';

  @override
  String get linkNotice => '連携後もゲストとしてのデータは保持されます';

  @override
  String get loginFailedTitle => 'ログインできませんでした';

  @override
  String get linkFailedTitle => '連携できませんでした';

  @override
  String get accountNotFoundMessage =>
      'このアカウントは登録されていません。\n新規登録は「すぐに始める」からアカウント連携を行ってください。';

  @override
  String get accountAlreadyExistsMessage =>
      'このアカウントは既に登録されています。\n連携するには、一度ログインしてアカウントを削除してください。';

  @override
  String get emailNotFoundMessage =>
      'メールアドレスを取得できませんでした。\n設定からApple IDの連携を解除して再度お試しください。';

  @override
  String get genericErrorMessage => 'エラーが発生しました。\nしばらくしてから再度お試しください。';

  @override
  String get confirmLinkTitle => 'アカウントを連携しますか？';

  @override
  String confirmLinkMessage(String provider) {
    return '$providerアカウントと連携します';
  }

  @override
  String get btnLink => '連携する';

  @override
  String get linkSuccessTitle => '連携完了';

  @override
  String get linkSuccessMessage => 'アカウントが正常に連携されました';

  @override
  String get feedbackTitle => '目標達成おめでとうございます!';

  @override
  String get feedbackMessage =>
      'より使いやすいアプリにするために、1分だけお声を聞かせていただけませんか？開発者が全て目を通します。';

  @override
  String get btnAnswer => '回答する';

  @override
  String get btnNotNow => '今はしない';
}
