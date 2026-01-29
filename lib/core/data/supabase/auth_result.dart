/// ソーシャル認証の結果を表すクラス
///
/// 認証フローを2段階に分けるため、idTokenとrawNonceも保持します。
/// 1. authenticateGoogle/Apple() で認証を実行し、AuthResultを取得
/// 2. アカウント存在チェック等の事前処理を行う
/// 3. completeSignInWithGoogle/Apple() でsignInWithIdToken()を呼び出す
class AuthResult {
  /// 認証が成功したかどうか
  final bool success;

  /// ユーザーがキャンセルしたかどうか
  final bool cancelled;

  /// 取得した表示名（取得できなかった場合はnull）
  final String? displayName;

  /// 取得したメールアドレス（取得できなかった場合はnull）
  final String? email;

  /// IDトークン（signInWithIdToken()で使用）
  final String? idToken;

  /// Apple Sign-In用のrawNonce（signInWithIdToken()で使用）
  final String? rawNonce;

  const AuthResult._({
    required this.success,
    required this.cancelled,
    this.displayName,
    this.email,
    this.idToken,
    this.rawNonce,
  });

  /// 成功した認証結果を作成
  factory AuthResult.success({
    String? displayName,
    String? email,
    String? idToken,
    String? rawNonce,
  }) {
    return AuthResult._(
      success: true,
      cancelled: false,
      displayName: displayName,
      email: email,
      idToken: idToken,
      rawNonce: rawNonce,
    );
  }

  /// キャンセルされた認証結果を作成
  factory AuthResult.cancelled() {
    return const AuthResult._(
      success: false,
      cancelled: true,
    );
  }

  /// 失敗した認証結果を作成（例外がスローされる場合に使用）
  factory AuthResult.failure() {
    return const AuthResult._(
      success: false,
      cancelled: false,
    );
  }
}
