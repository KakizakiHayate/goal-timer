import 'package:goal_timer/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:goal_timer/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:goal_timer/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:goal_timer/features/auth/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:goal_timer/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:goal_timer/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:goal_timer/features/auth/domain/usecases/create_user_profile_usecase.dart';
import 'package:goal_timer/features/auth/domain/entities/app_user.dart';
import 'package:goal_timer/core/services/sync_checker.dart';
import 'package:goal_timer/core/models/users/users_model.dart';

/// Fake implementation for testing without external dependencies
class FakeSignInWithEmailUseCase implements SignInWithEmailUseCase {
  @override
  Future<AppUser> call(String email, String password) async {
    return AppUser(
      id: 'test-id', 
      email: email, 
      displayName: 'Test User',
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

class FakeSignUpWithEmailUseCase implements SignUpWithEmailUseCase {
  @override
  Future<AppUser> call(String email, String password, String displayName) async {
    return AppUser(
      id: 'test-id', 
      email: email, 
      displayName: displayName,
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

class FakeSignInWithGoogleUseCase implements SignInWithGoogleUseCase {
  @override
  Future<AppUser> call() async {
    return AppUser(
      id: 'test-google-id', 
      email: 'test@gmail.com', 
      displayName: 'Google User',
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

class FakeSignInWithAppleUseCase implements SignInWithAppleUseCase {
  @override
  Future<AppUser> call() async {
    return AppUser(
      id: 'test-apple-id', 
      email: 'test@icloud.com', 
      displayName: 'Apple User',
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

class FakeSignOutUseCase implements SignOutUseCase {
  @override
  Future<void> call() async {
    // Do nothing for test
  }
}

class FakeGetCurrentUserUseCase implements GetCurrentUserUseCase {
  @override
  Future<AppUser?> call() async {
    return null; // No current user for test
  }
}

class FakeCreateUserProfileUseCase implements CreateUserProfileUseCase {
  @override
  Future<UsersModel> execute(AppUser authUser) async {
    return UsersModel(
      id: authUser.id,
      email: authUser.email,
      displayName: authUser.displayName ?? 'Test User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<UsersModel> getOrCreateProfile(AppUser authUser) async {
    return UsersModel(
      id: authUser.id,
      email: authUser.email,
      displayName: authUser.displayName ?? 'Test User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> profileExists(String userId) async {
    return false;
  }
}

class FakeSyncChecker implements SyncChecker {
  @override
  Future<void> checkAndSyncIfNeeded() async {
    // Do nothing for test
  }

  @override
  Future<Map<String, dynamic>> checkDataIntegrity() async {
    return {'status': 'ok'};
  }

  @override
  Future<void> forceFullSync() async {
    // Do nothing for test
  }

  @override
  Future<bool> hasUnsyncedData() async {
    return false;
  }

  @override
  Future<Map<String, dynamic>> getSyncStatus() async {
    return {'status': 'synced'};
  }

  @override
  Future<void> syncUnsyncedData() async {
    // Do nothing for test
  }

  @override
  Future<void> retrySyncWithBackoff() async {
    // Do nothing for test
  }

  void dispose() {
    // Do nothing for test
  }
}

/// Container class for all auth-related fake dependencies
class MockAuthDependencies {
  late final SignInWithEmailUseCase signInWithEmailUseCase;
  late final SignUpWithEmailUseCase signUpWithEmailUseCase;
  late final SignInWithGoogleUseCase signInWithGoogleUseCase;
  late final SignInWithAppleUseCase signInWithAppleUseCase;
  late final SignOutUseCase signOutUseCase;
  late final GetCurrentUserUseCase getCurrentUserUseCase;
  late final CreateUserProfileUseCase createUserProfileUseCase;
  late final SyncChecker syncChecker;

  MockAuthDependencies() {
    signInWithEmailUseCase = FakeSignInWithEmailUseCase();
    signUpWithEmailUseCase = FakeSignUpWithEmailUseCase();
    signInWithGoogleUseCase = FakeSignInWithGoogleUseCase();
    signInWithAppleUseCase = FakeSignInWithAppleUseCase();
    signOutUseCase = FakeSignOutUseCase();
    getCurrentUserUseCase = FakeGetCurrentUserUseCase();
    createUserProfileUseCase = FakeCreateUserProfileUseCase();
    syncChecker = FakeSyncChecker();
  }
}