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
  bool _isGoogleSignInInitialized = false;

  SupabaseAuthDatasource({
    required SupabaseClient supabase,
  }) : _supabase = supabase;

  /// GoogleSignInの初期化
  ///
  /// serverClientIdにはWeb Client IDを使用します。
  /// これはSupabaseがGoogle ID Tokenを検証する際に必要です。
  /// iOS/Android両方で同じWeb Client IDを使用することで、
  /// ID TokenのaudienceがSupabaseの期待する値と一致します。
  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleSignInInitialized) return;

    // Web Client IDを使用（Supabase連携に必要）
    // Google Cloud ConsoleのOAuth 2.0クライアントIDから取得
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

    if (webClientId == null || webClientId.isEmpty) {
      AppLogger.instance.w('GOOGLE_WEB_CLIENT_IDが設定されていません');
    }

    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId,
    );
    _isGoogleSignInInitialized = true;
  }

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

      final user = response.user;
      if (user == null) {
        throw Exception('匿名認証に失敗しました: ユーザー情報が取得できません');
      }

      AppLogger.instance.i('匿名認証成功: ユーザーID=${user.id}');
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

      // GoogleSignInを初期化
      await _initializeGoogleSignIn();

      // 既存のセッションをクリア
      await GoogleSignIn.instance.signOut();

      // 認証を実行（google_sign_in 7.x API）
      // authenticate()はidTokenとaccessTokenの両方を含む認証情報を返します
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 認証情報からidTokenを取得
      // google_sign_in 7.xではaccessTokenはauthorizeScopes()からのみ取得可能
      // authorizeScopes()を呼ぶと二重認証画面が表示されるため、
      // SupabaseにはidTokenのみを渡します（accessTokenはオプション）
      final authentication = googleUser.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        throw Exception('GoogleIDトークンの取得に失敗しました');
      }

      // signInWithIdTokenを使用してアカウントを連携
      // 現在の匿名セッションが新しいGoogleアカウントに自動的にリンクされます
      // accessTokenはオプションのため省略
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      AppLogger.instance.i('Googleアカウント連携成功');
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.instance.w('Googleログインがキャンセルされました');
        return false;
      }
      AppLogger.instance.e('Googleアカウント連携に失敗しました', e);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Googleアカウント連携に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// Googleアカウントでログイン（既存アカウントにサインイン）
  ///
  /// signInWithIdTokenを使用して、既存のGoogleアカウントでサインインします
  Future<bool> signInWithGoogle() async {
    try {
      AppLogger.instance.i('Googleアカウントでログインを開始します');

      // ネットワーク状態チェック
      final hasNetwork = await _checkNetworkConnection();
      if (!hasNetwork) {
        throw Exception('インターネット接続を確認してください');
      }

      // GoogleSignInを初期化
      await _initializeGoogleSignIn();

      // 既存のセッションをクリア
      await GoogleSignIn.instance.signOut();

      // 認証を実行
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 認証情報からidTokenを取得
      final authentication = googleUser.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        throw Exception('GoogleIDトークンの取得に失敗しました');
      }

      // signInWithIdTokenを使用してログイン
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      AppLogger.instance.i('Googleアカウントでログイン成功');
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.instance.w('Googleログインがキャンセルされました');
        return false;
      }
      AppLogger.instance.e('Googleログインに失敗しました', e);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Googleログインに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// Appleアカウントでログイン（既存アカウントにサインイン）
  ///
  /// signInWithIdTokenを使用して、既存のAppleアカウントでサインインします
  Future<bool> signInWithApple() async {
    try {
      AppLogger.instance.i('Appleアカウントでログインを開始します');

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

      // signInWithIdTokenを使用してログイン
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      AppLogger.instance.i('Appleアカウントでログイン成功');
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Appleログインに失敗しました', error, stackTrace);
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

  /// アカウントを削除
  ///
  /// Edge Function経由でユーザーと関連データを削除します
  Future<void> deleteAccount() async {
    try {
      AppLogger.instance.i('アカウント削除を開始します');

      // Edge Functionを呼び出してアカウントを削除
      final response = await _supabase.functions.invoke('delete-account');

      if (response.status != 200) {
        final data = response.data as Map<String, dynamic>?;
        final error = data?['error'] as String? ?? 'Unknown error';
        throw Exception('アカウント削除に失敗しました: $error');
      }

      // Googleセッションもクリア
      try {
        if (_isGoogleSignInInitialized) {
          await GoogleSignIn.instance.signOut();
        }
      } catch (e) {
        AppLogger.instance.w('Googleサインアウト失敗: $e');
      }

      AppLogger.instance.i('アカウント削除完了');
    } catch (error, stackTrace) {
      AppLogger.instance.e('アカウント削除に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();

      // Googleセッションもクリア
      try {
        if (_isGoogleSignInInitialized) {
          await GoogleSignIn.instance.signOut();
        }
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
