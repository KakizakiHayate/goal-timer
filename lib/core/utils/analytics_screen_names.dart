/// GetX のルートパスを GA4 の `screen_name` パラメータに変換するヘルパー。
///
/// `RouteNames` のパスをそのまま渡すと snake_case の screen_name を返す。
/// `/debug/` で始まるパスは null を返し、計測対象から除外する。
class AnalyticsScreenNames {
  AnalyticsScreenNames._();

  static const String _debugPrefix = '/debug';

  /// ルートパスを screen_name に変換する。
  ///
  /// - `null` または空文字 → `null`（計測スキップ）
  /// - `/debug/...` → `null`（計測スキップ）
  /// - `/` → `'splash'`
  /// - `/home` → `'home'`
  /// - `/timer-with-goal` → `'timer_with_goal'`
  /// - `/onboarding/goal-creation` → `'onboarding_goal_creation'`
  /// - `/auth/signin` → `'auth_signin'`
  static String? fromRoute(String? routeName) {
    if (routeName == null || routeName.isEmpty) {
      return null;
    }

    if (routeName == '/') {
      return 'splash';
    }

    if (routeName == _debugPrefix || routeName.startsWith('$_debugPrefix/')) {
      return null;
    }

    // 先頭の `/` を除去し、残りの `/` と `-` を `_` に置換する。
    final trimmed = routeName.startsWith('/')
        ? routeName.substring(1)
        : routeName;
    return trimmed.replaceAll('/', '_').replaceAll('-', '_');
  }
}
