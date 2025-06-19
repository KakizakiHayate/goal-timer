import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../../domain/entities/app_user.dart';

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
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Googleログインがキャンセルされました');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw Exception('Googleアクセストークンの取得に失敗しました');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        accessToken: accessToken,
      );

      if (response.user == null) {
        throw Exception('Googleログインに失敗しました');
      }

      return _mapToAppUser(response.user!);
    } catch (e) {
      throw Exception('Googleログインエラー: ${e.toString()}');
    }
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
      await _supabase.auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('サインアウトエラー: ${e.toString()}');
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
}
