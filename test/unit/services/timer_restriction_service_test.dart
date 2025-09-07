import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/core/services/timer_restriction_service.dart';

void main() {
  group('TimerRestrictionService', () {
    late TimerRestrictionService timerRestrictionService;

    setUp(() {
      timerRestrictionService = TimerRestrictionService();
    });

    group('canUseTimerMode', () {
      test('should allow all modes for premium user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('premium');

        // Act & Assert
        expect(timerRestrictionService.canUseTimerMode('normal'), isTrue);
        expect(timerRestrictionService.canUseTimerMode('countdown'), isTrue);
        expect(timerRestrictionService.canUseTimerMode('countup'), isTrue);
        expect(timerRestrictionService.canUseTimerMode('pomodoro'), isTrue);
      });

      test('should restrict pomodoro for guest user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('guest');

        // Act & Assert
        expect(timerRestrictionService.canUseTimerMode('normal'), isTrue);
        expect(timerRestrictionService.canUseTimerMode('countdown'), isTrue);
        expect(timerRestrictionService.canUseTimerMode('countup'), isTrue);
        expect(timerRestrictionService.canUseTimerMode('pomodoro'), isFalse);
      });

      test('should restrict pomodoro for free user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('free');

        // Act & Assert
        expect(timerRestrictionService.canUseTimerMode('normal'), isTrue);
        expect(timerRestrictionService.canUseTimerMode('countdown'), isTrue);
        expect(timerRestrictionService.canUseTimerMode('countup'), isTrue);
        expect(timerRestrictionService.canUseTimerMode('pomodoro'), isFalse);
      });
    });

    group('getAvailableTimerModes', () {
      test('should return all modes for premium user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('premium');

        // Act
        final modes = timerRestrictionService.getAvailableTimerModes();

        // Assert
        expect(modes, containsAll(['normal', 'countdown', 'countup', 'pomodoro']));
        expect(modes.length, equals(4));
      });

      test('should return limited modes for guest user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('guest');

        // Act
        final modes = timerRestrictionService.getAvailableTimerModes();

        // Assert
        expect(modes, containsAll(['normal', 'countdown', 'countup']));
        expect(modes, isNot(contains('pomodoro')));
        expect(modes.length, equals(3));
      });

      test('should return limited modes for free user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('free');

        // Act
        final modes = timerRestrictionService.getAvailableTimerModes();

        // Assert
        expect(modes, containsAll(['normal', 'countdown', 'countup']));
        expect(modes, isNot(contains('pomodoro')));
        expect(modes.length, equals(3));
      });
    });

    group('getRestrictedTimerModes', () {
      test('should return no restrictions for premium user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('premium');

        // Act
        final restrictedModes = timerRestrictionService.getRestrictedTimerModes();

        // Assert
        expect(restrictedModes, isEmpty);
      });

      test('should return pomodoro as restricted for guest user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('guest');

        // Act
        final restrictedModes = timerRestrictionService.getRestrictedTimerModes();

        // Assert
        expect(restrictedModes, contains('pomodoro'));
        expect(restrictedModes.length, equals(1));
      });

      test('should return pomodoro as restricted for free user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('free');

        // Act
        final restrictedModes = timerRestrictionService.getRestrictedTimerModes();

        // Assert
        expect(restrictedModes, contains('pomodoro'));
        expect(restrictedModes.length, equals(1));
      });
    });

    group('getRestrictionMessage', () {
      test('should return empty message for allowed modes', () async {
        // Arrange
        timerRestrictionService.setUserPlan('guest');

        // Act & Assert
        expect(timerRestrictionService.getRestrictionMessage('normal'), isEmpty);
        expect(timerRestrictionService.getRestrictionMessage('countdown'), isEmpty);
        expect(timerRestrictionService.getRestrictionMessage('countup'), isEmpty);
      });

      test('should return premium message for restricted modes', () async {
        // Arrange
        timerRestrictionService.setUserPlan('guest');

        // Act
        final message = timerRestrictionService.getRestrictionMessage('pomodoro');

        // Assert
        expect(message, equals('プレミアムプランで利用可能'));
      });

      test('should return empty message for premium user on all modes', () async {
        // Arrange
        timerRestrictionService.setUserPlan('premium');

        // Act & Assert
        expect(timerRestrictionService.getRestrictionMessage('normal'), isEmpty);
        expect(timerRestrictionService.getRestrictionMessage('countdown'), isEmpty);
        expect(timerRestrictionService.getRestrictionMessage('countup'), isEmpty);
        expect(timerRestrictionService.getRestrictionMessage('pomodoro'), isEmpty);
      });
    });

    group('getCurrentPlan', () {
      test('should return Free for guest user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('guest');

        // Act
        final plan = timerRestrictionService.getCurrentPlan();

        // Assert
        expect(plan, equals('Free'));
      });

      test('should return Free for free user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('free');

        // Act
        final plan = timerRestrictionService.getCurrentPlan();

        // Assert
        expect(plan, equals('Free'));
      });

      test('should return Premium for premium user', () async {
        // Arrange
        timerRestrictionService.setUserPlan('premium');

        // Act
        final plan = timerRestrictionService.getCurrentPlan();

        // Assert
        expect(plan, equals('Premium'));
      });
    });

    group('plan transitions', () {
      test('should handle plan upgrade from guest to premium', () async {
        // Arrange
        timerRestrictionService.setUserPlan('guest');
        expect(timerRestrictionService.canUseTimerMode('pomodoro'), isFalse);

        // Act
        timerRestrictionService.setUserPlan('premium');

        // Assert
        expect(timerRestrictionService.canUseTimerMode('pomodoro'), isTrue);
        expect(timerRestrictionService.getCurrentPlan(), equals('Premium'));
      });

      test('should handle plan downgrade from premium to free', () async {
        // Arrange
        timerRestrictionService.setUserPlan('premium');
        expect(timerRestrictionService.canUseTimerMode('pomodoro'), isTrue);

        // Act
        timerRestrictionService.setUserPlan('free');

        // Assert
        expect(timerRestrictionService.canUseTimerMode('pomodoro'), isFalse);
        expect(timerRestrictionService.getCurrentPlan(), equals('Free'));
      });
    });
  });
}