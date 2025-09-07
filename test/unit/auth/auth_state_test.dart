import 'package:flutter_test/flutter_test.dart';
import 'package:goal_timer/features/auth/domain/entities/auth_state.dart';

void main() {
  group('AuthState Tests', () {
    group('AuthState enum', () {
      test('should have all expected states', () {
        expect(AuthState.values, [
          AuthState.initial,
          AuthState.loading,
          AuthState.authenticated,
          AuthState.guest,
          AuthState.unauthenticated,
          AuthState.error,
        ]);
      });
    });

    group('AuthStateX extension methods', () {
      test('isAuthenticated should return true only for authenticated state', () {
        expect(AuthState.authenticated.isAuthenticated, true);
        expect(AuthState.guest.isAuthenticated, false);
        expect(AuthState.unauthenticated.isAuthenticated, false);
        expect(AuthState.initial.isAuthenticated, false);
        expect(AuthState.loading.isAuthenticated, false);
        expect(AuthState.error.isAuthenticated, false);
      });

      test('isGuest should return true only for guest state', () {
        expect(AuthState.guest.isGuest, true);
        expect(AuthState.authenticated.isGuest, false);
        expect(AuthState.unauthenticated.isGuest, false);
        expect(AuthState.initial.isGuest, false);
        expect(AuthState.loading.isGuest, false);
        expect(AuthState.error.isGuest, false);
      });

      test('isUnauthenticated should return true only for unauthenticated state', () {
        expect(AuthState.unauthenticated.isUnauthenticated, true);
        expect(AuthState.authenticated.isUnauthenticated, false);
        expect(AuthState.guest.isUnauthenticated, false);
        expect(AuthState.initial.isUnauthenticated, false);
        expect(AuthState.loading.isUnauthenticated, false);
        expect(AuthState.error.isUnauthenticated, false);
      });

      test('isLoading should return true only for loading state', () {
        expect(AuthState.loading.isLoading, true);
        expect(AuthState.authenticated.isLoading, false);
        expect(AuthState.guest.isLoading, false);
        expect(AuthState.unauthenticated.isLoading, false);
        expect(AuthState.initial.isLoading, false);
        expect(AuthState.error.isLoading, false);
      });

      test('isError should return true only for error state', () {
        expect(AuthState.error.isError, true);
        expect(AuthState.authenticated.isError, false);
        expect(AuthState.guest.isError, false);
        expect(AuthState.unauthenticated.isError, false);
        expect(AuthState.initial.isError, false);
        expect(AuthState.loading.isError, false);
      });

      test('canUseApp should return true for authenticated and guest states', () {
        expect(AuthState.authenticated.canUseApp, true);
        expect(AuthState.guest.canUseApp, true);
        expect(AuthState.unauthenticated.canUseApp, false);
        expect(AuthState.initial.canUseApp, false);
        expect(AuthState.loading.canUseApp, false);
        expect(AuthState.error.canUseApp, false);
      });

      test('needsOnboarding should return true for initial and unauthenticated states', () {
        expect(AuthState.initial.needsOnboarding, true);
        expect(AuthState.unauthenticated.needsOnboarding, true);
        expect(AuthState.authenticated.needsOnboarding, false);
        expect(AuthState.guest.needsOnboarding, false);
        expect(AuthState.loading.needsOnboarding, false);
        expect(AuthState.error.needsOnboarding, false);
      });
    });
  });
}