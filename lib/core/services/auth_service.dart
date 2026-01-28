import 'package:supabase_flutter/supabase_flutter.dart';

/// 認証状態を取得するサービス
/// SupabaseAuthDatasourceの薄いラッパー
class AuthService {
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  bool get isLoggedIn => currentUserId != null;
}
