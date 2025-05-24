import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseRepository {
  /// Supabaseを初期化する
  Future<void> initialize();

  Future<Map<String, dynamic>?> fetchAllUsers();
}
