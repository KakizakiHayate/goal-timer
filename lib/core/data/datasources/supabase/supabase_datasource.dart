import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_timer/core/config/env_config.dart';
import 'package:goal_timer/core/data/repositories/supabase/supabase_repository.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

class SupabaseDatasource implements SupabaseRepository {
  bool _initialized = false;
  static late final SupabaseClient client;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 環境変数からSupabase認証情報を取得
      final supabaseUrl = EnvConfig.supabaseUrl;
      final supabaseAnonKey = EnvConfig.supabaseAnonKey;

      if (!EnvConfig.validateSupabaseConfig()) {
        throw Exception('Supabase環境変数が設定されていません');
      }

      // Supabaseの初期化
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

      // クライアントインスタンスを保持
      client = Supabase.instance.client;
      _initialized = true;

      AppLogger.instance.i('Supabase initialized successfully');

      // テーブルの初期化はスキップ - テーブルは別途管理コンソールから作成する
      // 開発者に通知するためのログ
      AppLogger.instance.w('注意: Supabaseのテーブルが存在しない場合は、管理コンソールから手動作成してください');
    } catch (e) {
      AppLogger.instance.e('Error initializing Supabase', e);
      rethrow; // エラーを再スローして呼び出し元で処理可能に
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchAllUsers() async {
    try {
      final allUsers = await client.from('users').select().single();

      return allUsers;
    } catch (e) {
      return null;
    }
  }

  /// [ref] RiverpodのRefオブジェクト
  /// 返り値: 接続状態に問題がなければtrue
  Future<bool> checkConnection(WidgetRef ref) async {
    try {
      // 環境変数の値を確認
      AppLogger.instance.d('SUPABASE_URL: ${EnvConfig.supabaseUrl}');
      // キーは一部のみ表示してセキュリティを確保
      final keySnippet =
          EnvConfig.supabaseAnonKey.isNotEmpty
              ? '${EnvConfig.supabaseAnonKey.substring(0, 5)}...${EnvConfig.supabaseAnonKey.length}文字'
              : '未設定';
      AppLogger.instance.d('SUPABASE_ANON_KEY: $keySnippet');

      if (!EnvConfig.validateSupabaseConfig()) {
        AppLogger.instance.w('⚠️ Supabase環境変数が正しく設定されていません');
        return false;
      }

      final client = ref.read(supabaseClientProvider);

      // 接続テスト方法1: 単純なRPC呼び出し（認証不要）
      try {
        await client.rpc('current_timestamp');
        AppLogger.instance.d('RPC current_timestamp成功');
        return true;
      } catch (rpcErr) {
        AppLogger.instance.w('RPC current_timestamp失敗: $rpcErr');

        // 接続テスト方法2: 単純なテーブル存在確認（認証不要）
        try {
          // 構文を修正: count(*)ではなく単純にlimit(1)を使用
          final user = await client.from('users').select().limit(1).single();

          AppLogger.instance.i('テーブル接続テスト成功: ${user.toString()}');
          return true;
        } catch (tableErr) {
          AppLogger.instance.w('テーブル接続テストエラー: $tableErr');

          // 接続テスト方法3: auth.getUser()を使用（認証が必要）
          try {
            final user = await client.auth.getUser();
            AppLogger.instance.i('Auth User取得テスト成功: ${user != null}');
            return true;
          } catch (authErr) {
            AppLogger.instance.e('Auth User取得エラー', authErr);
            AppLogger.instance.e('全ての接続テストに失敗しました');
            return false;
          }
        }
      }
    } catch (e) {
      AppLogger.instance.e('❌ Supabase接続エラー', e);
      return false;
    }
  }
}
