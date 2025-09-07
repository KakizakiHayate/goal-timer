import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goal_timer/core/services/temp_user_service.dart';

void main() {
  group('TempUserService', () {
    late TempUserService tempUserService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tempUserService = TempUserService();
    });

    group('generateTempUserId', () {
      test('should generate ID with correct format', () async {
        // Act
        final userId = await tempUserService.generateTempUserId();

        // Assert
        expect(userId, startsWith('local_user_temp_'));
        expect(userId.length, greaterThan(18)); // 'local_user_temp_' + timestamp
      });

      test('should generate unique IDs for consecutive calls', () async {
        // Act
        final userId1 = await tempUserService.generateTempUserId();
        await Future.delayed(const Duration(milliseconds: 1));
        final userId2 = await tempUserService.generateTempUserId();

        // Assert
        expect(userId1, isNot(equals(userId2)));
      });

      test('should store ID in SharedPreferences', () async {
        // Act
        final userId = await tempUserService.generateTempUserId();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('temp_user_id'), equals(userId));
      });

      test('should store creation timestamp', () async {
        // Arrange
        final beforeTimestamp = DateTime.now().millisecondsSinceEpoch;
        
        // Act
        await tempUserService.generateTempUserId();
        
        // Assert
        final prefs = await SharedPreferences.getInstance();
        final storedTimestamp = prefs.getInt('temp_user_created_at');
        final afterTimestamp = DateTime.now().millisecondsSinceEpoch;
        
        expect(storedTimestamp, isNotNull);
        expect(storedTimestamp!, greaterThanOrEqualTo(beforeTimestamp));
        expect(storedTimestamp, lessThanOrEqualTo(afterTimestamp));
      });
    });

    group('getTempUserId', () {
      test('should return null when no temp user exists', () async {
        // Act
        final userId = await tempUserService.getTempUserId();

        // Assert
        expect(userId, isNull);
      });

      test('should return stored temp user ID', () async {
        // Arrange
        const testUserId = 'local_user_temp_123456789';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('temp_user_id', testUserId);

        // Act
        final userId = await tempUserService.getTempUserId();

        // Assert
        expect(userId, equals(testUserId));
      });
    });

    group('isTempUserExpired', () {
      test('should return false for newly created temp user', () async {
        // Arrange
        await tempUserService.generateTempUserId();

        // Act
        final isExpired = await tempUserService.isTempUserExpired();

        // Assert
        expect(isExpired, isFalse);
      });

      test('should return true for 7-day old temp user', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('temp_user_id', 'local_user_temp_123');
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7, hours: 1));
        await prefs.setInt('temp_user_created_at', sevenDaysAgo.millisecondsSinceEpoch);

        // Act
        final isExpired = await tempUserService.isTempUserExpired();

        // Assert
        expect(isExpired, isTrue);
      });

      test('should return false for temp user created 6 days ago', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('temp_user_id', 'local_user_temp_123');
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));
        await prefs.setInt('temp_user_created_at', sixDaysAgo.millisecondsSinceEpoch);

        // Act
        final isExpired = await tempUserService.isTempUserExpired();

        // Assert
        expect(isExpired, isFalse);
      });

      test('should return false when no temp user exists', () async {
        // Act
        final isExpired = await tempUserService.isTempUserExpired();

        // Assert
        expect(isExpired, isFalse);
      });
    });

    group('deleteTempUserData', () {
      test('should remove temp user ID from SharedPreferences', () async {
        // Arrange
        await tempUserService.generateTempUserId();

        // Act
        await tempUserService.deleteTempUserData();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('temp_user_id'), isNull);
        expect(prefs.getInt('temp_user_created_at'), isNull);
      });

      test('should not throw when deleting non-existent temp user', () async {
        // Act & Assert
        expect(() => tempUserService.deleteTempUserData(), returnsNormally);
      });
    });

    group('updateOnboardingStep', () {
      test('should store onboarding step', () async {
        // Arrange
        await tempUserService.generateTempUserId();

        // Act
        await tempUserService.updateOnboardingStep(2);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('temp_onboarding_step'), equals(2));
      });

      test('should overwrite existing onboarding step', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(1);

        // Act
        await tempUserService.updateOnboardingStep(3);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('temp_onboarding_step'), equals(3));
      });
    });

    group('getOnboardingStep', () {
      test('should return 0 when no step is stored', () async {
        // Act
        final step = await tempUserService.getOnboardingStep();

        // Assert
        expect(step, equals(0));
      });

      test('should return stored onboarding step', () async {
        // Arrange
        await tempUserService.generateTempUserId();
        await tempUserService.updateOnboardingStep(2);

        // Act
        final step = await tempUserService.getOnboardingStep();

        // Assert
        expect(step, equals(2));
      });
    });
  });
}