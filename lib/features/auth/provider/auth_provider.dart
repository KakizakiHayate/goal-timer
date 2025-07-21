import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Data Sources
import '../data/datasources/auth_local_datasource.dart';
import '../data/datasources/auth_remote_datasource.dart';

// Repository
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';

// Use Cases
import '../domain/usecases/sign_in_with_email_usecase.dart';
import '../domain/usecases/sign_up_with_email_usecase.dart';
import '../domain/usecases/sign_in_with_google_usecase.dart';
import '../domain/usecases/sign_in_with_apple_usecase.dart';
import '../domain/usecases/sign_out_usecase.dart';
import '../domain/usecases/get_current_user_usecase.dart';
import '../domain/usecases/create_user_profile_usecase.dart';

// ViewModels
import '../presentation/view_models/auth_view_model.dart';

// Entities
import '../domain/entities/app_user.dart';
import '../domain/entities/auth_state.dart';

// Shared providers from core
import '../../../core/provider/providers.dart';

// === 外部依存関係プロバイダー ===

/// GoogleSignInのプロバイダー
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(scopes: ['email', 'profile']);
});

// === Data Source プロバイダー ===

/// ローカル認証データソースのプロバイダー
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});

/// リモート認証データソースのプロバイダー
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final googleSignIn = ref.watch(googleSignInProvider);

  return AuthRemoteDataSourceImpl(supabaseClient, googleSignIn);
});

// === Repository プロバイダー ===

/// 認証リポジトリのプロバイダー
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);

  return AuthRepositoryImpl(localDataSource, remoteDataSource);
});

// === Use Case プロバイダー ===

/// メールログインユースケースのプロバイダー
final signInWithEmailUseCaseProvider = Provider<SignInWithEmailUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmailUseCase(repository);
});

/// メールサインアップユースケースのプロバイダー
final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmailUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpWithEmailUseCase(repository);
});

/// Googleログインユースケースのプロバイダー
final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithGoogleUseCase(repository);
});

/// Appleログインユースケースのプロバイダー
final signInWithAppleUseCaseProvider = Provider<SignInWithAppleUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithAppleUseCase(repository);
});

/// サインアウトユースケースのプロバイダー
final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
});

/// 現在ユーザー取得ユースケースのプロバイダー
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

/// プロファイル作成ユースケースのプロバイダー
final createUserProfileUseCaseProvider = Provider<CreateUserProfileUseCase>((
  ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  final usersRepository = ref.watch(hybridUsersRepositoryProvider);
  return CreateUserProfileUseCase(authRepository, usersRepository);
});

// === ViewModel プロバイダー ===

/// 認証ViewModelのプロバイダー
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  final signInWithEmailUseCase = ref.watch(signInWithEmailUseCaseProvider);
  final signUpWithEmailUseCase = ref.watch(signUpWithEmailUseCaseProvider);
  final signInWithGoogleUseCase = ref.watch(signInWithGoogleUseCaseProvider);
  final signInWithAppleUseCase = ref.watch(signInWithAppleUseCaseProvider);
  final signOutUseCase = ref.watch(signOutUseCaseProvider);
  final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
  final createUserProfileUseCase = ref.watch(createUserProfileUseCaseProvider);
  final syncChecker = ref.watch(syncCheckerProvider);

  return AuthViewModel(
    signInWithEmailUseCase: signInWithEmailUseCase,
    signUpWithEmailUseCase: signUpWithEmailUseCase,
    signInWithGoogleUseCase: signInWithGoogleUseCase,
    signInWithAppleUseCase: signInWithAppleUseCase,
    signOutUseCase: signOutUseCase,
    getCurrentUserUseCase: getCurrentUserUseCase,
    createUserProfileUseCase: createUserProfileUseCase,
    syncChecker: syncChecker,
  );
});

// === 認証状態監視プロバイダー ===

/// 認証状態の変更を監視するStreamProvider
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// 現在のユーザー情報を取得するFutureProvider
final currentUserProvider = FutureProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
});
