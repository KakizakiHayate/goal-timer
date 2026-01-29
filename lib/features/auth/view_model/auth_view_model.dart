import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/local/app_database.dart';
import '../../../core/data/local/local_users_datasource.dart';
import '../../../core/data/supabase/supabase_auth_datasource.dart';
import '../../../core/data/supabase/supabase_users_datasource.dart';
import '../../../core/utils/app_logger.dart';

/// 認証の状態
enum AuthStatus {
  /// 初期状態
  initial,

  /// 処理中
  loading,

  /// 成功
  success,

  /// エラー
  error,
}

/// 認証エラーの種別
enum AuthErrorType {
  /// エラーなし
  none,

  /// アカウントが存在しない（ログイン時）
  accountNotFound,

  /// アカウントが既に存在する（連携時）
  accountAlreadyExists,

  /// メールアドレスを取得できない
  emailNotFound,

  /// その他のエラー
  other,
}

/// プロバイダの定数
class AuthProvider {
  static const String google = 'google';
  static const String apple = 'apple';
  static const String anonymous = 'anonymous';
}

/// 認証ViewModel
class AuthViewModel extends GetxController {
  late final SupabaseAuthDatasource _authDatasource;
  late final LocalUsersDatasource _usersDatasource;
  late final SupabaseUsersDatasource _supabaseUsersDatasource;

  AuthViewModel({
    SupabaseAuthDatasource? authDatasource,
    LocalUsersDatasource? usersDatasource,
    SupabaseUsersDatasource? supabaseUsersDatasource,
  }) {
    _authDatasource = authDatasource ??
        SupabaseAuthDatasource(supabase: Supabase.instance.client);
    _usersDatasource =
        usersDatasource ?? LocalUsersDatasource(database: AppDatabase());
    _supabaseUsersDatasource = supabaseUsersDatasource ??
        SupabaseUsersDatasource(supabase: Supabase.instance.client);
  }

  /// 現在の状態
  final _status = AuthStatus.initial.obs;
  AuthStatus get status => _status.value;

  /// エラーメッセージ
  final _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  /// エラー種別
  final _errorType = AuthErrorType.none.obs;
  AuthErrorType get errorType => _errorType.value;

  /// ユーザーが匿名かどうか
  bool get isAnonymous => _authDatasource.isAnonymous;

  /// 処理中かどうか
  bool get isLoading => _status.value == AuthStatus.loading;

  /// エラーかどうか
  bool get hasError => _status.value == AuthStatus.error;

  /// 連携ボタンを表示するかどうか
  bool get showLinkButton => isAnonymous;

  /// Googleアカウントと連携
  ///
  /// 処理フロー:
  /// 1. Google認証を実行しemail/idTokenを取得
  /// 2. emailがnullの場合はエラー
  /// 3. アカウント存在チェック（存在する場合はエラー）
  /// 4. signInWithIdToken()を呼び出して連携
  /// 5. public.usersにemail/providerを保存
  Future<bool> linkWithGoogle() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      _errorType.value = AuthErrorType.none;
      update();

      // Step 1: Google認証のみ実行（signInWithIdTokenは呼ばない）
      final result = await _authDatasource.authenticateGoogle();

      if (result.cancelled) {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Googleアカウント連携がキャンセルされました');
        update();
        return false;
      }

      if (!result.success) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.other;
        _errorMessage.value = 'Google認証に失敗しました';
        update();
        return false;
      }

      // Step 2: emailチェック
      final email = result.email;
      final idToken = result.idToken;
      if (email == null || email.isEmpty) {
        await _authDatasource.clearGoogleSession();
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.emailNotFound;
        _errorMessage.value = 'メールアドレスを取得できませんでした';
        AppLogger.instance.e('emailがnullのため連携を中断');
        update();
        return false;
      }

      if (idToken == null) {
        await _authDatasource.clearGoogleSession();
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.other;
        _errorMessage.value = '認証情報を取得できませんでした';
        AppLogger.instance.e('idTokenがnullのため連携を中断');
        update();
        return false;
      }

      // Step 3: アカウント存在チェック
      final exists = await _supabaseUsersDatasource.checkAccountExists(
        email: email,
        provider: AuthProvider.google,
      );

      if (exists) {
        await _authDatasource.clearGoogleSession();
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.accountAlreadyExists;
        _errorMessage.value = 'このアカウントは既に登録されています';
        AppLogger.instance.e('アカウントが既に存在するため連携を中断');
        update();
        return false;
      }

      // Step 4: signInWithIdToken()を呼び出して連携
      await _authDatasource.completeSignInWithGoogle(idToken);

      // Step 5: public.usersにemail/providerを保存
      final userId = _authDatasource.currentUser?.id;
      if (userId != null) {
        await _supabaseUsersDatasource.upsertEmailAndProvider(
          userId: userId,
          email: email,
          provider: AuthProvider.google,
        );
      }

      // displayNameをローカルDBとSupabaseに保存
      await _saveDisplayName(result.displayName, saveToSupabase: true);

      _status.value = AuthStatus.success;
      AppLogger.instance.i('Googleアカウント連携成功');
      update();
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Googleアカウント連携に失敗しました', error, stackTrace);
      await _authDatasource.clearGoogleSession();
      _status.value = AuthStatus.error;
      _errorType.value = AuthErrorType.other;
      _errorMessage.value = 'Googleアカウント連携に失敗しました';
      update();
      return false;
    }
  }

  /// Appleアカウントと連携
  ///
  /// 処理フロー:
  /// 1. Apple認証を実行しemail/idToken/rawNonceを取得
  /// 2. emailがnullの場合はエラー
  /// 3. アカウント存在チェック（存在する場合はエラー）
  /// 4. signInWithIdToken()を呼び出して連携
  /// 5. public.usersにemail/providerを保存
  Future<bool> linkWithApple() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      _errorType.value = AuthErrorType.none;
      update();

      // Step 1: Apple認証のみ実行（signInWithIdTokenは呼ばない）
      final result = await _authDatasource.authenticateApple();

      if (result.cancelled) {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Appleアカウント連携がキャンセルされました');
        update();
        return false;
      }

      if (!result.success) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.other;
        _errorMessage.value = 'Apple認証に失敗しました';
        update();
        return false;
      }

      // Step 2: emailチェック
      final email = result.email;
      final idToken = result.idToken;
      final rawNonce = result.rawNonce;
      if (email == null || email.isEmpty) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.emailNotFound;
        _errorMessage.value = 'メールアドレスを取得できませんでした';
        AppLogger.instance.e('emailがnullのため連携を中断');
        update();
        return false;
      }

      if (idToken == null || rawNonce == null) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.other;
        _errorMessage.value = '認証情報を取得できませんでした';
        AppLogger.instance.e('idToken/rawNonceがnullのため連携を中断');
        update();
        return false;
      }

      // Step 3: アカウント存在チェック
      final exists = await _supabaseUsersDatasource.checkAccountExists(
        email: email,
        provider: AuthProvider.apple,
      );

      if (exists) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.accountAlreadyExists;
        _errorMessage.value = 'このアカウントは既に登録されています';
        AppLogger.instance.e('アカウントが既に存在するため連携を中断');
        update();
        return false;
      }

      // Step 4: signInWithIdToken()を呼び出して連携
      await _authDatasource.completeSignInWithApple(
        idToken: idToken,
        rawNonce: rawNonce,
      );

      // Step 5: public.usersにemail/providerを保存
      final userId = _authDatasource.currentUser?.id;
      if (userId != null) {
        await _supabaseUsersDatasource.upsertEmailAndProvider(
          userId: userId,
          email: email,
          provider: AuthProvider.apple,
        );
      }

      // displayNameをローカルDBとSupabaseに保存
      await _saveDisplayName(result.displayName, saveToSupabase: true);

      _status.value = AuthStatus.success;
      AppLogger.instance.i('Appleアカウント連携成功');
      update();
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Appleアカウント連携に失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorType.value = AuthErrorType.other;
      _errorMessage.value = 'Appleアカウント連携に失敗しました';
      update();
      return false;
    }
  }

  /// エラー状態をクリア
  void clearError() {
    _status.value = AuthStatus.initial;
    _errorMessage.value = '';
    _errorType.value = AuthErrorType.none;
    update();
  }

  /// Googleアカウントでログイン（既存アカウント）
  ///
  /// 処理フロー:
  /// 1. Google認証を実行しemail/idTokenを取得
  /// 2. emailがnullの場合はエラー
  /// 3. アカウント存在チェック（存在しない場合はエラー）
  /// 4. signInWithIdToken()を呼び出してログイン
  Future<bool> loginWithGoogle() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      _errorType.value = AuthErrorType.none;
      update();

      // Step 1: Google認証のみ実行（signInWithIdTokenは呼ばない）
      final result = await _authDatasource.authenticateGoogle();

      if (result.cancelled) {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Googleログインがキャンセルされました');
        update();
        return false;
      }

      if (!result.success) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.other;
        _errorMessage.value = 'Google認証に失敗しました';
        update();
        return false;
      }

      // Step 2: emailチェック
      final email = result.email;
      final idToken = result.idToken;
      if (email == null || email.isEmpty) {
        await _authDatasource.clearGoogleSession();
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.emailNotFound;
        _errorMessage.value = 'メールアドレスを取得できませんでした';
        AppLogger.instance.e('emailがnullのためログインを中断');
        update();
        return false;
      }

      if (idToken == null) {
        await _authDatasource.clearGoogleSession();
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.other;
        _errorMessage.value = '認証情報を取得できませんでした';
        AppLogger.instance.e('idTokenがnullのためログインを中断');
        update();
        return false;
      }

      // Step 3: アカウント存在チェック
      final exists = await _supabaseUsersDatasource.checkAccountExists(
        email: email,
        provider: AuthProvider.google,
      );

      if (!exists) {
        await _authDatasource.clearGoogleSession();
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.accountNotFound;
        _errorMessage.value = 'このアカウントは登録されていません';
        AppLogger.instance.e('アカウントが存在しないためログインを中断');
        update();
        return false;
      }

      // Step 4: signInWithIdToken()を呼び出してログイン
      await _authDatasource.completeSignInWithGoogle(idToken);

      // public.usersテーブルに保存されたカスタムdisplayNameを優先
      final userId = _authDatasource.currentUser?.id;
      String? customDisplayName;
      if (userId != null) {
        customDisplayName =
            await _supabaseUsersDatasource.getDisplayName(userId);
      }
      await _saveDisplayName(customDisplayName ?? result.displayName);

      _status.value = AuthStatus.success;
      AppLogger.instance.i('Googleログイン成功');
      update();
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Googleログインに失敗しました', error, stackTrace);
      await _authDatasource.clearGoogleSession();
      _status.value = AuthStatus.error;
      _errorType.value = AuthErrorType.other;
      _errorMessage.value = 'ログインに失敗しました';
      update();
      return false;
    }
  }

  /// Appleアカウントでログイン（既存アカウント）
  ///
  /// 処理フロー:
  /// 1. Apple認証を実行しemail/idToken/rawNonceを取得
  /// 2. emailがnullの場合はエラー
  /// 3. アカウント存在チェック（存在しない場合はエラー）
  /// 4. signInWithIdToken()を呼び出してログイン
  Future<bool> loginWithApple() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      _errorType.value = AuthErrorType.none;
      update();

      // Step 1: Apple認証のみ実行（signInWithIdTokenは呼ばない）
      final result = await _authDatasource.authenticateApple();

      if (result.cancelled) {
        _status.value = AuthStatus.initial;
        AppLogger.instance.w('Appleログインがキャンセルされました');
        update();
        return false;
      }

      if (!result.success) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.other;
        _errorMessage.value = 'Apple認証に失敗しました';
        update();
        return false;
      }

      // Step 2: emailチェック
      final email = result.email;
      final idToken = result.idToken;
      final rawNonce = result.rawNonce;
      if (email == null || email.isEmpty) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.emailNotFound;
        _errorMessage.value = 'メールアドレスを取得できませんでした';
        AppLogger.instance.e('emailがnullのためログインを中断');
        update();
        return false;
      }

      if (idToken == null || rawNonce == null) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.other;
        _errorMessage.value = '認証情報を取得できませんでした';
        AppLogger.instance.e('idToken/rawNonceがnullのためログインを中断');
        update();
        return false;
      }

      // Step 3: アカウント存在チェック
      final exists = await _supabaseUsersDatasource.checkAccountExists(
        email: email,
        provider: AuthProvider.apple,
      );

      if (!exists) {
        _status.value = AuthStatus.error;
        _errorType.value = AuthErrorType.accountNotFound;
        _errorMessage.value = 'このアカウントは登録されていません';
        AppLogger.instance.e('アカウントが存在しないためログインを中断');
        update();
        return false;
      }

      // Step 4: signInWithIdToken()を呼び出してログイン
      await _authDatasource.completeSignInWithApple(
        idToken: idToken,
        rawNonce: rawNonce,
      );

      // public.usersテーブルに保存されたカスタムdisplayNameを優先
      final userId = _authDatasource.currentUser?.id;
      String? customDisplayName;
      if (userId != null) {
        customDisplayName =
            await _supabaseUsersDatasource.getDisplayName(userId);
      }
      await _saveDisplayName(customDisplayName ?? result.displayName);

      _status.value = AuthStatus.success;
      AppLogger.instance.i('Appleログイン成功');
      update();
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Appleログインに失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorType.value = AuthErrorType.other;
      _errorMessage.value = 'ログインに失敗しました';
      update();
      return false;
    }
  }

  /// アカウント削除
  Future<bool> deleteAccount() async {
    try {
      _status.value = AuthStatus.loading;
      _errorMessage.value = '';
      _errorType.value = AuthErrorType.none;
      update();

      await _authDatasource.deleteAccount();

      // ローカルDBのユーザーデータをリセット
      await _usersDatasource.resetDisplayName();

      _status.value = AuthStatus.success;
      AppLogger.instance.i('アカウント削除成功');
      update();
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('アカウント削除に失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorType.value = AuthErrorType.other;
      _errorMessage.value = 'アカウント削除に失敗しました';
      update();
      return false;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      _status.value = AuthStatus.loading;
      update();

      await _authDatasource.signOut();

      // ローカルDBのユーザーデータをリセット
      await _usersDatasource.resetDisplayName();

      _status.value = AuthStatus.initial;
      _errorType.value = AuthErrorType.none;
      AppLogger.instance.i('サインアウト完了');
      update();
    } catch (error, stackTrace) {
      AppLogger.instance.e('サインアウトに失敗しました', error, stackTrace);
      _status.value = AuthStatus.error;
      _errorType.value = AuthErrorType.other;
      _errorMessage.value = 'サインアウトに失敗しました';
      update();
    }
  }

  /// displayNameをローカルDBとSupabaseに保存
  ///
  /// [saveToSupabase]がtrueの場合、public.usersテーブルにも保存します（連携時に使用）
  Future<void> _saveDisplayName(
    String? displayName, {
    bool saveToSupabase = false,
  }) async {
    if (displayName == null || displayName.isEmpty) {
      AppLogger.instance.i('displayNameが取得できなかったため保存をスキップ');
      return;
    }

    try {
      // ローカルDBに保存
      await _usersDatasource.updateDisplayName(displayName);
      AppLogger.instance.i('displayNameをローカルDBに保存しました: $displayName');

      // Supabaseにも保存（連携時のみ）
      if (saveToSupabase) {
        final userId = _authDatasource.currentUser?.id;
        if (userId != null) {
          await _supabaseUsersDatasource.updateDisplayName(userId, displayName);
          AppLogger.instance.i('displayNameをSupabaseに保存しました: $displayName');
        }
      }
    } catch (error, stackTrace) {
      // displayName保存の失敗はログイン処理全体を失敗させない
      AppLogger.instance.e('displayNameの保存に失敗しました', error, stackTrace);
    }
  }
}
