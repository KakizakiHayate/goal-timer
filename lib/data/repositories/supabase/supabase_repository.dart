import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SupabaseRepository {
  Future<void> initialize();
}
