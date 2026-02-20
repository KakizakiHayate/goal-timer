import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Goal Timer'**
  String get appName;

  /// Common cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonBtnCancel;

  /// Common OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonBtnOk;

  /// Common save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonBtnSave;

  /// Common delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonBtnDelete;

  /// Default name for guest users
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get defaultGuestName;

  /// Time format with hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String timeFormatHoursMinutes(int hours, int minutes);

  /// Time format with minutes only
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String timeFormatMinutes(int minutes);

  /// Days suffix with plural support
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}}'**
  String daysSuffix(int count);

  /// Progress label in goal card
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Start timer button text
  ///
  /// In en, this message translates to:
  /// **'Start Timer'**
  String get btnStartTimer;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get btnEdit;

  /// Deadline info text in goal card
  ///
  /// In en, this message translates to:
  /// **'Until {month}/{day} ({days} days left)'**
  String deadlineInfo(int month, int day, int days);

  /// Timer complete notification title
  ///
  /// In en, this message translates to:
  /// **'Timer Complete'**
  String get timerCompleteTitle;

  /// Timer complete notification message
  ///
  /// In en, this message translates to:
  /// **'Study time for \"{goal}\" has ended'**
  String timerCompleteMessage(String goal);

  /// Timer notification channel name
  ///
  /// In en, this message translates to:
  /// **'Timer Complete'**
  String get timerChannelName;

  /// Timer notification channel description
  ///
  /// In en, this message translates to:
  /// **'Notifications when timer completes'**
  String get timerChannelDescription;

  /// Streak reminder notification channel name
  ///
  /// In en, this message translates to:
  /// **'Streak Reminder'**
  String get streakReminderChannelName;

  /// Streak reminder notification channel description
  ///
  /// In en, this message translates to:
  /// **'Reminders to maintain your study streak'**
  String get streakReminderChannelDescription;

  /// Streak reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Let\'s study today!'**
  String get reminderTitle;

  /// Streak warning notification title
  ///
  /// In en, this message translates to:
  /// **'Your streak is at risk!'**
  String get warningTitle;

  /// Streak final warning notification title
  ///
  /// In en, this message translates to:
  /// **'Last chance!'**
  String get finalWarningTitle;

  /// Streak reminder notification message
  ///
  /// In en, this message translates to:
  /// **'You\'ve studied {days, plural, one{1 day} other{{days} days}} in a row. Keep it up!'**
  String reminderMessage(int days);

  /// Streak warning notification message
  ///
  /// In en, this message translates to:
  /// **'Your {days, plural, one{1-day} other{{days}-day}} streak will break! The day is almost over.'**
  String warningMessage(int days);

  /// Streak final warning notification message
  ///
  /// In en, this message translates to:
  /// **'Protect your {days, plural, one{1-day} other{{days}-day}} streak! Study for at least 1 minute today.'**
  String finalWarningMessage(int days);

  /// Reminder message when user has no streak
  ///
  /// In en, this message translates to:
  /// **'Start studying today!'**
  String get reminderNoStreak;

  /// Warning message when user has no streak
  ///
  /// In en, this message translates to:
  /// **'How about studying today? There\'s still time!'**
  String get warningNoStreak;

  /// Final warning message when user has no streak
  ///
  /// In en, this message translates to:
  /// **'Study today to start your streak!'**
  String get finalWarningNoStreak;

  /// Bottom navigation home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation timer tab label
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get navTimer;

  /// Bottom navigation settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Morning greeting with user name
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String greetingMorning(String name);

  /// Afternoon greeting with user name
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greetingAfternoon(String name);

  /// Evening greeting with user name
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String greetingEvening(String name);

  /// Section header for goals list
  ///
  /// In en, this message translates to:
  /// **'My Goals'**
  String get sectionMyGoals;

  /// Title when there are no goals
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get emptyGoalsTitle;

  /// Message when there are no goals
  ///
  /// In en, this message translates to:
  /// **'Tap the + button below\nto add a new goal'**
  String get emptyGoalsMessage;

  /// Timer tab app bar title
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerTabTitle;

  /// Message when there are no goals for timer
  ///
  /// In en, this message translates to:
  /// **'Create a goal\nto use the timer'**
  String get timerEmptyMessage;

  /// Instruction to select a goal for timer
  ///
  /// In en, this message translates to:
  /// **'Select a goal to start the timer'**
  String get timerSelectGoal;

  /// Delete goal confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete this goal?'**
  String get deleteGoalTitle;

  /// Delete goal confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'This goal and all related study logs will be permanently deleted. This action cannot be undone.'**
  String get deleteGoalMessage;

  /// Success message when goal is deleted
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get goalDeletedMessage;

  /// Error message when goal deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete goal'**
  String get goalDeleteFailedMessage;

  /// Timer screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerScreenTitle;

  /// Countdown timer mode
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get modeCountdown;

  /// Count up timer mode
  ///
  /// In en, this message translates to:
  /// **'Count Up'**
  String get modeCountup;

  /// Timer status when running
  ///
  /// In en, this message translates to:
  /// **'Focusing...'**
  String get statusFocusing;

  /// Timer status when paused
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// Timer status when ready to start
  ///
  /// In en, this message translates to:
  /// **'Press Start'**
  String get statusReady;

  /// Timer complete dialog title
  ///
  /// In en, this message translates to:
  /// **'Timer Complete'**
  String get dialogTimerCompleteTitle;

  /// Timer complete dialog message
  ///
  /// In en, this message translates to:
  /// **'Would you like to record {time} as study time?'**
  String dialogTimerCompleteMessage(String time);

  /// Record button text
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get btnRecord;

  /// Don't record button text
  ///
  /// In en, this message translates to:
  /// **'Don\'t Record'**
  String get btnDontRecord;

  /// Study complete dialog title
  ///
  /// In en, this message translates to:
  /// **'Study Complete'**
  String get dialogStudyCompleteTitle;

  /// Back confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Stop studying?'**
  String get dialogBackConfirmTitle;

  /// Back confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Unrecorded study time will be lost.'**
  String get dialogBackConfirmMessage;

  /// Quit button text
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get btnQuit;

  /// Mode switch dialog title
  ///
  /// In en, this message translates to:
  /// **'Switch Mode'**
  String get dialogModeSwitchTitle;

  /// Mode switch blocked dialog message
  ///
  /// In en, this message translates to:
  /// **'Please save or reset the timer before switching modes.'**
  String get dialogModeSwitchMessage;

  /// Complete button text
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get btnComplete;

  /// Study records screen title
  ///
  /// In en, this message translates to:
  /// **'Study Records'**
  String get studyRecordsTitle;

  /// Month format for calendar navigation
  ///
  /// In en, this message translates to:
  /// **'{year}/{month}'**
  String monthFormat(int year, int month);

  /// Current streak label
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreakLabel;

  /// Longest streak label
  ///
  /// In en, this message translates to:
  /// **'Longest Streak'**
  String get longestStreakLabel;

  /// Add goal modal title
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get addGoalTitle;

  /// Edit goal modal title
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get editGoalTitle;

  /// Success message when goal is added
  ///
  /// In en, this message translates to:
  /// **'Goal added'**
  String get goalAddedMessage;

  /// Success message when goal is updated
  ///
  /// In en, this message translates to:
  /// **'Goal updated'**
  String get goalUpdatedMessage;

  /// Error message when goal addition fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add goal'**
  String get goalAddFailedMessage;

  /// Error message when goal update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update goal'**
  String get goalUpdateFailedMessage;

  /// Validation message for deadline selection
  ///
  /// In en, this message translates to:
  /// **'Please select a deadline'**
  String get selectDeadlineValidation;

  /// Goal name field label
  ///
  /// In en, this message translates to:
  /// **'Goal Name *'**
  String get goalNameLabel;

  /// Description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// Target minutes field label
  ///
  /// In en, this message translates to:
  /// **'Daily Study Time *'**
  String get targetMinutesLabel;

  /// Deadline field label
  ///
  /// In en, this message translates to:
  /// **'Deadline *'**
  String get deadlineLabel;

  /// Avoid message field label
  ///
  /// In en, this message translates to:
  /// **'What happens if you don\'t achieve it? *'**
  String get avoidMessageLabel;

  /// Hint text for avoid message field
  ///
  /// In en, this message translates to:
  /// **'Clarifying negative outcomes helps maintain motivation'**
  String get avoidMessageHint;

  /// Validation message for required goal name
  ///
  /// In en, this message translates to:
  /// **'Please enter a goal name'**
  String get goalNameRequired;

  /// Validation message for required avoid message
  ///
  /// In en, this message translates to:
  /// **'Please enter what happens if you don\'t achieve it'**
  String get avoidMessageRequired;

  /// Placeholder for goal name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Get TOEIC 800'**
  String get goalNamePlaceholder;

  /// Placeholder for description field
  ///
  /// In en, this message translates to:
  /// **'e.g. I want to improve my English for working abroad'**
  String get descriptionPlaceholder;

  /// Placeholder for avoid message field
  ///
  /// In en, this message translates to:
  /// **'e.g. Miss career advancement opportunities'**
  String get avoidMessagePlaceholder;

  /// Placeholder for deadline selection
  ///
  /// In en, this message translates to:
  /// **'Select a deadline'**
  String get selectDeadlinePlaceholder;

  /// Time picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Set Target Time'**
  String get setTargetTimeTitle;

  /// Hours unit label
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hoursUnit;

  /// Minutes unit label
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get btnConfirm;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get btnUpdate;

  /// Remaining days and total target time info
  ///
  /// In en, this message translates to:
  /// **'{days} days left → Total target: {time}'**
  String remainingDaysInfo(int days, String time);

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Hint text for profile section
  ///
  /// In en, this message translates to:
  /// **'Tap to change name'**
  String get tapToChangeName;

  /// Name change dialog title
  ///
  /// In en, this message translates to:
  /// **'Change Name'**
  String get changeNameDialogTitle;

  /// Name change dialog hint
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get changeNameDialogHint;

  /// Error message for empty name
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get emptyNameError;

  /// Error message for offline state
  ///
  /// In en, this message translates to:
  /// **'Cannot change while offline'**
  String get offlineError;

  /// Success message for name change
  ///
  /// In en, this message translates to:
  /// **'Name changed successfully'**
  String get nameChangedSuccess;

  /// Error message for name change failure
  ///
  /// In en, this message translates to:
  /// **'Failed to change name'**
  String get nameChangeFailed;

  /// Account link section title
  ///
  /// In en, this message translates to:
  /// **'Account Link'**
  String get sectionAccountLink;

  /// Link account button title
  ///
  /// In en, this message translates to:
  /// **'Link Account'**
  String get linkAccount;

  /// Link account button subtitle
  ///
  /// In en, this message translates to:
  /// **'Backup data with Google / Apple'**
  String get linkAccountSubtitle;

  /// Account linked status
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get accountLinked;

  /// Default account linked subtitle
  ///
  /// In en, this message translates to:
  /// **'Account linked'**
  String get accountLinkedDefault;

  /// App settings section title
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get sectionAppSettings;

  /// Default timer duration setting title
  ///
  /// In en, this message translates to:
  /// **'Default Timer Duration'**
  String get defaultTimerDuration;

  /// Default timer duration setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Default time for new goals: {time}'**
  String defaultTimerDurationSubtitle(String time);

  /// Notifications section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get sectionNotifications;

  /// Streak reminder setting title
  ///
  /// In en, this message translates to:
  /// **'Streak Reminder'**
  String get streakReminder;

  /// Streak reminder enabled subtitle
  ///
  /// In en, this message translates to:
  /// **'Receive reminders to maintain your study streak'**
  String get streakReminderOnSubtitle;

  /// Streak reminder disabled subtitle
  ///
  /// In en, this message translates to:
  /// **'Reminder notifications are OFF'**
  String get streakReminderOffSubtitle;

  /// Data and privacy section title
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get sectionDataPrivacy;

  /// Privacy policy setting title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Privacy policy setting subtitle
  ///
  /// In en, this message translates to:
  /// **'About data handling'**
  String get privacyPolicySubtitle;

  /// Support section title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get sectionSupport;

  /// Bug report setting title
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get bugReport;

  /// Bug report setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Report bugs and issues'**
  String get bugReportSubtitle;

  /// Feature request setting title
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get featureRequest;

  /// Feature request setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Share your ideas for new features'**
  String get featureRequestSubtitle;

  /// About app setting title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// Account management section title
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get sectionAccountManagement;

  /// Logout button title
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout button subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign out from your account'**
  String get logoutSubtitle;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// Logout failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to logout'**
  String get logoutFailed;

  /// Delete account button title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Delete account button subtitle
  ///
  /// In en, this message translates to:
  /// **'All data will be deleted'**
  String get deleteAccountSubtitle;

  /// Delete account confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountConfirmTitle;

  /// Delete account confirmation message
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.\n\nAll your data (goals, study records, etc.) will be permanently deleted.'**
  String get deleteAccountConfirmMessage;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// Final delete account confirmation title
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteAccountFinalTitle;

  /// Final delete account confirmation message
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete your account and all your data.'**
  String get deleteAccountFinalMessage;

  /// Stop/Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get btnStop;

  /// Delete account failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get deleteAccountFailed;

  /// URL open failure message
  ///
  /// In en, this message translates to:
  /// **'Could not open URL'**
  String get urlOpenFailed;

  /// About dialog title
  ///
  /// In en, this message translates to:
  /// **'About {appName}'**
  String aboutDialogTitle(String appName);

  /// About dialog description
  ///
  /// In en, this message translates to:
  /// **'A timer app to help you achieve your goals. Small daily efforts lead to great results.'**
  String get aboutDialogDescription;

  /// View details link text
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// Message when streak is 0 days
  ///
  /// In en, this message translates to:
  /// **'Let\'s start today!'**
  String get streakMessageZero;

  /// Message for 1 week milestone
  ///
  /// In en, this message translates to:
  /// **'1 week achieved!'**
  String get streakMessageWeek;

  /// Message for 1 month milestone
  ///
  /// In en, this message translates to:
  /// **'1 month achieved!'**
  String get streakMessageMonth;

  /// Message for ongoing streak
  ///
  /// In en, this message translates to:
  /// **'{days} day streak!'**
  String streakMessageDays(int days);

  /// Placeholder name for deleted goals
  ///
  /// In en, this message translates to:
  /// **'Deleted Goal'**
  String get deletedGoal;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// Account link screen title
  ///
  /// In en, this message translates to:
  /// **'Link Account'**
  String get accountLinkTitle;

  /// Login screen description
  ///
  /// In en, this message translates to:
  /// **'Resume with your\nprevious data'**
  String get loginDescription;

  /// Account link screen description
  ///
  /// In en, this message translates to:
  /// **'Link your account to safely\nbackup your data'**
  String get linkDescription;

  /// Google login button text
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginWithGoogle;

  /// Google link button text
  ///
  /// In en, this message translates to:
  /// **'Link with Google'**
  String get linkWithGoogle;

  /// Apple login button text
  ///
  /// In en, this message translates to:
  /// **'Login with Apple'**
  String get loginWithApple;

  /// Apple link button text
  ///
  /// In en, this message translates to:
  /// **'Link with Apple'**
  String get linkWithApple;

  /// Login screen notice for new users
  ///
  /// In en, this message translates to:
  /// **'If you don\'t have an account, please use \"Start Now\"'**
  String get loginNotice;

  /// Account link notice
  ///
  /// In en, this message translates to:
  /// **'Your guest data will be preserved after linking'**
  String get linkNotice;

  /// Login failed dialog title
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailedTitle;

  /// Account link failed dialog title
  ///
  /// In en, this message translates to:
  /// **'Link Failed'**
  String get linkFailedTitle;

  /// Error message when account is not found
  ///
  /// In en, this message translates to:
  /// **'This account is not registered.\nTo register, please use \"Start Now\" and link your account.'**
  String get accountNotFoundMessage;

  /// Error message when account already exists
  ///
  /// In en, this message translates to:
  /// **'This account is already registered.\nTo link, please login first and delete the account.'**
  String get accountAlreadyExistsMessage;

  /// Error message when email is not found
  ///
  /// In en, this message translates to:
  /// **'Could not retrieve email address.\nPlease unlink your Apple ID in Settings and try again.'**
  String get emailNotFoundMessage;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred.\nPlease try again later.'**
  String get genericErrorMessage;

  /// Confirm account link dialog title
  ///
  /// In en, this message translates to:
  /// **'Link your account?'**
  String get confirmLinkTitle;

  /// Confirm account link message
  ///
  /// In en, this message translates to:
  /// **'Link with {provider} account'**
  String confirmLinkMessage(String provider);

  /// Link button text
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get btnLink;

  /// Link success dialog title
  ///
  /// In en, this message translates to:
  /// **'Link Complete'**
  String get linkSuccessTitle;

  /// Link success message
  ///
  /// In en, this message translates to:
  /// **'Account linked successfully'**
  String get linkSuccessMessage;

  /// Feedback dialog title
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get feedbackTitle;

  /// Feedback dialog message
  ///
  /// In en, this message translates to:
  /// **'Would you spare a minute to help us improve the app? The developers read every response.'**
  String get feedbackMessage;

  /// Answer button text
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get btnAnswer;

  /// Not now button text
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get btnNotNow;

  /// Welcome screen catch copy line 1
  ///
  /// In en, this message translates to:
  /// **'Turn goal achievement'**
  String get welcomeCatchCopy1;

  /// Welcome screen catch copy line 2
  ///
  /// In en, this message translates to:
  /// **'into a habit'**
  String get welcomeCatchCopy2;

  /// Start now button text
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get btnStartNow;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get btnLogin;

  /// Welcome screen login description
  ///
  /// In en, this message translates to:
  /// **'Login to resume with your\nprevious data'**
  String get welcomeLoginDescription;

  /// Splash screen checking network status
  ///
  /// In en, this message translates to:
  /// **'Checking network...'**
  String get splashCheckingNetwork;

  /// Splash screen authenticating status
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get splashAuthenticating;

  /// Splash screen preparing data status
  ///
  /// In en, this message translates to:
  /// **'Preparing data...'**
  String get splashPreparingData;

  /// Splash screen complete status
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get splashComplete;

  /// Splash screen offline status
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get splashOffline;

  /// Splash screen error status
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get splashErrorOccurred;

  /// Network error dialog title
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkErrorTitle;

  /// Network error dialog message
  ///
  /// In en, this message translates to:
  /// **'Please connect to the network.\nThis app requires an internet connection.'**
  String get networkErrorMessage;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get btnRetry;

  /// Generic error dialog title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// Initialization failed error message
  ///
  /// In en, this message translates to:
  /// **'Initialization failed. Please contact support.'**
  String get initializationFailedMessage;

  /// Error when auth credentials not found
  ///
  /// In en, this message translates to:
  /// **'Could not retrieve credentials'**
  String get authCredentialNotFound;

  /// Generic login failed message
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get authLoginFailed;

  /// Bottom navigation analytics tab label
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// Analytics summary total time label
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get analyticsTotalTime;

  /// Analytics summary daily average label
  ///
  /// In en, this message translates to:
  /// **'Daily Avg'**
  String get analyticsDailyAverage;

  /// Analytics summary study days label
  ///
  /// In en, this message translates to:
  /// **'Study Days'**
  String get analyticsStudyDays;

  /// Analytics days suffix with plural support
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}}'**
  String analyticsDaysSuffix(int count);

  /// Analytics period selector week label
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get analyticsWeek;

  /// Analytics period selector month label
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get analyticsMonth;

  /// Analytics month year format
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String analyticsMonthYear(String month, int year);

  /// Analytics tooltip total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get analyticsTotal;

  /// Analytics empty state message
  ///
  /// In en, this message translates to:
  /// **'No study records yet'**
  String get analyticsNoData;

  /// Analytics empty state CTA button
  ///
  /// In en, this message translates to:
  /// **'Start studying with Timer'**
  String get analyticsStartStudying;

  /// Analytics seconds format
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String analyticsSecondsFormat(int seconds);

  /// Analytics minutes format
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String analyticsMinutesFormat(int minutes);

  /// Analytics hours format for Y axis
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String analyticsHoursFormat(int hours);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
