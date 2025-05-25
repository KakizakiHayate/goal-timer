import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/config/env_config.dart';
import 'package:goal_timer/core/provider/providers.dart';
import 'package:goal_timer/core/utils/supabase_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// スプラッシュ画面の状態
class SplashState {
  final bool isLoading;
  final String? errorMessage;
  final String? errorDetails;
  final bool isConnectionOk;

  SplashState({
    this.isLoading = true,
    this.errorMessage,
    this.errorDetails,
    this.isConnectionOk = false,
  });

  SplashState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? errorDetails,
    bool? isConnectionOk,
  }) {
    return SplashState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      errorDetails: errorDetails ?? this.errorDetails,
      isConnectionOk: isConnectionOk ?? this.isConnectionOk,
    );
  }
}

// スプラッシュ画面のViewModel
class SplashViewModel extends StateNotifier<SplashState> {
  SplashViewModel() : super(SplashState()) {
    _initialize();
  }

  // 初期化処理
  Future<void> _initialize() async {
    try {
      // Supabaseを直接初期化
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );

      // 初期化後に接続状態を確認
      await _checkSupabaseConnection();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Supabase初期化エラー',
        errorDetails: error.toString(),
      );
    }
  }

  // Supabaseの接続状態を確認する
  Future<void> _checkSupabaseConnection() async {
    try {
      // クライアントの取得
      final client = Supabase.instance.client;

      // 初期化状態を確認
      if (!EnvConfig.validateSupabaseConfig()) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '初期化エラー',
          errorDetails: 'Supabase環境変数が正しく設定されていません。.envファイルを確認してください。',
        );
        return;
      }

      // サーバー接続を確認
      try {
        // 接続テスト方法1: 単純なRPC呼び出し（認証不要）
        await client.rpc('current_timestamp');

        // 全て成功
        state = state.copyWith(isLoading: false, isConnectionOk: true);
      } catch (rpcErr) {
        debugPrint('RPC current_timestamp失敗: $rpcErr');

        // 接続テスト方法2: 単純なテーブル存在確認（認証不要）
        try {
          await client.from('users').select().limit(1).single();

          // 全て成功
          state = state.copyWith(isLoading: false, isConnectionOk: true);
        } catch (tableErr) {
          debugPrint('テーブル接続テストエラー: $tableErr');

          // 接続テスト方法3: auth.getUser()を使用（認証が必要）
          try {
            await client.auth.getUser();

            // 全て成功
            state = state.copyWith(isLoading: false, isConnectionOk: true);
          } catch (authErr) {
            // 全ての接続テストに失敗
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'Supabaseサーバーに接続できません',
              errorDetails:
                  '1. .envファイル内のSUPABASE_URLとSUPABASE_ANON_KEYが正しいか確認してください\n'
                  '2. ネットワーク接続状態を確認してください\n'
                  '3. Supabaseプロジェクトが起動しているか確認してください',
            );
          }
        }
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '接続確認エラー',
        errorDetails: error.toString(),
      );
    }
  }

  // 再接続を試みる
  Future<void> retryConnection() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      errorDetails: null,
    );
    await _initialize();
  }
}

// スプラッシュ画面のViewModelを提供するProvider
final splashViewModelProvider =
    StateNotifierProvider<SplashViewModel, SplashState>((ref) {
      return SplashViewModel();
    });
