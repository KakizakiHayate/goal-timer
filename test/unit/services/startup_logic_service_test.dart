import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goal_timer/core/services/startup_logic_service.dart';
import 'package:goal_timer/core/services/temp_user_service.dart';

void main() {
  group('StartupLogicService', () {
    late StartupLogicService startupLogicService;
    late TempUserService tempUserService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempUserService = TempUserService();
      startupLogicService = StartupLogicService(tempUserService);
    });

    group('determineInitialRoute', () {
      test('should return onboarding route for first-time user', () async {
        // Act
        final route = await startupLogicService.determineInitialRoute();

        // Assert
        expect(route, equals('/onboarding/goal-creation'));
      });

      test('should return continuation route for existing temp user within 7 days', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(2);

        // Act
        final route = await startupLogicService.determineInitialRoute();

        // Assert
        expect(route, equals('/onboarding/account-promotion'));
      });

      test('should return home route for step 1 (tutorial starts)', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(1);

        // Act
        final route = await startupLogicService.determineInitialRoute();

        // Assert
        expect(route, equals('/home'));
      });

      test('should return account promotion route for step 2', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(2);

        // Act
        final route = await startupLogicService.determineInitialRoute();

        // Assert
        expect(route, equals('/onboarding/account-promotion'));
      });

      test('should clean up and restart onboarding for expired temp user', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('temp_user_id', 'local_user_temp_123');
        final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
        await prefs.setInt('temp_user_created_at', eightDaysAgo.millisecondsSinceEpoch);
        await prefs.setInt('temp_onboarding_step', 2);

        // Act
        final route = await startupLogicService.determineInitialRoute();

        // Assert
        expect(route, equals('/onboarding/goal-creation'));
        expect(prefs.getString('temp_user_id'), isNull);
        expect(prefs.getInt('temp_user_created_at'), isNull);
        expect(prefs.getInt('temp_onboarding_step'), isNull);
      });

      test('should return home route for completed onboarding with authenticated user', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);

        // Act
        final route = await startupLogicService.determineInitialRoute();

        // Assert
        expect(route, equals('/home'));
      });

      test('should return home route for completed onboarding as guest', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(3); // Completed

        // Act
        final route = await startupLogicService.determineInitialRoute();

        // Assert
        expect(route, equals('/home'));
      });
    });

    group('shouldShowOnboarding', () {
      test('should return true for first-time user', () async {
        // Act
        final shouldShow = await startupLogicService.shouldShowOnboarding();

        // Assert
        expect(shouldShow, isTrue);
      });

      test('should return true for existing temp user within 7 days', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(1);

        // Act
        final shouldShow = await startupLogicService.shouldShowOnboarding();

        // Assert
        expect(shouldShow, isTrue);
      });

      test('should return false for authenticated user', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_authenticated', true);

        // Act
        final shouldShow = await startupLogicService.shouldShowOnboarding();

        // Assert
        expect(shouldShow, isFalse);
      });

      test('should return false for completed guest onboarding', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(3);

        // Act
        final shouldShow = await startupLogicService.shouldShowOnboarding();

        // Assert
        expect(shouldShow, isFalse);
      });
    });

    group('getOnboardingProgress', () {
      test('should return 0% for first-time user', () async {
        // Act
        final progress = await startupLogicService.getOnboardingProgress();

        // Assert
        expect(progress, equals(0.0));
      });

      test('should return 33% for step 1 (goal creation completed)', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(1);

        // Act
        final progress = await startupLogicService.getOnboardingProgress();

        // Assert
        expect(progress, equals(0.33));
      });

      test('should return 66% for step 2 (demo timer completed)', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(2);

        // Act
        final progress = await startupLogicService.getOnboardingProgress();

        // Assert
        expect(progress, equals(0.66));
      });

      test('should return 100% for step 3 (account creation completed)', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(3);

        // Act
        final progress = await startupLogicService.getOnboardingProgress();

        // Assert
        expect(progress, equals(1.0));
      });
    });

    group('cleanupExpiredTempData', () {
      test('should delete expired temp user data', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('temp_user_id', 'local_user_temp_123');
        final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
        await prefs.setInt('temp_user_created_at', eightDaysAgo.millisecondsSinceEpoch);
        await prefs.setInt('temp_onboarding_step', 2);

        // Act
        await startupLogicService.cleanupExpiredTempData();

        // Assert
        expect(prefs.getString('temp_user_id'), isNull);
        expect(prefs.getInt('temp_user_created_at'), isNull);
        expect(prefs.getInt('temp_onboarding_step'), isNull);
      });

      test('should not delete valid temp user data', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(1);
        final userId = await tempUserService.getTempUserId();

        // Act
        await startupLogicService.cleanupExpiredTempData();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('temp_user_id'), equals(userId));
        expect(prefs.getInt('temp_onboarding_step'), equals(1));
      });

      test('should handle case when no temp data exists', () async {
        // Act & Assert
        expect(() => startupLogicService.cleanupExpiredTempData(), returnsNormally);
      });
    });
  });
}