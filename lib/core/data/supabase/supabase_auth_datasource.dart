import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/app_logger.dart';

/// Supabase認証を管理するDataSource
class SupabaseAuthDatasource {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  SupabaseAuthDatasource({
    required SupabaseClient supabase,
    GoogleSignIn? googleSignIn,
  })  : _supabase = supabase,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              serverClientId: Platform.isAndroid
                  ? dotenv.env['GOOGLE_SIGNIN_ANDROID_CLIENT_ID']
                  : null,
            );

  /// 現在のユーザーを取得
  User? get currentUser => _supabase.auth.currentUser;

  /// ユーザーが匿名かどうか
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  /// 認証状態の変更を監視
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// 匿名認証でサインイン
  Future<AuthResponse> signInAnonymously() async {
    try {
      AppLogger.instance.i('匿名認証を開始します');

      final response = await _supabase.auth.signInAnonymously();

      if (response.user == null) {
        throw Exception('匿名認証に失敗しました: ユーザー情報が取得できません');
      }

      AppLogger.instance.i('匿名認証成功: ユーザーID=${response.user!.id}');
      return response;
    } catch (error, stackTrace) {
      AppLogger.instance.e('匿名認証に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// Googleアカウントでアイデンティティを連携
  ///
  /// signInWithIdTokenを使用して、匿名ユーザーをGoogleアカウントにリンクします
  Future<bool> linkWithGoogle() async {
    try {
      AppLogger.instance.i('Googleアカウント連携を開始します');

      // ネットワーク状態チェック
      final hasNetwork = await _checkNetworkConnection();
      if (!hasNetwork) {
        throw Exception('インターネット接続を確認してください');
      }

      // 既存のセッションをクリア
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.instance.w('Googleログインがキャンセルされました');
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Googleトークンの取得に失敗しました');
      }

      // signInWithIdTokenを使用してアカウントを連携
      // 現在の匿名セッションが新しいGoogleアカウントに自動的にリンクされます
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      AppLogger.instance.i('Googleアカウント連携成功');
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Googleアカウント連携に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// Appleアカウントでアイデンティティを連携
  ///
  /// signInWithIdTokenを使用して、匿名ユーザーをAppleアカウントにリンクします
  Future<bool> linkWithApple() async {
    try {
      AppLogger.instance.i('Appleアカウント連携を開始します');

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
        throw Exception('AppleIDトークンの取得に失敗しました');
      }

      // signInWithIdTokenを使用してアカウントを連携
      // 現在の匿名セッションが新しいAppleアカウントに自動的にリンクされます
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      AppLogger.instance.i('Appleアカウント連携成功');
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Appleアカウント連携に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();

      // Googleセッションもクリア
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        AppLogger.instance.w('Googleサインアウト失敗: $e');
      }

      AppLogger.instance.i('サインアウト完了');
    } catch (error, stackTrace) {
      AppLogger.instance.e('サインアウトに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// セッションを復元
  Future<Session?> recoverSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        AppLogger.instance.i('既存セッションを復元しました');
        return session;
      }
      return null;
    } catch (error, stackTrace) {
      AppLogger.instance.e('セッション復元に失敗しました', error, stackTrace);
      return null;
    }
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
