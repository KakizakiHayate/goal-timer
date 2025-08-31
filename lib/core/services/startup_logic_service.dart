import 'package:shared_preferences/shared_preferences.dart';
import 'temp_user_service.dart';

/// Service for determining application startup logic and routing
class StartupLogicService {
  final TempUserService _tempUserService;

  StartupLogicService(this._tempUserService);

  /// Determine the initial route based on user state
  Future<String> determineInitialRoute() async {
    // Check if user is authenticated
    if (await _isUserAuthenticated()) {
      return '/home';
    }

    // Check for temp user and handle expired data
    final tempUserId = await _tempUserService.getTempUserId();
    if (tempUserId == null) {
      return '/onboarding/goal-creation';
    }

    // Check if temp user data is expired
    if (await _tempUserService.isTempUserExpired()) {
      await cleanupExpiredTempData();
      return '/onboarding/goal-creation';
    }

    // Check if tutorial is active - if so, go to home instead of continuing onboarding
    // This allows the tutorial to take over the user experience
    final prefs = await SharedPreferences.getInstance();
    final isTutorialActive = prefs.getBool('tutorial_active') ?? false;
    if (isTutorialActive) {
      return '/home'; // Let tutorial manage the flow
    }

    // Determine route based on onboarding step
    final step = await _tempUserService.getOnboardingStep();
    if (step >= 3) {
      return '/home'; // Onboarding completed as guest
    }

    return _getRouteForStep(step);
  }

  /// Check if onboarding should be shown
  Future<bool> shouldShowOnboarding() async {
    // Don't show onboarding for authenticated users
    if (await _isUserAuthenticated()) {
      return false;
    }

    // Check temp user state
    final tempUserId = await _tempUserService.getTempUserId();
    if (tempUserId == null) {
      return true; // First time user
    }

    // Check if expired
    if (await _tempUserService.isTempUserExpired()) {
      return true; // Expired data, restart onboarding
    }

    // Check completion status
    final step = await _tempUserService.getOnboardingStep();
    return step < 3; // Show if not completed
  }

  /// Get onboarding progress as a percentage (0.0 to 1.0)
  Future<double> getOnboardingProgress() async {
    final step = await _tempUserService.getOnboardingStep();

    switch (step) {
      case 0:
        return 0.0; // Starting
      case 1:
        return 0.33; // Goal creation completed
      case 2:
        return 0.66; // Demo timer completed
      case 3:
        return 1.0; // Account creation completed
      default:
        return 0.0;
    }
  }

  /// Clean up expired temporary data
  Future<void> cleanupExpiredTempData() async {
    final isExpired = await _tempUserService.isTempUserExpired();
    if (isExpired) {
      await _tempUserService.deleteTempUserData();
    }
  }

  /// Get the route for a specific onboarding step
  String _getRouteForStep(int step) {
    switch (step) {
      case 0:
        return '/onboarding/goal-creation';
      case 1:
        return '/onboarding/demo-timer';
      case 2:
        return '/onboarding/account-promotion';
      default:
        return '/onboarding/goal-creation';
    }
  }

  /// Check if user is authenticated
  Future<bool> _isUserAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_authenticated') ?? false;
  }

  /// Get user authentication state
  Future<bool> isUserAuthenticated() async {
    return await _isUserAuthenticated();
  }

  /// Get current user type (guest, free, premium)
  Future<String> getUserType() async {
    if (await _isUserAuthenticated()) {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool('is_premium') ?? false;
      return isPremium ? 'premium' : 'free';
    }

    // Check if user has completed onboarding as guest
    final tempUserId = await _tempUserService.getTempUserId();
    if (tempUserId != null && !await _tempUserService.isTempUserExpired()) {
      final step = await _tempUserService.getOnboardingStep();
      if (step >= 3) {
        return 'guest';
      }
    }

    return 'unknown';
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    if (await _isUserAuthenticated()) {
      return true;
    }

    final tempUserId = await _tempUserService.getTempUserId();
    if (tempUserId == null || await _tempUserService.isTempUserExpired()) {
      return false;
    }

    final step = await _tempUserService.getOnboardingStep();
    return step >= 3;
  }

  /// Initialize startup state for new users
  Future<void> initializeForNewUser() async {
    await _tempUserService.generateTempUserId();
    await _tempUserService.updateOnboardingStep(0);
  }

  /// Complete onboarding step and update progress
  Future<void> completeOnboardingStep(int step) async {
    await _tempUserService.updateOnboardingStep(step);
  }

  /// Reset onboarding state (for expired users)
  Future<void> resetOnboardingState() async {
    await _tempUserService.deleteTempUserData();
  }
}
