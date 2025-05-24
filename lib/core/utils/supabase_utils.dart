import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/config/env_config.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase関連のユーティリティを提供するクラス
class SupabaseUtils {
  /// Supabaseサーバーの接続状態を確認する
  ///
  /// [ref] RiverpodのRefオブジェクト
  /// 返り値: 接続状態に問題がなければtrue
  static Future<bool> checkConnection(WidgetRef ref) async {
    try {
      // 環境変数の値を確認
      debugPrint('SUPABASE_URL: ${EnvConfig.supabaseUrl}');
      // キーは一部のみ表示してセキュリティを確保
      final keySnippet =
          EnvConfig.supabaseAnonKey.isNotEmpty
              ? '${EnvConfig.supabaseAnonKey.substring(0, 5)}...${EnvConfig.supabaseAnonKey.length}文字'
              : '未設定';
      debugPrint('SUPABASE_ANON_KEY: $keySnippet');

      if (!EnvConfig.validateSupabaseConfig()) {
        debugPrint('⚠️ Supabase環境変数が正しく設定されていません');
        return false;
      }

      final client = ref.read(supabaseClientProvider);

      // 接続テスト方法1: 単純なRPC呼び出し（認証不要）
      try {
        await client.rpc('current_timestamp');
        debugPrint('RPC current_timestamp成功');
        return true;
      } catch (rpcErr) {
        debugPrint('RPC current_timestamp失敗: $rpcErr');

        // 接続テスト方法2: 単純なテーブル存在確認（認証不要）
        try {
          // 構文を修正: count(*)ではなく単純にlimit(1)を使用
          final user = await client.from('users').select().limit(1).single();

          debugPrint('テーブル接続テスト成功: ${user.toString()}');
          return true;
        } catch (tableErr) {
          debugPrint('テーブル接続テストエラー: $tableErr');

          // 接続テスト方法3: auth.getUser()を使用（認証が必要）
          try {
            final user = await client.auth.getUser();
            debugPrint('Auth User取得テスト成功: ${user != null}');
            return true;
          } catch (authErr) {
            debugPrint('Auth User取得エラー: $authErr');
            debugPrint('全ての接続テストに失敗しました');
            return false;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Supabase接続エラー: $e');
      return false;
    }
  }

  /// 現在のユーザーがログインしているかどうかを確認する
  ///
  /// [ref] RiverpodのRefオブジェクト
  /// 返り値: ログインしていればtrue
  static bool isLoggedIn(WidgetRef ref) {
    try {
      final client = ref.read(supabaseClientProvider);
      return client.auth.currentUser != null;
    } catch (e) {
      debugPrint('ログイン状態確認エラー: $e');
      return false;
    }
  }

  /// 初期化状態をチェックし、問題があればエラーメッセージを返す
  ///
  /// [ref] RiverpodのRefオブジェクト
  /// 返り値: 問題がなければnull、問題があればエラーメッセージ
  static String? checkInitializationStatus(WidgetRef ref) {
    try {
      final isInitialized = ref.read(supabaseInitializedProvider);
      if (!isInitialized) {
        return 'Supabaseが初期化されていません。アプリを再起動してください。';
      }

      // 環境変数が正しく設定されているか確認
      if (!EnvConfig.validateSupabaseConfig()) {
        return 'Supabase環境変数が正しく設定されていません。.envファイルを確認してください。';
      }

      // クライアントの取得を試みる（例外が発生する可能性がある）
      ref.read(supabaseClientProvider);

      return null; // 問題なし
    } catch (e) {
      return 'Supabase接続エラー: ${e.toString()}';
    }
  }
}
