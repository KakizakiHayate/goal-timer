import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/features/onboarding/presentation/view_models/tutorial_view_model.dart';
import 'package:goal_timer/core/services/temp_user_service.dart';
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
  
  void reset() {
    _tempUserId = null;
    _generateCallCount = 0;
  }
}

void main() {
  group('TutorialViewModel Tests', () {
    late TutorialViewModel tutorialViewModel;
    late MockTempUserService mockTempUserService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      mockTempUserService = MockTempUserService();
      tutorialViewModel = TutorialViewModel(mockTempUserService);
    });

    tearDown(() {
      mockTempUserService.reset();
    });

    group('completeTutorial()', () {
      test('should create temp user when none exists', () async {
        // Arrange
        expect(await mockTempUserService.hasTempUser(), isFalse);
        
        // Act
        await tutorialViewModel.completeTutorial();
        
        // Assert
        expect(await mockTempUserService.hasTempUser(), isTrue);
        expect(await mockTempUserService.getTempUserId(), isNotNull);
        expect(mockTempUserService.generateCallCount, equals(1));
        expect(tutorialViewModel.state.isCompleted, isTrue);
        expect(tutorialViewModel.state.isTutorialActive, isFalse);
      });

      test('should not create new temp user when one already exists', () async {
        // Arrange
        mockTempUserService.setTempUserId('existing_temp_user_123');
        expect(await mockTempUserService.hasTempUser(), isTrue);
        
        // Act
        await tutorialViewModel.completeTutorial();
        
        // Assert
        expect(await mockTempUserService.getTempUserId(), equals('existing_temp_user_123'));
        expect(mockTempUserService.generateCallCount, equals(0)); // Should not generate new user
        expect(tutorialViewModel.state.isCompleted, isTrue);
        expect(tutorialViewModel.state.isTutorialActive, isFalse);
      });
    });

    group('skipTutorial()', () {
      test('should create temp user when skipping tutorial and none exists', () async {
        // Arrange
        expect(await mockTempUserService.hasTempUser(), isFalse);
        
        // Act
        await tutorialViewModel.skipTutorial();
        
        // Assert
        expect(await mockTempUserService.hasTempUser(), isTrue);
        expect(await mockTempUserService.getTempUserId(), isNotNull);
        expect(mockTempUserService.generateCallCount, equals(1));
        expect(tutorialViewModel.state.isCompleted, isTrue);
        expect(tutorialViewModel.state.isTutorialActive, isFalse);
      });

      test('should not create new temp user when one exists and skipping', () async {
        // Arrange
        mockTempUserService.setTempUserId('existing_temp_user_456');
        expect(await mockTempUserService.hasTempUser(), isTrue);
        
        // Act
        await tutorialViewModel.skipTutorial();
        
        // Assert
        expect(await mockTempUserService.getTempUserId(), equals('existing_temp_user_456'));
        expect(mockTempUserService.generateCallCount, equals(0));
        expect(tutorialViewModel.state.isCompleted, isTrue);
        expect(tutorialViewModel.state.isTutorialActive, isFalse);
      });
    });

    group('nextStep()', () {
      test('should advance to next step when not at last step', () async {
        // Arrange
        await tutorialViewModel.startTutorial(
          tempUserId: 'test_temp_user_123',
          totalSteps: 3,
        );
        expect(tutorialViewModel.state.currentStepIndex, equals(0));
        
        // Act
        await tutorialViewModel.nextStep('step_1');
        
        // Assert
        expect(tutorialViewModel.state.currentStepIndex, equals(1));
        expect(tutorialViewModel.state.currentStepId, equals('step_1'));
        expect(tutorialViewModel.state.isCompleted, isFalse);
      });

      test('should complete tutorial when advancing from last step', () async {
        // Arrange
        await tutorialViewModel.startTutorial(
          tempUserId: 'test_temp_user_123',
          totalSteps: 3,
        );
        // Move to the second step (index 1)
        await tutorialViewModel.nextStep('step_1');
        expect(tutorialViewModel.state.currentStepIndex, equals(1));
        
        // Act - Move to what would be step 3 (completing the tutorial since totalSteps is 3)
        await tutorialViewModel.nextStep('step_2');
        
        // Assert
        expect(tutorialViewModel.state.currentStepIndex, equals(2));
        // After another nextStep, it should complete
        await tutorialViewModel.nextStep('step_3');
        expect(tutorialViewModel.state.isCompleted, isTrue);
        expect(tutorialViewModel.state.isTutorialActive, isFalse);
        expect(await mockTempUserService.hasTempUser(), isTrue);
      });
    });

    group('startTutorial()', () {
      test('should initialize tutorial state correctly', () async {
        // Act
        await tutorialViewModel.startTutorial(
          tempUserId: 'test_temp_user_123',
          totalSteps: 3,
        );
        
        // Assert
        expect(tutorialViewModel.state.isTutorialActive, isTrue);
        expect(tutorialViewModel.state.currentStepIndex, equals(0));
        expect(tutorialViewModel.state.totalSteps, equals(3));
        expect(tutorialViewModel.state.tempUserId, equals('test_temp_user_123'));
        expect(tutorialViewModel.state.isCompleted, isFalse);
      });
    });

    group('resetTutorial()', () {
      test('should reset tutorial to initial state', () async {
        // Arrange
        await tutorialViewModel.startTutorial(
          tempUserId: 'test_temp_user_123',
          totalSteps: 3,
        );
        await tutorialViewModel.nextStep('step_1');
        expect(tutorialViewModel.state.currentStepIndex, equals(1));
        
        // Act
        tutorialViewModel.resetTutorial();
        
        // Assert
        expect(tutorialViewModel.state.isTutorialActive, isFalse);
        expect(tutorialViewModel.state.currentStepIndex, equals(0));
        expect(tutorialViewModel.state.isCompleted, isFalse);
        expect(tutorialViewModel.state.currentStepId, equals(''));
      });
    });

    group('isCurrentStep()', () {
      test('should return true for current step when tutorial is active', () async {
        // Arrange
        await tutorialViewModel.startTutorial(
          tempUserId: 'test_temp_user_123',
          totalSteps: 3,
        );
        tutorialViewModel.state = tutorialViewModel.state.copyWith(
          currentStepId: 'test_step',
        );
        
        // Assert
        expect(tutorialViewModel.isCurrentStep('test_step'), isTrue);
        expect(tutorialViewModel.isCurrentStep('other_step'), isFalse);
      });

      test('should return false when tutorial is not active', () {
        // Arrange
        tutorialViewModel.state = tutorialViewModel.state.copyWith(
          isTutorialActive: false,
          currentStepId: 'test_step',
        );
        
        // Assert
        expect(tutorialViewModel.isCurrentStep('test_step'), isFalse);
      });
    });
  });
}