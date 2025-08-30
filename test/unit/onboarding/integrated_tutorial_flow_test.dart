import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/onboarding/presentation/view_models/tutorial_view_model.dart';
import 'package:goal_timer/features/onboarding/presentation/view_models/onboarding_view_model.dart';
import 'package:goal_timer/core/services/temp_user_service.dart';
import 'package:goal_timer/core/services/startup_logic_service.dart';
import 'package:goal_timer/core/services/data_migration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock implementation of TempUserService for testing
class MockTempUserService extends TempUserService {
  String? _tempUserId;
  int _generateCallCount = 0;
  
  int get generateCallCount => _generateCallCount;
  
  void setTempUserId(String? id) => _tempUserId = id;
  
  @override
  Future<String?> getTempUserId() async => _tempUserId;
  
  @override
  Future<String> generateTempUserId() async {
    _generateCallCount++;
    _tempUserId = 'test_temp_user_${DateTime.now().millisecondsSinceEpoch}';
    return _tempUserId!;
  }
  
  @override
  Future<bool> hasTempUser() async => _tempUserId != null;
  
  @override
  Future<void> deleteTempUserData() async {
    _tempUserId = null;
  }
}

void main() {
  group('Integrated Tutorial Flow Tests', () {
    late ProviderContainer container;
    late MockTempUserService mockTempUserService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      mockTempUserService = MockTempUserService();
      container = ProviderContainer(
        overrides: [
          tempUserServiceProvider.overrideWithValue(mockTempUserService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Tutorial Flow After Demo Screen Removal', () {
      test('should start tutorial with 3 steps after goal creation', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);

        // Act
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );

        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.isTutorialActive, true);
        expect(state.totalSteps, 3);
        expect(state.currentStepId, 'home_goal_selection');
        expect(state.currentStepIndex, 0);
      });

      test('should progress from home_goal_selection to home_timer_button_showcase', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );

        // Act
        await tutorialViewModel.nextStep('home_timer_button_showcase');

        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.currentStepId, 'home_timer_button_showcase');
        expect(state.currentStepIndex, 1);
        expect(state.isTutorialActive, true);
      });

      test('should progress from home_timer_button_showcase to timer_operation', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );
        await tutorialViewModel.nextStep('home_timer_button_showcase');

        // Act
        await tutorialViewModel.nextStep('timer_operation');

        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.currentStepId, 'timer_operation');
        expect(state.currentStepIndex, 2);
        expect(state.isTutorialActive, true);
      });

      test('should complete tutorial after timer_operation step', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );
        await tutorialViewModel.nextStep('home_timer_button_showcase');
        await tutorialViewModel.nextStep('timer_operation');

        // Act - この時点で最終ステップなので completeTutorial が呼ばれる
        await tutorialViewModel.nextStep('final_step');

        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.isTutorialActive, false);
        expect(state.isCompleted, true);
      });
    });

    group('Tutorial Step Detection', () {
      test('should correctly identify current tutorial steps', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );

        // Test each step
        expect(tutorialViewModel.isCurrentStep('home_goal_selection'), true);
        expect(tutorialViewModel.isCurrentStep('home_timer_button_showcase'), false);
        expect(tutorialViewModel.isCurrentStep('timer_operation'), false);

        await tutorialViewModel.nextStep('home_timer_button_showcase');
        
        expect(tutorialViewModel.isCurrentStep('home_goal_selection'), false);
        expect(tutorialViewModel.isCurrentStep('home_timer_button_showcase'), true);
        expect(tutorialViewModel.isCurrentStep('timer_operation'), false);

        await tutorialViewModel.nextStep('timer_operation');
        
        expect(tutorialViewModel.isCurrentStep('home_goal_selection'), false);
        expect(tutorialViewModel.isCurrentStep('home_timer_button_showcase'), false);
        expect(tutorialViewModel.isCurrentStep('timer_operation'), true);
      });
    });

    group('Tutorial Skip Functionality', () {
      test('should properly handle tutorial skip and create temp user', () async {
        // Arrange
        mockTempUserService.setTempUserId(null);
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );

        // Act
        await tutorialViewModel.skipTutorial();

        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.isTutorialActive, false);
        expect(state.isCompleted, true);
        expect(mockTempUserService.generateCallCount, 1);
      });
    });

    group('Onboarding Integration', () {
      test('should have 2 onboarding steps after demo timer removal', () async {
        // Arrange
        mockTempUserService.setTempUserId(null);
        
        // Act - オンボーディング初期化は自動的に行われる
        await Future.delayed(const Duration(milliseconds: 100)); // 初期化を待つ

        // Assert
        final state = container.read(onboardingViewModelProvider);
        // オンボーディングは新規フローで開始されるはず
        expect(state.currentStep, 0);
        expect(state.progress, 0.0);
      });

      test('should complete goal creation and move to step 1', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final onboardingViewModel = container.read(onboardingViewModelProvider.notifier);

        // Act
        await onboardingViewModel.completeGoalCreation();

        // Assert
        final state = container.read(onboardingViewModelProvider);
        expect(state.currentStep, 1);
        expect(state.progress, 0.5); // 1/2 = 0.5
      });

      test('should complete account creation and move to step 2', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final onboardingViewModel = container.read(onboardingViewModelProvider.notifier);
        await onboardingViewModel.completeGoalCreation();

        // Act
        await onboardingViewModel.completeAccountCreation();

        // Assert
        final state = container.read(onboardingViewModelProvider);
        expect(state.currentStep, 2);
        expect(state.progress, 1.0); // 2/2 = 1.0
        expect(onboardingViewModel.isOnboardingCompleted, true);
      });
    });
  });
}