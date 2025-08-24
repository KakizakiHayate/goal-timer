import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/features/auth/domain/entities/auth_state.dart';
import 'package:goal_timer/features/auth/presentation/view_models/auth_view_model.dart';
import '../../mocks/mock_auth_dependencies.dart';

void main() {
  group('AuthViewModel Tests', () {
    late AuthViewModel authViewModel;
    late MockAuthDependencies mockDeps;

    setUp(() {
      mockDeps = MockAuthDependencies();
      authViewModel = AuthViewModel(
        signInWithEmailUseCase: mockDeps.signInWithEmailUseCase,
        signUpWithEmailUseCase: mockDeps.signUpWithEmailUseCase,
        signInWithGoogleUseCase: mockDeps.signInWithGoogleUseCase,
        signInWithAppleUseCase: mockDeps.signInWithAppleUseCase,
        signOutUseCase: mockDeps.signOutUseCase,
        getCurrentUserUseCase: mockDeps.getCurrentUserUseCase,
        createUserProfileUseCase: mockDeps.createUserProfileUseCase,
        syncChecker: mockDeps.syncChecker,
      );
    });

    group('Initial State', () {
      test('should start with initial state', () {
        expect(authViewModel.state, AuthState.initial);
        expect(authViewModel.currentUser, null);
      });
    });

    group('Guest State Management', () {
      test('setGuestState should set state to guest and clear current user', () {
        // Act
        authViewModel.setGuestState();

        // Assert
        expect(authViewModel.state, AuthState.guest);
        expect(authViewModel.currentUser, null);
      });

      test('resetToInitial should reset state to initial and clear current user', () {
        // Arrange: Set to guest first
        authViewModel.setGuestState();
        expect(authViewModel.state, AuthState.guest);

        // Act
        authViewModel.resetToInitial();

        // Assert
        expect(authViewModel.state, AuthState.initial);
        expect(authViewModel.currentUser, null);
      });
    });

    group('State Transitions', () {
      test('should transition from initial to guest state', () {
        expect(authViewModel.state, AuthState.initial);
        
        authViewModel.setGuestState();
        
        expect(authViewModel.state, AuthState.guest);
      });

      test('should transition from guest to initial state', () {
        authViewModel.setGuestState();
        expect(authViewModel.state, AuthState.guest);
        
        authViewModel.resetToInitial();
        
        expect(authViewModel.state, AuthState.initial);
      });

      test('should be able to set guest state multiple times', () {
        authViewModel.setGuestState();
        expect(authViewModel.state, AuthState.guest);
        
        authViewModel.setGuestState();
        expect(authViewModel.state, AuthState.guest);
      });

      test('should be able to reset to initial multiple times', () {
        authViewModel.resetToInitial();
        expect(authViewModel.state, AuthState.initial);
        
        authViewModel.resetToInitial();
        expect(authViewModel.state, AuthState.initial);
      });
    });

    group('Guest State Properties', () {
      test('guest state should allow app usage', () {
        authViewModel.setGuestState();
        expect(authViewModel.state.canUseApp, true);
      });

      test('guest state should not need onboarding', () {
        authViewModel.setGuestState();
        expect(authViewModel.state.needsOnboarding, false);
      });

      test('guest state should not be authenticated', () {
        authViewModel.setGuestState();
        expect(authViewModel.state.isAuthenticated, false);
        expect(authViewModel.state.isGuest, true);
      });
    });
  });
}