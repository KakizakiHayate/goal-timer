import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/features/auth/domain/entities/auth_state.dart';
import 'package:goal_timer/features/auth/presentation/view_models/auth_view_model.dart';
import '../mocks/mock_auth_dependencies.dart';

void main() {
  group('Screen Navigation Widget Tests', () {
    late MockAuthDependencies mockDeps;

    setUp(() {
      mockDeps = MockAuthDependencies();
    });

    testWidgets('AuthState transitions should affect UI rendering', (WidgetTester tester) async {
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
      expect(authViewModel.state.canUseApp, false);

      authViewModel.setGuestState();
      expect(authViewModel.state, AuthState.guest);
      expect(authViewModel.state.canUseApp, true);

      authViewModel.resetToInitial();
      expect(authViewModel.state, AuthState.initial);
      expect(authViewModel.state.canUseApp, false);
    });

    testWidgets('AuthState guest should have correct properties', (WidgetTester tester) async {
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

      expect(authViewModel.state.isGuest, true);
      expect(authViewModel.state.isAuthenticated, false);
      expect(authViewModel.state.canUseApp, true);
      expect(authViewModel.state.needsOnboarding, false);
    });

    testWidgets('AuthState initial should have correct properties', (WidgetTester tester) async {
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

      expect(authViewModel.state == AuthState.initial, true);
      expect(authViewModel.state.isGuest, false);
      expect(authViewModel.state.isAuthenticated, false);
      expect(authViewModel.state.canUseApp, false);
      expect(authViewModel.state.needsOnboarding, true);
    });

    testWidgets('AuthState extension methods work correctly', (WidgetTester tester) async {
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

      expect(AuthState.initial.isGuest, false);
      expect(AuthState.loading.isGuest, false);
      expect(AuthState.authenticated.isGuest, false);
      expect(AuthState.guest.isGuest, true);
      expect(AuthState.unauthenticated.isGuest, false);
      expect(AuthState.error.isGuest, false);

      expect(AuthState.initial.isAuthenticated, false);
      expect(AuthState.loading.isAuthenticated, false);
      expect(AuthState.authenticated.isAuthenticated, true);
      expect(AuthState.guest.isAuthenticated, false);
      expect(AuthState.unauthenticated.isAuthenticated, false);
      expect(AuthState.error.isAuthenticated, false);
    });

    testWidgets('Multiple state transitions should work correctly', (WidgetTester tester) async {
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

    testWidgets('AuthViewModel currentUser should be null for guest state', (WidgetTester tester) async {
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

      expect(authViewModel.currentUser, null);

      authViewModel.setGuestState();
      expect(authViewModel.currentUser, null);

      authViewModel.resetToInitial();
      expect(authViewModel.currentUser, null);
    });
  });
}