// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Goal Timer';

  @override
  String get commonBtnCancel => 'Cancel';

  @override
  String get commonBtnOk => 'OK';

  @override
  String get commonBtnSave => 'Save';

  @override
  String get commonBtnDelete => 'Delete';

  @override
  String get defaultGuestName => 'Guest';

  @override
  String timeFormatHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String timeFormatMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String daysSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get progress => 'Progress';

  @override
  String get btnStartTimer => 'Start Timer';

  @override
  String get btnEdit => 'Edit';

  @override
  String deadlineInfo(int month, int day, int days) {
    return 'Until $month/$day ($days days left)';
  }

  @override
  String get timerCompleteTitle => 'Timer Complete';

  @override
  String timerCompleteMessage(String goal) {
    return 'Study time for \"$goal\" has ended';
  }

  @override
  String get timerChannelName => 'Timer Complete';

  @override
  String get timerChannelDescription => 'Notifications when timer completes';

  @override
  String get streakReminderChannelName => 'Streak Reminder';

  @override
  String get streakReminderChannelDescription =>
      'Reminders to maintain your study streak';

  @override
  String get reminderTitle => 'Let\'s study today!';

  @override
  String get warningTitle => 'Your streak is at risk!';

  @override
  String get finalWarningTitle => 'Last chance!';

  @override
  String reminderMessage(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'You\'ve studied $_temp0 in a row. Keep it up!';
  }

  @override
  String warningMessage(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day',
      one: '1-day',
    );
    return 'Your $_temp0 streak will break! The day is almost over.';
  }

  @override
  String finalWarningMessage(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day',
      one: '1-day',
    );
    return 'Protect your $_temp0 streak! Study for at least 1 minute today.';
  }

  @override
  String get reminderNoStreak => 'Start studying today!';

  @override
  String get warningNoStreak =>
      'How about studying today? There\'s still time!';

  @override
  String get finalWarningNoStreak => 'Study today to start your streak!';

  @override
  String get navHome => 'Home';

  @override
  String get navTimer => 'Timer';

  @override
  String get navSettings => 'Settings';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Hello, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get sectionMyGoals => 'My Goals';

  @override
  String get emptyGoalsTitle => 'No goals yet';

  @override
  String get emptyGoalsMessage => 'Tap the + button below\nto add a new goal';

  @override
  String get timerTabTitle => 'Timer';

  @override
  String get timerEmptyMessage => 'Create a goal\nto use the timer';

  @override
  String get timerSelectGoal => 'Select a goal to start the timer';

  @override
  String get deleteGoalTitle => 'Delete this goal?';

  @override
  String get deleteGoalMessage =>
      'This goal and all related study logs will be permanently deleted. This action cannot be undone.';

  @override
  String get goalDeletedMessage => 'Goal deleted';

  @override
  String get goalDeleteFailedMessage => 'Failed to delete goal';

  @override
  String get timerScreenTitle => 'Timer';

  @override
  String get modeCountdown => 'Countdown';

  @override
  String get modeCountup => 'Count Up';

  @override
  String get statusFocusing => 'Focusing...';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusReady => 'Press Start';

  @override
  String get dialogTimerCompleteTitle => 'Timer Complete';

  @override
  String dialogTimerCompleteMessage(String time) {
    return 'Would you like to record $time as study time?';
  }

  @override
  String get btnRecord => 'Record';

  @override
  String get btnDontRecord => 'Don\'t Record';

  @override
  String get dialogStudyCompleteTitle => 'Study Complete';

  @override
  String get dialogBackConfirmTitle => 'Stop studying?';

  @override
  String get dialogBackConfirmMessage => 'Unrecorded study time will be lost.';

  @override
  String get btnQuit => 'Quit';

  @override
  String get dialogModeSwitchTitle => 'Switch Mode';

  @override
  String get dialogModeSwitchMessage =>
      'Please save or reset the timer before switching modes.';

  @override
  String get btnComplete => 'Complete';

  @override
  String get studyRecordsTitle => 'Study Records';

  @override
  String monthFormat(int year, int month) {
    return '$year/$month';
  }

  @override
  String get currentStreakLabel => 'Current Streak';

  @override
  String get longestStreakLabel => 'Longest Streak';

  @override
  String get addGoalTitle => 'Add Goal';

  @override
  String get editGoalTitle => 'Edit Goal';

  @override
  String get goalAddedMessage => 'Goal added';

  @override
  String get goalUpdatedMessage => 'Goal updated';

  @override
  String get goalAddFailedMessage => 'Failed to add goal';

  @override
  String get goalUpdateFailedMessage => 'Failed to update goal';

  @override
  String get selectDeadlineValidation => 'Please select a deadline';

  @override
  String get goalNameLabel => 'Goal Name *';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get targetMinutesLabel => 'Daily Study Time *';

  @override
  String get deadlineLabel => 'Deadline *';

  @override
  String get avoidMessageLabel => 'What happens if you don\'t achieve it? *';

  @override
  String get avoidMessageHint =>
      'Clarifying negative outcomes helps maintain motivation';

  @override
  String get goalNameRequired => 'Please enter a goal name';

  @override
  String get avoidMessageRequired =>
      'Please enter what happens if you don\'t achieve it';

  @override
  String get goalNamePlaceholder => 'e.g. Get TOEIC 800';

  @override
  String get descriptionPlaceholder =>
      'e.g. I want to improve my English for working abroad';

  @override
  String get avoidMessagePlaceholder =>
      'e.g. Miss career advancement opportunities';

  @override
  String get selectDeadlinePlaceholder => 'Select a deadline';

  @override
  String get setTargetTimeTitle => 'Set Target Time';

  @override
  String get hoursUnit => 'hours';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get btnConfirm => 'Confirm';

  @override
  String get btnUpdate => 'Update';

  @override
  String remainingDaysInfo(int days, String time) {
    return '$days days left → Total target: $time';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get tapToChangeName => 'Tap to change name';

  @override
  String get changeNameDialogTitle => 'Change Name';

  @override
  String get changeNameDialogHint => 'Enter name';

  @override
  String get emptyNameError => 'Please enter a name';

  @override
  String get offlineError => 'Cannot change while offline';

  @override
  String get nameChangedSuccess => 'Name changed successfully';

  @override
  String get nameChangeFailed => 'Failed to change name';

  @override
  String get sectionAccountLink => 'Account Link';

  @override
  String get linkAccount => 'Link Account';

  @override
  String get linkAccountSubtitle => 'Backup data with Google / Apple';

  @override
  String get accountLinked => 'Linked';

  @override
  String get accountLinkedDefault => 'Account linked';

  @override
  String get sectionAppSettings => 'App Settings';

  @override
  String get defaultTimerDuration => 'Default Timer Duration';

  @override
  String defaultTimerDurationSubtitle(String time) {
    return 'Default time for new goals: $time';
  }

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get streakReminder => 'Streak Reminder';

  @override
  String get streakReminderOnSubtitle =>
      'Receive reminders to maintain your study streak';

  @override
  String get streakReminderOffSubtitle => 'Reminder notifications are OFF';

  @override
  String get sectionDataPrivacy => 'Data & Privacy';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'About data handling';

  @override
  String get sectionSupport => 'Support';

  @override
  String get bugReport => 'Bug Report';

  @override
  String get bugReportSubtitle => 'Report bugs and issues';

  @override
  String get featureRequest => 'Feature Request';

  @override
  String get featureRequestSubtitle => 'Share your ideas for new features';

  @override
  String get aboutApp => 'About';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get sectionAccountManagement => 'Account Management';

  @override
  String get logout => 'Logout';

  @override
  String get logoutSubtitle => 'Sign out from your account';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to logout?';

  @override
  String get logoutFailed => 'Failed to logout';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle => 'All data will be deleted';

  @override
  String get deleteAccountConfirmTitle => 'Delete Account';

  @override
  String get deleteAccountConfirmMessage =>
      'This action cannot be undone.\n\nAll your data (goals, study records, etc.) will be permanently deleted.';

  @override
  String get btnDelete => 'Delete';

  @override
  String get deleteAccountFinalTitle => 'Are you sure?';

  @override
  String get deleteAccountFinalMessage =>
      'This action will permanently delete your account and all your data.';

  @override
  String get btnStop => 'Stop';

  @override
  String get deleteAccountFailed => 'Failed to delete account';

  @override
  String get urlOpenFailed => 'Could not open URL';

  @override
  String aboutDialogTitle(String appName) {
    return 'About $appName';
  }

  @override
  String get aboutDialogDescription =>
      'A timer app to help you achieve your goals. Small daily efforts lead to great results.';

  @override
  String get viewDetails => 'View details';

  @override
  String get streakMessageZero => 'Let\'s start today!';

  @override
  String get streakMessageWeek => '1 week achieved!';

  @override
  String get streakMessageMonth => '1 month achieved!';

  @override
  String streakMessageDays(int days) {
    return '$days day streak!';
  }

  @override
  String get deletedGoal => 'Deleted Goal';

  @override
  String get loginTitle => 'Login';

  @override
  String get accountLinkTitle => 'Link Account';

  @override
  String get loginDescription => 'Resume with your\nprevious data';

  @override
  String get linkDescription => 'Link your account to safely\nbackup your data';

  @override
  String get loginWithGoogle => 'Login with Google';

  @override
  String get linkWithGoogle => 'Link with Google';

  @override
  String get loginWithApple => 'Login with Apple';

  @override
  String get linkWithApple => 'Link with Apple';

  @override
  String get loginNotice =>
      'If you don\'t have an account, please use \"Start Now\"';

  @override
  String get linkNotice => 'Your guest data will be preserved after linking';

  @override
  String get loginFailedTitle => 'Login Failed';

  @override
  String get linkFailedTitle => 'Link Failed';

  @override
  String get accountNotFoundMessage =>
      'This account is not registered.\nTo register, please use \"Start Now\" and link your account.';

  @override
  String get accountAlreadyExistsMessage =>
      'This account is already registered.\nTo link, please login first and delete the account.';

  @override
  String get emailNotFoundMessage =>
      'Could not retrieve email address.\nPlease unlink your Apple ID in Settings and try again.';

  @override
  String get genericErrorMessage =>
      'An error occurred.\nPlease try again later.';

  @override
  String get confirmLinkTitle => 'Link your account?';

  @override
  String confirmLinkMessage(String provider) {
    return 'Link with $provider account';
  }

  @override
  String get btnLink => 'Link';

  @override
  String get linkSuccessTitle => 'Link Complete';

  @override
  String get linkSuccessMessage => 'Account linked successfully';

  @override
  String get feedbackTitle => 'Congratulations!';

  @override
  String get feedbackMessage =>
      'Would you spare a minute to help us improve the app? The developers read every response.';

  @override
  String get btnAnswer => 'Answer';

  @override
  String get btnNotNow => 'Not Now';
}
