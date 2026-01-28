import 'package:supabase_flutter/supabase_flutter.dart';

/// 認証情報を提供するサービス
///
/// ViewModelがSupabaseに直接依存しないようにラップする。
/// Repository層でuserIdが必要な場合に使用する。
class AuthService {
  /// 現在ログインしているユーザーのID
  ///
  /// 未ログインの場合はnullを返す
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  /// ログイン済みかどうか
  bool get isLoggedIn => currentUserId != null;

  /// 匿名ユーザーかどうか
  bool get isAnonymous =>
      Supabase.instance.client.auth.currentUser?.isAnonymous ?? true;
}
