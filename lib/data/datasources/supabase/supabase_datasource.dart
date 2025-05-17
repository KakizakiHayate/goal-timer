import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goal_timer/data/repositories/supabase/supabase_repository.dart';

class SupabaseDatasource implements SupabaseRepository {
  bool _initialized = false;
  static late final SupabaseClient client;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 環境変数からSupabase認証情報を取得
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Supabase環境変数が設定されていません');
      }

      // Supabaseの初期化
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

      // クライアントインスタンスを保持
      client = Supabase.instance.client;
      _initialized = true;

      print('Supabase initialized successfully');

      // テーブルの初期化はスキップ - テーブルは別途管理コンソールから作成する
      // 開発者に通知するためのログ
      print('注意: Supabaseのテーブルが存在しない場合は、管理コンソールから手動作成してください');
      // アプリがローカルデータベースで動作できるようにするため、初期化は成功とみなす
    } catch (e) {
      print('Error initializing Supabase: $e');
      rethrow; // エラーを再スローして呼び出し元で処理可能に
    }
  }
}
