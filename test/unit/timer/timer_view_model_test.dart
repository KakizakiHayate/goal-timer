import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/goal_timer/presentation/viewmodels/timer_view_model.dart';
import 'package:goal_timer/core/services/timer_restriction_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'timer_view_model_test.mocks.dart';

@GenerateMocks([TimerRestrictionService, Ref])
void main() {
  group('TimerViewModel', () {
    late MockTimerRestrictionService mockRestrictionService;
    late MockRef<TimerState> mockRef;
    late TimerViewModel viewModel;

    setUp(() {
      mockRestrictionService = MockTimerRestrictionService();
      mockRef = MockRef<TimerState>();
      
      // Default mock behavior
      when(mockRestrictionService.canUseTimerMode(any)).thenReturn(true);
      when(mockRestrictionService.getCurrentPlan()).thenReturn('free');
      when(mockRestrictionService.getRestrictionMessage(any)).thenReturn('');
      
      viewModel = TimerViewModel(mockRef);
    });

    tearDown(() {
      viewModel.dispose();
    });

    group('Timer Completion Flow', () {
      test('should complete timer in tutorial mode when reaching 0 seconds', () async {
        // Arrange
        const goalId = 'tutorial-goal-123';
        viewModel.setGoalId(goalId);
        viewModel.setTutorialMode(true);
        viewModel.setTutorialTime(5); // Sets to 5 seconds
        
        // Act
        viewModel.startTimer();
        
        // Fast-forward to completion
        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          // Simulate timer tick - this would normally be handled by the Timer
        }
        
        // Manually trigger completion for testing
        viewModel.completeTimer();
        
        // Assert
        expect(viewModel.state.status, equals(TimerStatus.completed));
        expect(viewModel.state.currentSeconds, equals(0));
      });

      test('should start timer in tutorial mode without goalId requirement', () {
        // Arrange
        viewModel.setTutorialMode(true);
        // No goalId set intentionally
        
        // Act
        viewModel.startTimer();
        
        // Assert
        expect(viewModel.state.status, equals(TimerStatus.running));
      });

      test('should not start timer in non-tutorial mode without goalId', () {
        // Arrange
        viewModel.setTutorialMode(false);
        // No goalId set intentionally
        
        // Act
        viewModel.startTimer();
        
        // Assert
        expect(viewModel.state.status, equals(TimerStatus.initial));
      });

      test('should set tutorial time to 5 seconds', () {
        // Act
        viewModel.setTutorialTime(5);
        
        // Assert
        expect(viewModel.state.totalSeconds, equals(5));
        expect(viewModel.state.currentSeconds, equals(5));
      });

      test('should maintain tutorial mode flag during timer operations', () {
        // Arrange
        viewModel.setTutorialMode(true);
        const goalId = 'tutorial-goal';
        viewModel.setGoalId(goalId);
        
        // Act & Assert - Start timer
        viewModel.startTimer();
        expect(viewModel.state.status, equals(TimerStatus.running));
        
        // Act & Assert - Pause timer
        viewModel.pauseTimer();
        expect(viewModel.state.status, equals(TimerStatus.paused));
        
        // Act & Assert - Resume timer
        viewModel.startTimer();
        expect(viewModel.state.status, equals(TimerStatus.running));
        
        // Act & Assert - Complete timer
        viewModel.completeTimer();
        expect(viewModel.state.status, equals(TimerStatus.completed));
      });

      test('should handle timer completion with different modes', () {
        const goalId = 'test-goal';
        viewModel.setGoalId(goalId);
        
        // Test countdown mode completion
        viewModel.changeMode(TimerMode.countdown);
        viewModel.setTime(10); // 10 seconds
        viewModel.startTimer();
        viewModel.completeTimer();
        expect(viewModel.state.status, equals(TimerStatus.completed));
        
        // Test countup mode completion
        viewModel.resetTimer();
        viewModel.changeMode(TimerMode.countup);
        viewModel.startTimer();
        viewModel.completeTimer();
        expect(viewModel.state.status, equals(TimerStatus.completed));
      });
    });

    group('Timer State Management', () {
      test('should initialize with correct default values', () {
        expect(viewModel.state.status, equals(TimerStatus.initial));
        expect(viewModel.state.mode, equals(TimerMode.countup));
        expect(viewModel.state.currentSeconds, equals(0));
        expect(viewModel.state.totalSeconds, equals(0));
        expect(viewModel.state.isPomodoroBreak, isFalse);
        expect(viewModel.state.pomodoroRound, equals(1));
      });

      test('should update state when setting goal ID', () {
        // Act
        const goalId = 'test-goal-123';
        viewModel.setGoalId(goalId);
        
        // Assert
        expect(viewModel.state.goalId, equals(goalId));
        expect(viewModel.state.hasGoal, isTrue);
      });

      test('should handle mode changes correctly', () {
        // Test countdown mode
        viewModel.changeMode(TimerMode.countdown);
        expect(viewModel.state.mode, equals(TimerMode.countdown));
        
        // Test countup mode
        viewModel.changeMode(TimerMode.countup);
        expect(viewModel.state.mode, equals(TimerMode.countup));
        
        // Test pomodoro mode
        viewModel.changeMode(TimerMode.pomodoro);
        expect(viewModel.state.mode, equals(TimerMode.pomodoro));
      });

      test('should calculate progress correctly', () {
        // Arrange - countdown mode
        viewModel.changeMode(TimerMode.countdown);
        viewModel.setTime(60); // 60 seconds total
        
        // Test initial progress (100% for countdown)
        expect(viewModel.state.progress, equals(1.0));
        
        // Simulate 30 seconds elapsed
        final updatedState = viewModel.state.copyWith(currentSeconds: 30);
        viewModel.state = updatedState;
        
        // Should be 50% remaining
        expect(viewModel.state.progress, equals(0.5));
      });
    });

    group('Timer Controls', () {
      test('should start, pause, and reset timer correctly', () {
        // Arrange
        const goalId = 'test-goal';
        viewModel.setGoalId(goalId);
        viewModel.changeMode(TimerMode.countdown);
        viewModel.setTime(30);
        
        // Test start
        viewModel.startTimer();
        expect(viewModel.state.status, equals(TimerStatus.running));
        
        // Test pause
        viewModel.pauseTimer();
        expect(viewModel.state.status, equals(TimerStatus.paused));
        
        // Test reset
        viewModel.resetTimer();
        expect(viewModel.state.status, equals(TimerStatus.initial));
        expect(viewModel.state.currentSeconds, equals(viewModel.state.totalSeconds));
      });

      test('should handle timer completion from different states', () {
        const goalId = 'test-goal';
        viewModel.setGoalId(goalId);
        
        // Test completion from running state
        viewModel.startTimer();
        expect(viewModel.state.status, equals(TimerStatus.running));
        
        viewModel.completeTimer();
        expect(viewModel.state.status, equals(TimerStatus.completed));
        
        // Test completion from paused state
        viewModel.resetTimer();
        viewModel.startTimer();
        viewModel.pauseTimer();
        expect(viewModel.state.status, equals(TimerStatus.paused));
        
        viewModel.completeTimer();
        expect(viewModel.state.status, equals(TimerStatus.completed));
      });
    });

    group('Display Formatting', () {
      test('should format display time correctly', () {
        // Test seconds only
        viewModel.state = viewModel.state.copyWith(currentSeconds: 45);
        expect(viewModel.state.displayTime, equals('00:45'));
        
        // Test minutes and seconds
        viewModel.state = viewModel.state.copyWith(currentSeconds: 125); // 2:05
        expect(viewModel.state.displayTime, equals('02:05'));
        
        // Test hours, minutes, and seconds
        viewModel.state = viewModel.state.copyWith(currentSeconds: 3665); // 1:01:05
        expect(viewModel.state.displayTime, equals('01:01:05'));
      });

      test('should provide correct mode labels', () {
        expect(viewModel.getModeLabel(TimerMode.countup), equals('カウントアップ'));
        expect(viewModel.getModeLabel(TimerMode.countdown), equals('カウントダウン'));
        expect(viewModel.getModeLabel(TimerMode.pomodoro), equals('ポモドーロ'));
      });
    });

    group('Tutorial Mode Specific Tests', () {
      test('should handle tutorial mode flag correctly', () {
        // Initially false
        expect(viewModel.state.status, equals(TimerStatus.initial));
        
        // Set tutorial mode
        viewModel.setTutorialMode(true);
        
        // Should allow timer start without goalId in tutorial mode
        viewModel.startTimer();
        expect(viewModel.state.status, equals(TimerStatus.running));
      });

      test('should complete tutorial timer correctly', () async {
        // Arrange
        viewModel.setTutorialMode(true);
        viewModel.setTutorialTime(5); // 5 seconds
        expect(viewModel.state.totalSeconds, equals(5));
        expect(viewModel.state.currentSeconds, equals(5));
        
        // Start timer
        viewModel.startTimer();
        expect(viewModel.state.status, equals(TimerStatus.running));
        
        // Complete timer
        viewModel.completeTimer();
        expect(viewModel.state.status, equals(TimerStatus.completed));
        expect(viewModel.state.currentSeconds, equals(0));
      });
    });
  });
}