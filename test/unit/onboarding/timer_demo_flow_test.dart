import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/features/onboarding/presentation/view_models/tutorial_view_model.dart';
import 'package:goal_timer/features/onboarding/presentation/view_models/onboarding_view_model.dart';
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
}

void main() {
  group('Timer Demo Flow Tests', () {
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

    group('Tutorial Step Progression', () {
      test('should start with home_goal_selection and progress to home_timer_button_showcase', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);

        // Act - チュートリアル開始
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );
        
        // Assert - 初期ステップ確認
        var state = container.read(tutorialViewModelProvider);
        expect(state.isTutorialActive, true);
        expect(state.currentStepId, 'home_goal_selection');
        expect(state.currentStepIndex, 0);
        
        // Act - 次のステップへ進む（ゴール作成完了後）
        await tutorialViewModel.nextStep('home_timer_button_showcase');
        
        // Assert - タイマーボタンshowcaseステップ確認
        state = container.read(tutorialViewModelProvider);
        expect(state.isTutorialActive, true);
        expect(state.currentStepId, 'home_timer_button_showcase');
        expect(state.currentStepIndex, 1);
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
        
        // Act - タイマーボタン押下後、timer_operationへ
        await tutorialViewModel.nextStep('timer_operation');
        
        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.isTutorialActive, true);
        expect(state.currentStepId, 'timer_operation');
        expect(state.currentStepIndex, 2);
      });

      test('should complete tutorial after timer demo', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );
        await tutorialViewModel.nextStep('home_timer_button_showcase');
        await tutorialViewModel.nextStep('timer_operation');
        
        // Act - タイマーデモ完了後
        await tutorialViewModel.completeTutorial();
        
        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.isTutorialActive, false);
        expect(state.isCompleted, true);
      });
    });

    group('Timer Button Showcase Step', () {
      test('should be active when currentStepId is home_timer_button_showcase', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );
        
        // Act - タイマーボタンshowcaseステップへ進む
        await tutorialViewModel.nextStep('home_timer_button_showcase');
        
        // Assert
        final isTimerButtonShowcase = tutorialViewModel.isCurrentStep('home_timer_button_showcase');
        expect(isTimerButtonShowcase, true);
        
        final isOtherStep = tutorialViewModel.isCurrentStep('home_goal_selection');
        expect(isOtherStep, false);
      });

      test('should activate timer tutorial mode when transitioning to timer screen', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );
        await tutorialViewModel.nextStep('home_timer_button_showcase');
        
        // Assert - タイマーボタンshowcaseが有効
        var state = container.read(tutorialViewModelProvider);
        expect(state.isTutorialActive, true);
        expect(state.currentStepId, 'home_timer_button_showcase');
        
        // タイマー画面遷移時のチュートリアルモード判定
        final shouldUseTutorialMode = 
            state.isTutorialActive && 
            state.currentStepId == 'home_timer_button_showcase';
        expect(shouldUseTutorialMode, true);
        
        // Act - タイマー画面へ遷移後、次のステップへ
        await tutorialViewModel.nextStep('timer_operation');
        
        // Assert - timer_operationステップ確認
        state = container.read(tutorialViewModelProvider);
        expect(state.currentStepId, 'timer_operation');
      });
    });

    group('Step Methods', () {
      test('startTimerButtonShowcaseStep should set correct step ID', () {
        // Arrange
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        
        // Act
        tutorialViewModel.startTimerButtonShowcaseStep();
        
        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.currentStepId, 'home_timer_button_showcase');
      });

      test('startTimerOperationStep should set correct step ID', () {
        // Arrange
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        
        // Act
        tutorialViewModel.startTimerOperationStep();
        
        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.currentStepId, 'timer_operation');
      });
    });

    group('Error Handling', () {
      test('should handle tutorial skip properly during timer demo flow', () async {
        // Arrange
        mockTempUserService.setTempUserId('temp_123');
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        await tutorialViewModel.startTutorial(
          tempUserId: 'temp_123',
          totalSteps: 3,
        );
        await tutorialViewModel.nextStep('home_timer_button_showcase');
        
        // Act - チュートリアルをスキップ
        await tutorialViewModel.skipTutorial();
        
        // Assert
        final state = container.read(tutorialViewModelProvider);
        expect(state.isTutorialActive, false);
        expect(state.isCompleted, true);
      });

      test('should create temp user when completing tutorial without existing user', () async {
        // Arrange
        mockTempUserService.setTempUserId(null);
        
        final tutorialViewModel = container.read(tutorialViewModelProvider.notifier);
        
        // Act
        await tutorialViewModel.completeTutorial();
        
        // Assert
        expect(mockTempUserService.generateCallCount, 1);
        final tempUserId = await mockTempUserService.getTempUserId();
        expect(tempUserId, isNotNull);
        expect(tempUserId, startsWith('test_temp_user_'));
      });
    });
  });
}