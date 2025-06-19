import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_up_with_email_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_in_with_apple_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/create_user_profile_usecase.dart';

/// 認証状態を管理するViewModel
class AuthViewModel extends StateNotifier<AuthState> {
  final SignInWithEmailUseCase _signInWithEmailUseCase;
  final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInWithAppleUseCase _signInWithAppleUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CreateUserProfileUseCase _createUserProfileUseCase;

  AuthViewModel({
    required SignInWithEmailUseCase signInWithEmailUseCase,
    required SignUpWithEmailUseCase signUpWithEmailUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithAppleUseCase signInWithAppleUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required CreateUserProfileUseCase createUserProfileUseCase,
  }) : _signInWithEmailUseCase = signInWithEmailUseCase,
       _signUpWithEmailUseCase = signUpWithEmailUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _signInWithAppleUseCase = signInWithAppleUseCase,
       _signOutUseCase = signOutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _createUserProfileUseCase = createUserProfileUseCase,
       super(AuthState.initial);

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  /// 初期化
  Future<void> initialize() async {
    state = AuthState.loading;
    try {
      final user = await _getCurrentUserUseCase.call();
      if (user != null) {
        _currentUser = user;
        state = AuthState.authenticated;
      } else {
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      state = AuthState.error;
    }
  }

  /// メールでログイン
  Future<void> signInWithEmail(String email, String password) async {
    state = AuthState.loading;
    try {
      final user = await _signInWithEmailUseCase.call(email, password);
      _currentUser = user;
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  /// メールでサインアップ
  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = AuthState.loading;
    try {
      final user = await _signUpWithEmailUseCase.call(
        email,
        password,
        displayName,
      );
      _currentUser = user;

      // ユーザープロファイルを自動作成
      await _createUserProfileIfNeeded(user);

      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  /// Googleでログイン
  Future<void> signInWithGoogle() async {
    state = AuthState.loading;
    try {
      final user = await _signInWithGoogleUseCase.call();
      _currentUser = user;
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  /// Appleでログイン
  Future<void> signInWithApple() async {
    state = AuthState.loading;
    try {
      final user = await _signInWithAppleUseCase.call();
      _currentUser = user;
      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    state = AuthState.loading;
    try {
      await _signOutUseCase.call();
      _currentUser = null;
      state = AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  /// プロファイルが存在しない場合に自動作成
  Future<void> _createUserProfileIfNeeded(AppUser user) async {
    try {
      await _createUserProfileUseCase.execute(user);
    } catch (e) {
      // プロファイル作成に失敗しても認証は成功として扱う
      // ログにエラーを記録（本番環境では適切なログ機能を使用）
      debugPrint('プロファイル作成に失敗しました: $e');
    }
  }
}
