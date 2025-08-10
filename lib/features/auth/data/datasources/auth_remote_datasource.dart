import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import '../../domain/entities/app_user.dart';
import '../../../../core/utils/app_logger.dart';

/// リモート認証を管理するデータソース
abstract class AuthRemoteDataSource {
  /// 認証状態の変更を監視
  Stream<AppUser?> get authStateChanges;

  /// 現在のユーザーを取得
  Future<AppUser?> getCurrentUser();

  /// メールアドレスとパスワードでログイン
  Future<AppUser> signInWithEmail(String email, String password);

  /// メールアドレスとパスワードでサインアップ
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );

  /// Googleアカウントでログイン
  Future<AppUser> signInWithGoogle();

  /// Appleアカウントでログイン
  Future<AppUser> signInWithApple();

  /// サインアウト
  Future<void> signOut();

  /// パスワードリセットメールを送信
  Future<void> sendPasswordResetEmail(String email);

  /// メール確認を送信
  Future<void> sendEmailVerification();

  /// メールが確認済みかチェック
  Future<bool> isEmailVerified();
}

/// リモート認証データソースの実装
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl(this._supabase, this._googleSignIn);

  @override
  Stream<AppUser?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user != null ? _mapToAppUser(user) : null;
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    return user != null ? _mapToAppUser(user) : null;
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('ログインに失敗しました');
      }

      return _mapToAppUser(response.user!);
    } catch (e) {
      throw Exception('ログインエラー: ${e.toString()}');
    }
  }

  @override
  Future<AppUser> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user == null) {
        throw Exception('サインアップに失敗しました');
      }

      return _mapToAppUser(response.user!);
    } catch (e) {
      throw Exception('サインアップエラー: ${e.toString()}');
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    AppLogger.instance.i('Googleログイン開始');
    
    try {
      // ネットワーク状態チェック（追加）
      final hasNetwork = await _checkNetworkConnection();
      if (!hasNetwork) {
        AppLogger.instance.w('ネットワークに接続されていません');
        throw Exception('インターネット接続を確認してください');
      }

      // セッションを完全にクリア（追加）
      await _googleSignIn.signOut();
      AppLogger.instance.d('既存のGoogleセッションをクリア');

      AppLogger.instance.d('Google Sign-In ダイアログを表示中...');
      final googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        AppLogger.instance.w('Googleログインがユーザーによってキャンセルされました');
        throw Exception('Googleログインがキャンセルされました');
      }

      AppLogger.instance.d('Googleユーザー情報取得成功: ${googleUser.email}');
      AppLogger.instance.d('Google認証トークンを取得中...');
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      AppLogger.instance.d('アクセストークン取得: ${accessToken != null ? "成功" : "失敗"}');
      AppLogger.instance.d('IDトークン取得: ${idToken != null ? "成功" : "失敗"}');

      if (accessToken == null) {
        AppLogger.instance.e('Googleアクセストークンがnull');
        throw Exception('Googleアクセストークンの取得に失敗しました');
      }

      if (idToken == null) {
        AppLogger.instance.e('GoogleIDトークンがnull');
        throw Exception('GoogleIDトークンの取得に失敗しました');
      }

      AppLogger.instance.d('Supabaseでの認証を開始...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
        nonce: null,
      );

      if (response.user == null) {
        AppLogger.instance.e('Supabase認証レスポンスでユーザーがnull');
        AppLogger.instance.e('認証レスポンス詳細: ${response.toString()}');
        throw Exception('Googleログインに失敗しました');
      }

      final appUser = _mapToAppUser(response.user!);
      AppLogger.instance.i('Googleログイン成功: ユーザーID=${appUser.id}, Email=${appUser.email}');
      return appUser;
      
    } on Exception catch (e) {
      // エラーハンドリング改善（追加）
      if (e.toString().contains('ApiException: 7')) {
        AppLogger.instance.w('ネットワークエラーを検出、リトライします...');
        // 短時間待機してリトライ
        await Future.delayed(const Duration(seconds: 2));
        return _retryGoogleSignIn();
      }
      AppLogger.instance.e('Googleログイン Exception', e);
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.instance.e('Googleログイン 予期しないエラー', e, stackTrace);
      throw Exception('Googleログインエラー: ${e.toString()}');
    }
  }

  /// Google Sign-In リトライメソッド
  Future<AppUser> _retryGoogleSignIn() async {
    AppLogger.instance.d('Googleログイン リトライ実行');
    final googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      throw Exception('Googleログインがキャンセルされました');
    }

    AppLogger.instance.d('リトライ: Googleユーザー情報取得成功: ${googleUser.email}');
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Googleトークンの取得に失敗しました');
    }

    AppLogger.instance.d('リトライ: Supabaseでの認証を開始...');
    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
      nonce: null,
    );

    if (response.user == null) {
      throw Exception('Googleログインに失敗しました');
    }

    final appUser = _mapToAppUser(response.user!);
    AppLogger.instance.i('Googleログイン リトライ成功: ユーザーID=${appUser.id}');
    return appUser;
  }

  @override
  Future<AppUser> signInWithApple() async {
    try {
      // Apple Sign In用のランダムな文字列を生成
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Appleログインでトークンの取得に失敗しました');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (response.user == null) {
        throw Exception('Appleログインに失敗しました');
      }

      return _mapToAppUser(response.user!);
    } catch (e) {
      throw Exception('Appleログインエラー: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Supabaseからサインアウト
      await _supabase.auth.signOut();
      AppLogger.instance.d('Supabaseサインアウト完了');
      
      // Googleセッションもクリア
      try {
        await _googleSignIn.signOut();
        AppLogger.instance.d('Googleサインアウト完了');
        
        // disconnect()は失敗する可能性があるため個別にハンドリング
        try {
          await _googleSignIn.disconnect();
          AppLogger.instance.d('Google完全切断完了');
        } catch (disconnectError) {
          // disconnect失敗は既知の問題のため、ログのみ出力
          AppLogger.instance.w('Google disconnect失敗（既知の問題）: $disconnectError');
        }
      } catch (googleError) {
        AppLogger.instance.w('Googleサインアウト失敗: $googleError');
      }
      
      AppLogger.instance.i('サインアウト完了');
    } catch (e) {
      AppLogger.instance.e('サインアウトエラー: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('パスワードリセットメール送信エラー: ${e.toString()}');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) {
        throw Exception('ユーザーまたはメールアドレスが見つかりません');
      }

      await _supabase.auth.resend(type: OtpType.signup, email: user!.email!);
    } catch (e) {
      throw Exception('メール確認送信エラー: ${e.toString()}');
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  /// SupabaseのUserをAppUserエンティティにマッピング
  AppUser _mapToAppUser(User user) {
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName:
          user.userMetadata?['display_name'] as String? ??
          user.userMetadata?['full_name'] as String?,
      photoUrl:
          user.userMetadata?['avatar_url'] as String? ??
          user.userMetadata?['picture'] as String?,
      createdAt: user.createdAt,
      lastSignInAt: user.lastSignInAt,
    );
  }

  /// Apple Sign In用のランダムな文字列を生成
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// ネットワーク接続状態をチェック
  Future<bool> _checkNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      AppLogger.instance.w('ネットワーク接続チェック失敗: $e');
      return false;
    }
  }
}
