/// ソーシャル認証の結果を表すクラス
class AuthResult {
  /// 認証が成功したかどうか
  final bool success;

  /// ユーザーがキャンセルしたかどうか
  final bool cancelled;

  /// 取得した表示名（取得できなかった場合はnull）
  final String? displayName;

  const AuthResult._({
    required this.success,
    required this.cancelled,
    this.displayName,
  });

  /// 成功した認証結果を作成
  factory AuthResult.success({String? displayName}) {
    return AuthResult._(
      success: true,
      cancelled: false,
      displayName: displayName,
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
