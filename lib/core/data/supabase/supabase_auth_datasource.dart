import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/app_logger.dart';
import 'auth_result.dart';

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
  /// 戻り値のAuthResultにはdisplayNameとemailが含まれます
  ///
  /// signInWithIdTokenを呼び出す前にAuthResultを返すため、
  /// 呼び出し元でアカウント存在チェックなどの事前処理が可能です。
  /// signInWithIdTokenの呼び出しは[completeGoogleSignIn]で行います。
  Future<AuthResult> linkWithGoogle() async {
    try {
      AppLogger.instance.i('Googleアカウント連携を開始します');

      // ネットワーク状態チェック
      final hasNetwork = await checkNetworkConnection();
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

      // displayNameとemailを取得
      final displayName = googleUser.displayName;
      final email = googleUser.email;
      AppLogger.instance.i(
        'Googleアカウント連携成功: displayName=$displayName, email=$email',
      );

      return AuthResult.success(displayName: displayName, email: email);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.instance.w('Googleログインがキャンセルされました');
        return AuthResult.cancelled();
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
  /// 戻り値のAuthResultにはdisplayNameとemailが含まれます
  Future<AuthResult> signInWithGoogle() async {
    try {
      AppLogger.instance.i('Googleアカウントでログインを開始します');

      // ネットワーク状態チェック
      final hasNetwork = await checkNetworkConnection();
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

      // displayNameとemailを取得
      final displayName = googleUser.displayName;
      final email = googleUser.email;
      AppLogger.instance.i(
        'Googleアカウントでログイン成功: displayName=$displayName, email=$email',
      );

      return AuthResult.success(displayName: displayName, email: email);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.instance.w('Googleログインがキャンセルされました');
        return AuthResult.cancelled();
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
  /// 戻り値のAuthResultにはdisplayNameとemailが含まれます
  /// 注意: Appleは初回ログイン時のみ名前を提供します。2回目以降はnullになります。
  /// emailはidTokenをデコードして取得します（credential.emailは初回のみ）。
  Future<AuthResult> signInWithApple() async {
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

      // displayNameを取得（Appleは初回のみ名前を提供）
      final displayName = _buildAppleDisplayName(
        givenName: credential.givenName,
        familyName: credential.familyName,
      );

      // emailをidTokenからデコードして取得
      // credential.emailは初回のみ提供されるため、idTokenから取得する
      final email = _extractEmailFromIdToken(idToken);
      AppLogger.instance.i(
        'Appleアカウントでログイン成功: displayName=$displayName, email=$email',
      );

      return AuthResult.success(displayName: displayName, email: email);
    } catch (error, stackTrace) {
      AppLogger.instance.e('Appleログインに失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// Appleアカウントでアイデンティティを連携
  ///
  /// signInWithIdTokenを使用して、匿名ユーザーをAppleアカウントにリンクします
  /// 戻り値のAuthResultにはdisplayNameとemailが含まれます
  /// 注意: Appleは初回ログイン時のみ名前を提供します。2回目以降はnullになります。
  /// emailはidTokenをデコードして取得します（credential.emailは初回のみ）。
  Future<AuthResult> linkWithApple() async {
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

      // displayNameを取得（Appleは初回のみ名前を提供）
      final displayName = _buildAppleDisplayName(
        givenName: credential.givenName,
        familyName: credential.familyName,
      );

      // emailをidTokenからデコードして取得
      // credential.emailは初回のみ提供されるため、idTokenから取得する
      final email = _extractEmailFromIdToken(idToken);
      AppLogger.instance.i(
        'Appleアカウント連携成功: displayName=$displayName, email=$email',
      );

      return AuthResult.success(displayName: displayName, email: email);
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
  Future<bool> checkNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      AppLogger.instance.w('ネットワーク接続チェック失敗: $e');
      return false;
    }
  }

  /// Apple Sign-Inから取得した名前を結合
  /// givenNameとfamilyNameがどちらもnullの場合はnullを返す
  String? _buildAppleDisplayName({
    required String? givenName,
    required String? familyName,
  }) {
    if (givenName == null && familyName == null) {
      return null;
    }

    final parts = <String>[];
    if (familyName != null && familyName.isNotEmpty) {
      parts.add(familyName);
    }
    if (givenName != null && givenName.isNotEmpty) {
      parts.add(givenName);
    }

    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Apple idTokenからemailを抽出
  ///
  /// credential.emailは初回のみ提供されるため、
  /// 2回目以降のログインではidTokenをデコードしてemailを取得する。
  /// 「メールを非公開」の場合もプライベートリレーアドレスが取得できる。
  String? _extractEmailFromIdToken(String idToken) {
    try {
      final decodedToken = JwtDecoder.decode(idToken);
      final email = decodedToken['email'] as String?;
      AppLogger.instance.d('idTokenからemailを抽出しました: $email');
      return email;
    } catch (error, stackTrace) {
      AppLogger.instance.e('idTokenのデコードに失敗しました', error, stackTrace);
      return null;
    }
  }

  /// Supabase Auth user_metadataのdisplayNameを更新
  Future<void> updateDisplayName(String displayName) async {
    try {
      AppLogger.instance.i('displayNameを更新します: $displayName');

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'display_name': displayName},
        ),
      );

      AppLogger.instance.i('displayNameの更新が完了しました');
    } catch (error, stackTrace) {
      AppLogger.instance.e('displayNameの更新に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// 現在のユーザーのdisplayNameを取得（user_metadataから）
  String? getDisplayNameFromMetadata() {
    final user = currentUser;
    if (user == null) return null;

    final metadata = user.userMetadata;
    if (metadata == null) return null;

    // カスタムのdisplay_nameを優先
    final customDisplayName = metadata['display_name'] as String?;
    if (customDisplayName != null && customDisplayName.isNotEmpty) {
      return customDisplayName;
    }

    // Google Sign-Inの場合はnameが設定される
    final googleName = metadata['name'] as String?;
    if (googleName != null && googleName.isNotEmpty) {
      return googleName;
    }

    return null;
  }

  // ============================================================
  // 認証フロー分離メソッド
  // 以下のメソッドは認証とsignInWithIdToken()を分離するために使用します。
  // 1. authenticateGoogle/Apple() で認証のみ実行
  // 2. アカウント存在チェック等の事前処理を実行
  // 3. completeSignInWithGoogle/Apple() でsignInWithIdToken()を呼び出す
  // ============================================================

  /// Google認証のみを実行（signInWithIdToken()は呼ばない）
  ///
  /// 戻り値のAuthResultにはidToken, displayName, emailが含まれます。
  /// アカウント存在チェック後、[completeSignInWithGoogle]を呼び出してください。
  Future<AuthResult> authenticateGoogle() async {
    try {
      AppLogger.instance.i('Google認証を開始します（signInWithIdTokenは呼ばない）');

      // ネットワーク状態チェック
      final hasNetwork = await checkNetworkConnection();
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

      // displayNameとemailを取得
      final displayName = googleUser.displayName;
      final email = googleUser.email;
      AppLogger.instance.i(
        'Google認証成功: displayName=$displayName, email=$email',
      );

      return AuthResult.success(
        displayName: displayName,
        email: email,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        AppLogger.instance.w('Google認証がキャンセルされました');
        return AuthResult.cancelled();
      }
      AppLogger.instance.e('Google認証に失敗しました', e);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.instance.e('Google認証に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// Apple認証のみを実行（signInWithIdToken()は呼ばない）
  ///
  /// 戻り値のAuthResultにはidToken, rawNonce, displayName, emailが含まれます。
  /// アカウント存在チェック後、[completeSignInWithApple]を呼び出してください。
  Future<AuthResult> authenticateApple() async {
    try {
      AppLogger.instance.i('Apple認証を開始します（signInWithIdTokenは呼ばない）');

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

      // displayNameを取得（Appleは初回のみ名前を提供）
      final displayName = _buildAppleDisplayName(
        givenName: credential.givenName,
        familyName: credential.familyName,
      );

      // emailをidTokenからデコードして取得
      final email = _extractEmailFromIdToken(idToken);
      AppLogger.instance.i(
        'Apple認証成功: displayName=$displayName, email=$email',
      );

      return AuthResult.success(
        displayName: displayName,
        email: email,
        idToken: idToken,
        rawNonce: rawNonce,
      );
    } catch (error, stackTrace) {
      AppLogger.instance.e('Apple認証に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// Google認証完了（signInWithIdToken()を呼び出す）
  ///
  /// [authenticateGoogle]で取得したidTokenを使用して、
  /// Supabaseの認証を完了します。
  Future<void> completeSignInWithGoogle(String idToken) async {
    try {
      AppLogger.instance.i('Google認証を完了します（signInWithIdToken）');

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      AppLogger.instance.i('Google認証完了');
    } catch (error, stackTrace) {
      AppLogger.instance.e('Google認証の完了に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// Apple認証完了（signInWithIdToken()を呼び出す）
  ///
  /// [authenticateApple]で取得したidTokenとrawNonceを使用して、
  /// Supabaseの認証を完了します。
  Future<void> completeSignInWithApple({
    required String idToken,
    required String rawNonce,
  }) async {
    try {
      AppLogger.instance.i('Apple認証を完了します（signInWithIdToken）');

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      AppLogger.instance.i('Apple認証完了');
    } catch (error, stackTrace) {
      AppLogger.instance.e('Apple認証の完了に失敗しました', error, stackTrace);
      rethrow;
    }
  }

  /// Google認証セッションをクリア
  ///
  /// エラー終了時にGoogle認証セッションをクリアするために使用します。
  Future<void> clearGoogleSession() async {
    try {
      if (_isGoogleSignInInitialized) {
        await GoogleSignIn.instance.signOut();
        AppLogger.instance.i('Google認証セッションをクリアしました');
      }
    } catch (e) {
      AppLogger.instance.w('Google認証セッションのクリアに失敗しました: $e');
    }
  }
}
