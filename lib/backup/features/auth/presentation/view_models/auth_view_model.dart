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
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/sync_checker.dart';
import '../../../../core/services/temp_user_service.dart';
import '../../../../core/services/data_migration_service.dart';

/// 認証状態を管理するViewModel
class AuthViewModel extends StateNotifier<AuthState> {
  final SignInWithEmailUseCase _signInWithEmailUseCase;
  final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignInWithAppleUseCase _signInWithAppleUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final CreateUserProfileUseCase _createUserProfileUseCase;
  final SyncChecker _syncChecker;

  AuthViewModel({
    required SignInWithEmailUseCase signInWithEmailUseCase,
    required SignUpWithEmailUseCase signUpWithEmailUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignInWithAppleUseCase signInWithAppleUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required CreateUserProfileUseCase createUserProfileUseCase,
    required SyncChecker syncChecker,
  }) : _signInWithEmailUseCase = signInWithEmailUseCase,
       _signUpWithEmailUseCase = signUpWithEmailUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _signInWithAppleUseCase = signInWithAppleUseCase,
       _signOutUseCase = signOutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _createUserProfileUseCase = createUserProfileUseCase,
       _syncChecker = syncChecker,
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

        // 認証完了後に同期チェックを実行
        AppLogger.instance.i('認証完了後の同期チェックを開始します');
        await _syncChecker.checkAndSyncIfNeeded();
      } else {
        // tempユーザーの存在チェックを追加
        final tempUserService = TempUserService();
        final hasTempUser = await tempUserService.hasTempUser();

        if (hasTempUser) {
          // tempユーザーが存在する = チュートリアル完了済み
          AppLogger.instance.i('TempUserが存在します。ゲスト状態に設定します');
          state = AuthState.guest;
        } else {
          // tempユーザーがいない = 初回起動
          AppLogger.instance.i('TempUserが存在しません。未認証状態に設定します');
          state = AuthState.unauthenticated;
        }
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

      // ユーザープロファイルを自動作成/更新
      await _createUserProfileIfNeeded(user);

      state = AuthState.authenticated;

      // ログイン完了後に同期チェックを実行
      AppLogger.instance.i('メールログイン完了後の同期チェックを開始します');
      await _syncChecker.checkAndSyncIfNeeded();
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

      // ユーザープロファイルを自動作成/更新
      await _createUserProfileIfNeeded(user);

      state = AuthState.authenticated;

      // ログイン完了後に同期チェックを実行
      AppLogger.instance.i('Googleログイン完了後の同期チェックを開始します');
      await _syncChecker.checkAndSyncIfNeeded();
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

      // ユーザープロファイルを自動作成/更新
      await _createUserProfileIfNeeded(user);

      state = AuthState.authenticated;

      // ログイン完了後に同期チェックを実行
      AppLogger.instance.i('Appleログイン完了後の同期チェックを開始します');
      await _syncChecker.checkAndSyncIfNeeded();
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
      AppLogger.instance.i('ユーザープロファイル作成/更新を開始します: ${user.id}');
      await _createUserProfileUseCase.execute(user);
      AppLogger.instance.i('ユーザープロファイル作成/更新が完了しました: ${user.id}');
    } catch (e, stackTrace) {
      // エラーを詳細にログ出力
      AppLogger.instance.e(
        'プロファイル作成に失敗しました: ユーザーID=${user.id}, メール=${user.email}',
        e,
        stackTrace,
      );
      // 認証は成功として扱うが、エラーの詳細を記録
    }
  }

  /// 一時ユーザーデータの移行をサポートする認証メソッド
  Future<void> signInWithGoogleAndMigrate({
    TempUserService? tempUserService,
    DataMigrationService? migrationService,
  }) async {
    state = AuthState.loading;
    try {
      // 一時ユーザーIDを取得（存在する場合）
      String? tempUserId;
      if (tempUserService != null) {
        tempUserId = await tempUserService.getTempUserId();
      }

      // 通常のGoogleサインイン処理
      final user = await _signInWithGoogleUseCase.call();
      _currentUser = user;

      // ユーザープロファイルを自動作成/更新
      await _createUserProfileIfNeeded(user);

      // データ移行処理（一時ユーザーが存在する場合）
      if (tempUserId != null && migrationService != null) {
        try {
          AppLogger.instance.i('一時ユーザーデータの移行を開始: $tempUserId → ${user.id}');
          final success = await migrationService.migrateTempUserData(
            tempUserId,
            user.id,
          );
          if (success) {
            AppLogger.instance.i('一時ユーザーデータの移行が完了しました');
            // 移行成功後、一時ユーザーデータを削除
            await tempUserService?.deleteTempUserData();
          } else {
            AppLogger.instance.w('一時ユーザーデータの移行に失敗しました');
          }
        } catch (e, stackTrace) {
          AppLogger.instance.e('データ移行中にエラーが発生しました', e, stackTrace);
          // 移行エラーは認証の失敗とは扱わない
        }
      }

      state = AuthState.authenticated;

      // ログイン完了後に同期チェックを実行
      AppLogger.instance.i('Googleログイン完了後の同期チェックを開始します');
      await _syncChecker.checkAndSyncIfNeeded();
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  /// 一時ユーザーデータの移行をサポートするApple認証メソッド
  Future<void> signInWithAppleAndMigrate({
    TempUserService? tempUserService,
    DataMigrationService? migrationService,
  }) async {
    state = AuthState.loading;
    try {
      // 一時ユーザーIDを取得（存在する場合）
      String? tempUserId;
      if (tempUserService != null) {
        tempUserId = await tempUserService.getTempUserId();
      }

      // 通常のAppleサインイン処理
      final user = await _signInWithAppleUseCase.call();
      _currentUser = user;

      // ユーザープロファイルを自動作成/更新
      await _createUserProfileIfNeeded(user);

      // データ移行処理（一時ユーザーが存在する場合）
      if (tempUserId != null && migrationService != null) {
        try {
          AppLogger.instance.i('一時ユーザーデータの移行を開始: $tempUserId → ${user.id}');
          final success = await migrationService.migrateTempUserData(
            tempUserId,
            user.id,
          );
          if (success) {
            AppLogger.instance.i('一時ユーザーデータの移行が完了しました');
            // 移行成功後、一時ユーザーデータを削除
            await tempUserService?.deleteTempUserData();
          } else {
            AppLogger.instance.w('一時ユーザーデータの移行に失敗しました');
          }
        } catch (e, stackTrace) {
          AppLogger.instance.e('データ移行中にエラーが発生しました', e, stackTrace);
          // 移行エラーは認証の失敗とは扱わない
        }
      }

      state = AuthState.authenticated;

      // ログイン完了後に同期チェックを実行
      AppLogger.instance.i('Appleログイン完了後の同期チェックを開始します');
      await _syncChecker.checkAndSyncIfNeeded();
    } catch (e) {
      state = AuthState.error;
      rethrow;
    }
  }

  /// ゲスト状態に設定（オンボーディング完了時）
  void setGuestState() {
    AppLogger.instance.i('ゲスト状態に移行しました');
    state = AuthState.guest;
    _currentUser = null; // ゲストユーザーは正式なユーザーではない
  }

  /// 初期状態に戻す
  void resetToInitial() {
    AppLogger.instance.i('認証状態を初期状態にリセットしました');
    state = AuthState.initial;
    _currentUser = null;
  }
}
