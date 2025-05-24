abstract class SupabaseRepository {
  /// Supabaseを初期化する
  Future<void> initialize();

  Future<Map<String, dynamic>?> fetchAllUsers();
}
