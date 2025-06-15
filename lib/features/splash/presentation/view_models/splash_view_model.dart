import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_timer/core/config/env_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goal_timer/core/utils/app_logger.dart';

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

  // StateNotifierがdisposeされているかどうかを追跡
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // 安全に状態を更新するヘルパーメソッド
  void _safeUpdateState(SplashState Function(SplashState) updater) {
    if (!_isDisposed) {
      state = updater(state);
    } else {
      AppLogger.instance.w('SplashViewModel: disposeされた後に状態更新が試みられました');
    }
  }

  // 初期化処理
  Future<void> _initialize() async {
    try {
      // Supabaseの初期化はプロバイダーで行うので、ここではSupabaseの接続状態のみを確認する
      AppLogger.instance.i('SplashViewModel: Supabase接続状態を確認します');

      // 初期化後に接続状態を確認
      await _checkSupabaseConnection();
    } catch (error) {
      AppLogger.instance.e('SplashViewModel初期化エラー', error);
      _safeUpdateState(
        (state) => state.copyWith(
          isLoading: false,
          errorMessage: 'Supabase初期化エラー',
          errorDetails: error.toString(),
        ),
      );
    }
  }

  // Supabaseの接続状態を確認する
  Future<void> _checkSupabaseConnection() async {
    try {
      // 処理中にdisposeされた場合は早期リターン
      if (_isDisposed) {
        AppLogger.instance.w('SplashViewModel: disposeされた後に接続確認が試みられました');
        return;
      }

      // クライアントの取得
      final client = Supabase.instance.client;

      // 初期化状態を確認
      if (!EnvConfig.validateSupabaseConfig()) {
        _safeUpdateState(
          (state) => state.copyWith(
            isLoading: false,
            errorMessage: '初期化エラー',
            errorDetails: 'Supabase環境変数が正しく設定されていません。.envファイルを確認してください。',
          ),
        );
        return;
      }

      // サーバー接続を確認
      try {
        // 処理中にdisposeされた場合は早期リターン
        if (_isDisposed) return;

        // 接続テスト方法1: 単純なRPC呼び出し（認証不要）
        await client.rpc('current_timestamp');

        // 全て成功
        _safeUpdateState(
          (state) => state.copyWith(isLoading: false, isConnectionOk: true),
        );
      } catch (rpcErr) {
        debugPrint('RPC current_timestamp失敗: $rpcErr');

        // 処理中にdisposeされた場合は早期リターン
        if (_isDisposed) return;

        // 接続テスト方法2: 単純なテーブル存在確認（認証不要）
        try {
          await client.from('users').select().limit(1).single();

          // 全て成功
          _safeUpdateState(
            (state) => state.copyWith(isLoading: false, isConnectionOk: true),
          );
        } catch (tableErr) {
          debugPrint('テーブル接続テストエラー: $tableErr');

          // 処理中にdisposeされた場合は早期リターン
          if (_isDisposed) return;

          // 接続テスト方法3: auth.getUser()を使用（認証が必要）
          try {
            await client.auth.getUser();

            // 全て成功
            _safeUpdateState(
              (state) => state.copyWith(isLoading: false, isConnectionOk: true),
            );
          } catch (authErr) {
            // 全ての接続テストに失敗
            _safeUpdateState(
              (state) => state.copyWith(
                isLoading: false,
                errorMessage: 'サーバーに接続できません',
                errorDetails: 'あなたのデバイスがネットワークに接続されていない可能性があります。',
              ),
            );
          }
        }
      }
    } catch (error) {
      _safeUpdateState(
        (state) => state.copyWith(
          isLoading: false,
          errorMessage: '接続確認エラー',
          errorDetails: error.toString(),
        ),
      );
    }
  }

  // 再接続を試みる
  Future<void> retryConnection() async {
    _safeUpdateState(
      (state) => state.copyWith(
        isLoading: true,
        errorMessage: null,
        errorDetails: null,
      ),
    );
    await _initialize();
  }
}
