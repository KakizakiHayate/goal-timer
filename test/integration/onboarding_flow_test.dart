import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/features/auth/domain/entities/auth_state.dart';
import 'package:goal_timer/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:goal_timer/core/services/startup_logic_service.dart';
import 'package:goal_timer/core/services/temp_user_service.dart';
import '../mocks/mock_auth_dependencies.dart';

void main() {
  group('Onboarding Flow Integration Tests', () {
    late MockAuthDependencies mockDeps;

    setUp(() {
      mockDeps = MockAuthDependencies();
    });

    testWidgets('Complete onboarding flow should set guest state', (WidgetTester tester) async {
      final authViewModel = AuthViewModel(
        signInWithEmailUseCase: mockDeps.signInWithEmailUseCase,
        signUpWithEmailUseCase: mockDeps.signUpWithEmailUseCase,
        signInWithGoogleUseCase: mockDeps.signInWithGoogleUseCase,
        signInWithAppleUseCase: mockDeps.signInWithAppleUseCase,
        signOutUseCase: mockDeps.signOutUseCase,
        getCurrentUserUseCase: mockDeps.getCurrentUserUseCase,
        createUserProfileUseCase: mockDeps.createUserProfileUseCase,
        syncChecker: mockDeps.syncChecker,
      );

      expect(authViewModel.state, AuthState.initial);

      authViewModel.setGuestState();

      expect(authViewModel.state, AuthState.guest);
      expect(authViewModel.state.canUseApp, true);
      expect(authViewModel.state.isGuest, true);
      expect(authViewModel.state.needsOnboarding, false);
    });

    testWidgets('Guest state should allow access to home screen features', (WidgetTester tester) async {
      final authViewModel = AuthViewModel(
        signInWithEmailUseCase: mockDeps.signInWithEmailUseCase,
        signUpWithEmailUseCase: mockDeps.signUpWithEmailUseCase,
        signInWithGoogleUseCase: mockDeps.signInWithGoogleUseCase,
        signInWithAppleUseCase: mockDeps.signInWithAppleUseCase,
        signOutUseCase: mockDeps.signOutUseCase,
        getCurrentUserUseCase: mockDeps.getCurrentUserUseCase,
        createUserProfileUseCase: mockDeps.createUserProfileUseCase,
        syncChecker: mockDeps.syncChecker,
      );

      authViewModel.setGuestState();

      expect(authViewModel.state, AuthState.guest);
      expect(authViewModel.state.canUseApp, true);
      expect(authViewModel.state.isGuest, true);
      expect(authViewModel.state.needsOnboarding, false);
    });

    testWidgets('Initial state should require onboarding', (WidgetTester tester) async {
      final authViewModel = AuthViewModel(
        signInWithEmailUseCase: mockDeps.signInWithEmailUseCase,
        signUpWithEmailUseCase: mockDeps.signUpWithEmailUseCase,
        signInWithGoogleUseCase: mockDeps.signInWithGoogleUseCase,
        signInWithAppleUseCase: mockDeps.signInWithAppleUseCase,
        signOutUseCase: mockDeps.signOutUseCase,
        getCurrentUserUseCase: mockDeps.getCurrentUserUseCase,
        createUserProfileUseCase: mockDeps.createUserProfileUseCase,
        syncChecker: mockDeps.syncChecker,
      );

      expect(authViewModel.state, AuthState.initial);
      expect(authViewModel.state.needsOnboarding, true);
      expect(authViewModel.state.canUseApp, false);
    });

    testWidgets('Guest state can be reset to initial', (WidgetTester tester) async {
      final authViewModel = AuthViewModel(
        signInWithEmailUseCase: mockDeps.signInWithEmailUseCase,
        signUpWithEmailUseCase: mockDeps.signUpWithEmailUseCase,
        signInWithGoogleUseCase: mockDeps.signInWithGoogleUseCase,
        signInWithAppleUseCase: mockDeps.signInWithAppleUseCase,
        signOutUseCase: mockDeps.signOutUseCase,
        getCurrentUserUseCase: mockDeps.getCurrentUserUseCase,
        createUserProfileUseCase: mockDeps.createUserProfileUseCase,
        syncChecker: mockDeps.syncChecker,
      );

      authViewModel.setGuestState();
      expect(authViewModel.state, AuthState.guest);

      authViewModel.resetToInitial();
      expect(authViewModel.state, AuthState.initial);
      expect(authViewModel.state.needsOnboarding, true);
    });

    testWidgets('AuthState transitions work correctly', (WidgetTester tester) async {
      final authViewModel = AuthViewModel(
        signInWithEmailUseCase: mockDeps.signInWithEmailUseCase,
        signUpWithEmailUseCase: mockDeps.signUpWithEmailUseCase,
        signInWithGoogleUseCase: mockDeps.signInWithGoogleUseCase,
        signInWithAppleUseCase: mockDeps.signInWithAppleUseCase,
        signOutUseCase: mockDeps.signOutUseCase,
        getCurrentUserUseCase: mockDeps.getCurrentUserUseCase,
        createUserProfileUseCase: mockDeps.createUserProfileUseCase,
        syncChecker: mockDeps.syncChecker,
      );

      expect(authViewModel.state, AuthState.initial);
      
      authViewModel.setGuestState();
      expect(authViewModel.state, AuthState.guest);
      
      authViewModel.resetToInitial();
      expect(authViewModel.state, AuthState.initial);

      authViewModel.setGuestState();
      authViewModel.setGuestState();
      expect(authViewModel.state, AuthState.guest);

      authViewModel.resetToInitial();
      authViewModel.resetToInitial();
      expect(authViewModel.state, AuthState.initial);
    });

    testWidgets('AuthState business logic methods work correctly', (WidgetTester tester) async {
      expect(AuthState.initial.canUseApp, false);
      expect(AuthState.loading.canUseApp, false);
      expect(AuthState.authenticated.canUseApp, true);
      expect(AuthState.guest.canUseApp, true);
      expect(AuthState.unauthenticated.canUseApp, false);
      expect(AuthState.error.canUseApp, false);

      expect(AuthState.initial.needsOnboarding, true);
      expect(AuthState.loading.needsOnboarding, false);
      expect(AuthState.authenticated.needsOnboarding, false);
      expect(AuthState.guest.needsOnboarding, false);
      expect(AuthState.unauthenticated.needsOnboarding, true);
      expect(AuthState.error.needsOnboarding, false);
    });
  });

  group('StartupLogicService Integration Tests', () {
    late StartupLogicService startupService;
    late TempUserService tempUserService;

    setUp(() {
      tempUserService = TempUserService();
      startupService = StartupLogicService(tempUserService);
    });

    test('should determine correct initial route for new user', () async {
      final route = await startupService.determineInitialRoute();
      expect(route, '/onboarding/goal-creation');
    });

    test('should show onboarding for new users', () async {
      final shouldShow = await startupService.shouldShowOnboarding();
      expect(shouldShow, true);
    });

    test('should return correct onboarding progress', () async {
      var progress = await startupService.getOnboardingProgress();
      expect(progress, 0.0);
    });

    test('should indicate user type correctly', () async {
      final userType = await startupService.getUserType();
      expect(userType, 'unknown');
    });

    test('should handle onboarding completion', () async {
      await startupService.initializeForNewUser();
      await startupService.completeOnboardingStep(3);
      
      final hasCompleted = await startupService.hasCompletedOnboarding();
      expect(hasCompleted, true);
      
      final progress = await startupService.getOnboardingProgress();
      expect(progress, 1.0);
    });

    test('should handle onboarding step progression', () async {
      await startupService.initializeForNewUser();
      
      var progress = await startupService.getOnboardingProgress();
      expect(progress, 0.0);
      
      await startupService.completeOnboardingStep(1);
      progress = await startupService.getOnboardingProgress();
      expect(progress, closeTo(0.33, 0.01));
      
      await startupService.completeOnboardingStep(2);
      progress = await startupService.getOnboardingProgress();
      expect(progress, closeTo(0.66, 0.01));
      
      await startupService.completeOnboardingStep(3);
      progress = await startupService.getOnboardingProgress();
      expect(progress, 1.0);
    });

    test('should cleanup expired temp data', () async {
      await startupService.cleanupExpiredTempData();
    });

    test('should reset onboarding state', () async {
      await startupService.resetOnboardingState();
    });
  });
}