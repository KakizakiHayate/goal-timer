/// 認証状態を表すenum
enum AuthState {
  /// 初期状態（認証状態不明）
  initial,

  /// 認証中
  loading,

  /// 認証済み
  authenticated,

  /// 未認証
  unauthenticated,

  /// エラー
  error,
}

/// 認証状態の拡張メソッド
extension AuthStateX on AuthState {
  /// 認証済みかどうか
  bool get isAuthenticated => this == AuthState.authenticated;

  /// 未認証かどうか
  bool get isUnauthenticated => this == AuthState.unauthenticated;

  /// ローディング中かどうか
  bool get isLoading => this == AuthState.loading;

  /// エラー状態かどうか
  bool get isError => this == AuthState.error;
}
