import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class SupabaseRepository {
  /// Supabaseを初期化する
  Future<void> initialize();

  Future<Map<String, dynamic>?> fetchAllUsers();
  Future<bool> checkConnection(WidgetRef ref);
}
