/// 認証状態を表すenum
enum AuthState {
  /// 初期状態（認証状態不明）
  initial,

  /// 認証中
  loading,

  /// 認証済み
  authenticated,

  /// ゲストユーザー（tempUser）
  guest,

  /// 未認証
  unauthenticated,

  /// エラー
  error,
}

/// 認証状態の拡張メソッド
extension AuthStateX on AuthState {
  /// 認証済みかどうか
  bool get isAuthenticated => this == AuthState.authenticated;

  /// ゲストユーザーかどうか
  bool get isGuest => this == AuthState.guest;

  /// 未認証かどうか
  bool get isUnauthenticated => this == AuthState.unauthenticated;

  /// ローディング中かどうか
  bool get isLoading => this == AuthState.loading;

  /// エラー状態かどうか
  bool get isError => this == AuthState.error;

  /// アプリを使用可能な状態かどうか（認証済みまたはゲスト）
  bool get canUseApp {
    final canUse = isAuthenticated || isGuest;
    print('🔍 AuthState.canUseApp - State: $this, isAuthenticated: $isAuthenticated, isGuest: $isGuest, canUseApp: $canUse');
    return canUse;
  }

  /// 初回起動またはログアウト後の状態かどうか
  bool get needsOnboarding => this == AuthState.initial || isUnauthenticated;
}
