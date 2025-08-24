import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks/mock_services.dart';

/// Test helpers for MVP onboarding tests
class TestHelpers {
  /// Setup clean test environment
  static Future<void> setupCleanEnvironment() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Create a temp user with specified step completion
  static Future<void> setupTempUser({
    required int step,
    int? daysAgo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = daysAgo != null 
        ? DateTime.now().subtract(Duration(days: daysAgo)).millisecondsSinceEpoch
        : DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setString('temp_user_id', 'local_user_temp_$timestamp');
    await prefs.setInt('temp_user_created_at', timestamp);
    await prefs.setInt('temp_onboarding_step', step);
  }

  /// Setup authenticated user state
  static Future<void> setupAuthenticatedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_authenticated', true);
    await prefs.setString('user_id', 'auth_user_123');
  }

  /// Setup premium user state
  static Future<void> setupPremiumUser() async {
    await setupAuthenticatedUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
  }

  /// Verify temp user data exists
  static Future<bool> tempUserExists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('temp_user_id') != null;
  }

  /// Verify temp user data is cleaned up
  static Future<bool> tempUserCleanedUp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('temp_user_id') == null &&
           prefs.getInt('temp_user_created_at') == null &&
           prefs.getInt('temp_onboarding_step') == null;
  }

  /// Get current onboarding step
  static Future<int> getCurrentOnboardingStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('temp_onboarding_step') ?? 0;
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_authenticated') ?? false;
  }

  /// Check if user is premium
  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_premium') ?? false;
  }

  /// Wait for widget to appear with timeout
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final end = tester.binding.clock.now().add(timeout);
    
    while (tester.binding.clock.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    
    throw TimeoutException('Widget not found within timeout', timeout);
  }

  /// Create test provider overrides for testing
  static List<Override> createTestProviderOverrides() {
    return [
      // Add mock provider overrides here if needed
      // For now, return empty list to use real providers
    ];
  }

  /// Pump widget until settled with timeout
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = tester.binding.clock.now().add(timeout);
    
    while (tester.binding.clock.now().isBefore(end)) {
      await tester.pump();
      if (!tester.hasRunningAnimations) {
        break;
      }
    }
  }

  /// Fill onboarding goal form
  static Future<void> fillGoalForm(
    WidgetTester tester, {
    String goalName = 'Test Goal',
    String reason = 'Test Reason',
    String consequence = 'Test Consequence',
  }) async {
    await tester.enterText(
      find.byKey(const Key('goal_name_field')), 
      goalName,
    );
    await tester.enterText(
      find.byKey(const Key('goal_reason_field')), 
      reason,
    );
    await tester.enterText(
      find.byKey(const Key('goal_consequence_field')), 
      consequence,
    );
    await tester.pump();
  }

  /// Navigate through onboarding steps
  static Future<void> completeOnboardingToStep(
    WidgetTester tester,
    int targetStep,
  ) async {
    if (targetStep >= 1) {
      // Complete goal creation
      await fillGoalForm(tester);
      await tester.tap(find.byKey(const Key('next_button')));
      await pumpAndSettleWithTimeout(tester);
    }

    if (targetStep >= 2) {
      // Complete demo timer
      await tester.pump(const Duration(seconds: 6));
      await pumpAndSettleWithTimeout(tester);
      
      // Dismiss completion dialog
      await tester.tap(find.text('次へ'));
      await pumpAndSettleWithTimeout(tester);
    }

    if (targetStep >= 3) {
      // Complete account creation (as guest)
      await tester.tap(find.text('ゲストとして続ける'));
      await pumpAndSettleWithTimeout(tester);
    }
  }

  /// Verify progress indicator value
  static void verifyProgressIndicator(
    WidgetTester tester,
    double expectedProgress,
  ) {
    final progressIndicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progressIndicator.value, closeTo(expectedProgress, 0.01));
  }

  /// Verify timer button state
  static void verifyTimerButtonState(
    WidgetTester tester,
    String buttonKey,
    bool shouldBeEnabled,
  ) {
    final buttonFinder = find.byKey(Key(buttonKey));
    expect(buttonFinder, findsOneWidget);
    
    final button = tester.widget<ElevatedButton>(buttonFinder);
    if (shouldBeEnabled) {
      expect(button.onPressed, isNotNull);
    } else {
      expect(button.onPressed, isNull);
    }
  }

  /// Create test goal data
  static Map<String, dynamic> createTestGoalData({
    String? tempUserId,
    String goalName = 'Test Goal',
    String reason = 'Test Reason',
    String consequence = 'Test Consequence',
  }) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'temp_user_id': tempUserId,
      'goal_name': goalName,
      'reason': reason,
      'consequence': consequence,
      'is_temp': tempUserId != null ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create test study log data
  static Map<String, dynamic> createTestStudyLogData({
    String? tempUserId,
    String goalId = 'test_goal_id',
    int duration = 1800, // 30 minutes
  }) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'temp_user_id': tempUserId,
      'goal_id': goalId,
      'duration': duration,
      'is_temp': tempUserId != null ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Custom matchers for testing
class CustomMatchers {
  /// Matcher for temp user ID format
  static Matcher isTempUserId() {
    return predicate<String>(
      (value) => value.startsWith('local_user_temp_') && value.length > 18,
      'is a valid temp user ID',
    );
  }

  /// Matcher for progress values
  static Matcher isProgressValue(double expected) {
    return closeTo(expected, 0.01);
  }

  /// Matcher for timestamp within range
  static Matcher isRecentTimestamp({Duration tolerance = const Duration(seconds: 10)}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final min = now - tolerance.inMilliseconds;
    final max = now + tolerance.inMilliseconds;
    
    return predicate<int>(
      (value) => value >= min && value <= max,
      'is a recent timestamp',
    );
  }
}

/// Exception for test timeouts
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}