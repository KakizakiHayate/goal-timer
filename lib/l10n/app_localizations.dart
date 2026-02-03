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
